extends Node2D

# Center-origin constants (legacy script retained for reference)
const VIEW_SIZE: Vector2 = Vector2(1280, 720)
const HALF_VIEW: Vector2 = VIEW_SIZE * 0.5
const CENTER: Vector2 = Vector2.ZERO

# main_v2.gd - DREAM GATE DEFENSE
# A rhythm-based typing defense game (legacy)

# Scenes
const ProtagonistScene = preload("res://scenes/protagonist.tscn")
const PhantomScene = preload("res://scenes/phantom.tscn")

# Nodes
@onready var phantom_container = $GameplayArea/PhantomContainer
@onready var protagonist_container = $GameplayArea/ProtagonistContainer
@onready var health_bar = $UILayer/HealthBar
@onready var status_text = $UILayer/StatusText
@onready var camera = $Camera2D

# Resources
var phantom_resources: Array[PhantomData] = []
var monogram_font: FontFile

# Game State
var protagonist = null
var active_phantoms: Array = []
var focused_phantom = null
var current_typed_string: String = ""

# Core Stats
var health: float = 100.0
var max_health: float = 100.0
var score: int = 0
var high_score: int = 0
var wave: int = 1

# NEW MECHANIC: Dream Gates (center-origin)
var gates: Dictionary = {
	"north": {"position": Vector2(0, -HALF_VIEW.y + 100), "breached": false, "threat_level": 0},
	"south": {"position": Vector2(0, HALF_VIEW.y - 100), "breached": false, "threat_level": 0},
	"east": {"position": Vector2(HALF_VIEW.x - 100, 0), "breached": false, "threat_level": 0},
	"west": {"position": Vector2(-HALF_VIEW.x + 100, 0), "breached": false, "threat_level": 0}
}

# NEW: Spawn zones at edges (center-origin)
var spawn_zones: Dictionary = {
	"north": Vector2(0, -HALF_VIEW.y + 50),
	"south": Vector2(0, HALF_VIEW.y - 50),
	"east": Vector2(HALF_VIEW.x - 50, 0),
	"west": Vector2(-HALF_VIEW.x + 50, 0)
}

# NEW: Rhythm system
var rhythm_timer: float = 0.0
var rhythm_beat: float = 0.6  # Beat every 0.6 seconds
var last_input_time: float = 0.0
var on_beat_window: float = 0.15  # ±0.15s from beat
var rhythm_bonus_active: bool = false

# NEW: Combo system
var combo: int = 0
var combo_timer: float = 0.0
var combo_timeout: float = 3.0
var max_combo: int = 0

# Spawn control
var spawn_timer: float = 0.0
var spawn_interval: float = 3.0  # Slower, more strategic
var max_phantoms: int = 8
var phantoms_per_wave: int = 15
var phantoms_spawned_this_wave: int = 0

# Control
var can_accept_input: bool = false
var game_over: bool = false

func _ready():
	# Load font
	monogram_font = load("res://fonts/monogram-extended.ttf")
	
	# Load high score
	load_high_score()
	
	# Load phantom resources
	load_phantom_resources()
	
	# Setup camera at center
	camera.position = CENTER
	
	# Spawn protagonist
	protagonist = ProtagonistScene.instantiate()
	protagonist_container.add_child(protagonist)
	
	# Setup UI
	update_ui()
	
	# Start game
	await get_tree().create_timer(1.0).timeout
	start_game()

func load_phantom_resources():
	var loaded_count := 0
	var dir = DirAccess.open("res://phantoms")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var phantom_data = load("res://phantoms/" + file_name) as PhantomData
				if phantom_data:
					phantom_resources.append(phantom_data)
					loaded_count += 1
			file_name = dir.get_next()
		dir.list_dir_end()

	# Fallback to preloaded registry if DirAccess fails (common on HTML5)
	if loaded_count == 0:
		print("[load_phantom_resources v2] DirAccess returned no files; using phantom_registry fallback.")
		var reg := preload("res://scripts/phantom_registry.gd")
		if reg.PHANTOM_RESOURCES and reg.PHANTOM_RESOURCES.size() > 0:
			for r in reg.PHANTOM_RESOURCES:
				if r:
					phantom_resources.append(r)
					loaded_count += 1
		else:
			for p in reg.PHANTOM_PATHS:
				var phantom_data = load(p) as PhantomData
				if phantom_data:
					phantom_resources.append(phantom_data)
					loaded_count += 1

func start_game():
	can_accept_input = true
	spawn_timer = spawn_interval
	status_text.text = "defend the gates | wave %d" % wave

func _process(delta):
	if game_over:
		return
	
	if not can_accept_input:
		return
	
	# Update rhythm timer
	rhythm_timer += delta
	if rhythm_timer >= rhythm_beat:
		rhythm_timer -= rhythm_beat
	
	# Check if we're on beat
	var time_from_beat = abs(rhythm_timer)
	rhythm_bonus_active = time_from_beat < on_beat_window or time_from_beat > (rhythm_beat - on_beat_window)
	
	# Update combo timer
	if combo > 0:
		combo_timer -= delta
		if combo_timer <= 0:
			combo = 0
			if status_text:
				status_text.text = "combo lost | wave %d" % wave
	
	# Spawn phantoms
	spawn_timer -= delta
	if spawn_timer <= 0 and active_phantoms.size() < max_phantoms:
		if phantoms_spawned_this_wave < phantoms_per_wave:
			spawn_phantom()
			spawn_timer = spawn_interval
	
	# Update phantoms - they drift toward gates
	for phantom in active_phantoms:
		if phantom and is_instance_valid(phantom):
			var target_gate = get_nearest_gate(phantom.position)
			var direction = (target_gate - phantom.position).normalized()
			phantom.position += direction * 30.0 * delta  # Slow drift
			
			# Check if reached gate
			if phantom.position.distance_to(target_gate) < 30:
				gate_breach(phantom)
	
	# Update gate threat levels
	update_gate_threats()
	
	# Update UI
	update_ui()

func spawn_phantom():
	if phantom_resources.is_empty():
		return
	
	# Pick random spawn zone
	var zone_name = spawn_zones.keys().pick_random()
	var spawn_pos = spawn_zones[zone_name]
	
	var phantom_data = phantom_resources.pick_random()
	var phantom = PhantomScene.instantiate()
	phantom.initialize(phantom_data, monogram_font)
	phantom.position = spawn_pos + Vector2(randf_range(-50, 50), randf_range(-50, 50))
	phantom_container.add_child(phantom)
	active_phantoms.append(phantom)
	
	phantoms_spawned_this_wave += 1

func get_nearest_gate(pos: Vector2) -> Vector2:
	var nearest_gate = gates["north"]["position"]
	var min_dist = pos.distance_to(nearest_gate)
	
	for gate_name in gates:
		var gate_pos = gates[gate_name]["position"]
		var dist = pos.distance_to(gate_pos)
		if dist < min_dist:
			min_dist = dist
			nearest_gate = gate_pos
	
	return nearest_gate

func update_gate_threats():
	# Reset threat levels
	for gate_name in gates:
		gates[gate_name]["threat_level"] = 0
	
	# Count phantoms near each gate
	for phantom in active_phantoms:
		if phantom and is_instance_valid(phantom):
			var nearest = get_nearest_gate(phantom.position)
			for gate_name in gates:
				if gates[gate_name]["position"] == nearest:
					gates[gate_name]["threat_level"] += 1

func gate_breach(phantom):
	# Damage player
	take_damage(25.0)
	
	# Remove phantom
	active_phantoms.erase(phantom)
	phantom.queue_free()
	
	# Visual feedback
	add_screen_shake(5.0)
	SoundManager.play_damage()
	
	if status_text:
		status_text.text = "GATE BREACHED! | wave %d" % wave

func _unhandled_input(event: InputEvent):
	if not can_accept_input or game_over:
		return
	
	if event is InputEventKey and event.pressed and not event.is_echo():
		handle_key_input(event)

func handle_key_input(event: InputEventKey):
	var keycode = event.keycode
	var character = ""
	
	if keycode == KEY_BACKSPACE:
		if current_typed_string.length() > 0:
			current_typed_string = current_typed_string.substr(0, current_typed_string.length() - 1)
			if focused_phantom:
				focused_phantom.update_typing_progress(current_typed_string)
		return
	elif keycode == KEY_SPACE:
		character = " "
	elif keycode >= KEY_A and keycode <= KEY_Z:
		character = char(keycode + 32)
	elif keycode >= KEY_0 and keycode <= KEY_9:
		character = char(keycode)
	else:
		return
	
	process_character(character)

func process_character(character: String):
	var current_time = Time.get_ticks_msec() / 1000.0
	last_input_time = current_time
	
	SoundManager.play_type()
	
	if focused_phantom == null:
		# Find phantom starting with this character
		for phantom in active_phantoms:
			if phantom and is_instance_valid(phantom):
				var text = phantom.phantom_data.text_to_type
				if text.begins_with(character):
					focus_phantom(phantom)
					current_typed_string = character
					phantom.update_typing_progress(current_typed_string)
					break
	else:
		# Continue typing focused phantom
		var expected = focused_phantom.phantom_data.text_to_type
		
		if expected.begins_with(current_typed_string + character):
			current_typed_string += character
			focused_phantom.update_typing_progress(current_typed_string)
			
			# Check completion
			if current_typed_string == expected:
				complete_phantom()
		else:
			# Mistake - lose combo
			mistake()

func focus_phantom(phantom):
	focused_phantom = phantom
	phantom.set_focused(true)

func complete_phantom():
	if not focused_phantom:
		return
	
	# Calculate points
	var base_points = focused_phantom.phantom_data.text_to_type.length() * 10
	var rhythm_mult = 2.0 if rhythm_bonus_active else 1.0
	var combo_mult = 1.0 + (combo * 0.1)
	var points = int(base_points * rhythm_mult * combo_mult)
	
	score += points
	combo += 1
	combo_timer = combo_timeout
	
	if combo > max_combo:
		max_combo = combo
	
	# Visual feedback
	SoundManager.play_success()
	add_screen_shake(1.0)
	
	# Remove phantom
	active_phantoms.erase(focused_phantom)
	focused_phantom.queue_free()
	
	focused_phantom = null
	current_typed_string = ""
	
	# Check wave completion
	if phantoms_spawned_this_wave >= phantoms_per_wave and active_phantoms.size() == 0:
		next_wave()
	
	update_ui()

func mistake():
	combo = 0
	current_typed_string = ""
	if focused_phantom:
		focused_phantom.set_focused(false)
		focused_phantom = null
	
	SoundManager.play_error()
	add_screen_shake(2.0)

func take_damage(amount: float):
	health -= amount
	health = max(0, health)
	
	if health <= 0:
		end_game()
	
	update_health_bar()

func next_wave():
	wave += 1
	phantoms_spawned_this_wave = 0
	spawn_interval = max(1.0, spawn_interval - 0.2)
	max_phantoms = min(12, max_phantoms + 1)
	
	if status_text:
		status_text.text = "WAVE %d | combo x%d" % [wave, combo]

func update_ui():
	if status_text:
		var combo_text = (" | x%d" % combo) if combo > 0 else ""
		var rhythm_text = " ♪" if rhythm_bonus_active else ""
		status_text.text = "wave %d | score %d%s%s" % [wave, score, combo_text, rhythm_text]
	
	update_health_bar()

func update_health_bar():
	if health_bar:
		health_bar.value = (health / max_health) * 100.0

func add_screen_shake(amount: float):
	if camera:
		var shake_offset = Vector2(randf_range(-amount, amount), randf_range(-amount, amount))
		camera.offset = shake_offset
		var tween = create_tween()
		tween.tween_property(camera, "offset", Vector2.ZERO, 0.1)

func end_game():
	game_over = true
	can_accept_input = false
	
	if score > high_score:
		high_score = score
		save_high_score()
	
	if status_text:
		status_text.text = "dream collapsed | score: %d | high: %d" % [score, high_score]

func save_high_score():
	var file = FileAccess.open("user://high_score.dat", FileAccess.WRITE)
	if file:
		file.store_32(high_score)
		file.close()

func load_high_score():
	if FileAccess.file_exists("user://high_score.dat"):
		var file = FileAccess.open("user://high_score.dat", FileAccess.READ)
		if file:
			high_score = file.get_32()
			file.close()
