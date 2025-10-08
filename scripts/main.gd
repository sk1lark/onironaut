# main.gd
extends Node2D

# Preloaded scenes
const ProtagonistScene = preload("res://scenes/protagonist.tscn")
const PowerUpScene = preload("res://scenes/power_up.tscn")

# Scene references
@onready var phantom_container = $GameplayArea/PhantomContainer
@onready var power_up_container = $GameplayArea/PowerUpContainer
@onready var protagonist_container = $GameplayArea/ProtagonistContainer
@onready var health_bar = $UILayer/HealthBar
@onready var health_static = $UILayer/HealthStatic
@onready var cursor = $UILayer/Cursor
@onready var status_text = $UILayer/StatusText
@onready var dither_shader_rect = $DitherLayer/DitherShader
@onready var transition_rect = $TransitionLayer/TransitionRect
@onready var camera = $Camera2D

# Font resource
var monogram_font: FontFile

# Protagonist
var protagonist = null

# Game state variables
var focused_phantom: Phantom = null
var current_typed_string: String = ""
var lucidity: float = 100.0
var max_lucidity: float = 100.0
var synchronicity_counter: int = 0
var resonance: int = 0
var is_in_sync: bool = false
var current_level: int = 1
var is_typing_blocked: bool = false
var score: int = 0

# Phantom management
var active_phantoms: Array[Phantom] = []
var phantom_resources: Array[PhantomData] = []
var spawn_timer: float = 0.0
var spawn_interval: float = 1.0  # FASTER: was 1.5
var max_phantoms: int = 8  # MORE: was 6

# addiction mechanics - escalation
var survival_time: float = 0.0
var last_transformation: float = 0.0
var transformation_interval: float = 20.0  # FASTER: was 30.0
var transformation_level: int = 0
var typing_speed_multiplier: float = 1.0

# HIGH STAKES mechanics
var health_drain_per_second: float = 2.0  # HARDER: was 1.5
var phantom_damage: float = 12.0  # HARDER: was 8.0
var mistake_damage: float = 18.0  # HARDER: was 12.0
var time_pressure_multiplier: float = 1.0

# addiction mechanics - juice
var screen_shake_amount: float = 0.0
var combo_count: int = 0
var combo_timer: float = 0.0
var combo_window: float = 3.0
var perfect_streak: int = 0

# NEW addiction mechanics - power-ups & danger
var active_power_ups: Array = []
var power_up_resources: Array[PowerUpData] = []
var card_resources: Array[CardData] = []
var drawn_cards: Array[CardData] = []
var damage_reduction: float = 0.0
var health_regen_bonus: float = 0.0
var max_phantoms_bonus: int = 0
var power_up_chance_bonus: float = 0.0
var choosing_upgrade: bool = false
var upgrade_options: Array[String] = []
var near_miss_count: int = 0
var danger_zone_radius: float = 120.0  # BIGGER: was 80.0
var streak_multiplier: float = 1.0

# Near-death mechanics
var near_death_threshold: float = 25.0
var is_near_death: bool = false
var critical_threshold: float = 10.0
var is_critical: bool = false

# Idle punishment - phantoms attack if you stop typing
var idle_timer: float = 0.0
var idle_attack_threshold: float = 4.0  # Start attacking after 4 seconds of no typing

# addiction mechanics - flow state
var flow_intensity: float = 0.0
var last_keypress_interval: float = 0.0
var rhythm_consistency: float = 0.0
var last_intervals: Array[float] = []

# Level data
var level_phantom_counts = {
	1: 20,  # Surface Dream
	2: 25,  # Archive of Memory  
	3: 30,  # Logic Engine
	4: 35,  # Abstract Syntax
	5: 1    # The Ego
}

# Input handling
var can_accept_input: bool = true
var last_keypress_time: float = 0.0

func _ready():
	setup_game()
	load_phantom_resources()
	load_power_up_resources()
	load_card_resources()
	spawn_protagonist()
	start_game()

func setup_game():
	# Load monogram font
	monogram_font = load("res://fonts/monogram-extended.ttf")
	
	# Pure 1-bit aesthetic - no post-processing needed
	# Dither shader is disabled by default for clean visuals
	
	# Setup cursor pulse animation
	animate_cursor()

	# Initialize health bar
	update_health_bar()

func load_power_up_resources():
	# Load power-up resources
	var dir = DirAccess.open("res://power_ups/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var resource = load("res://power_ups/" + file_name) as PowerUpData
				if resource:
					power_up_resources.append(resource)
			file_name = dir.get_next()
		dir.list_dir_end()

func load_card_resources():
	# Load card resources
	var dir = DirAccess.open("res://cards/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var resource = load("res://cards/" + file_name) as CardData
				if resource:
					card_resources.append(resource)
			file_name = dir.get_next()
		dir.list_dir_end()

func spawn_protagonist():
	protagonist = ProtagonistScene.instantiate()
	protagonist_container.add_child(protagonist)

func load_phantom_resources():
	# Load all phantom resources from the phantoms folder
	var dir = DirAccess.open("res://phantoms/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()

		while file_name != "":
			if file_name.ends_with(".tres"):
				var resource = load("res://phantoms/" + file_name) as PhantomData
				if resource:
					# Include any phantom that is the same level or lower so the field has variety
					if resource.level <= current_level:
						phantom_resources.append(resource)
			file_name = dir.get_next()

	print("Loaded ", phantom_resources.size(), " phantom resources for level ", current_level)

func start_game():
	can_accept_input = true
	spawn_timer = spawn_interval
	
	# HIGH STAKES: Start with 5 phantoms immediately
	for i in range(5):
		await get_tree().create_timer(0.3 * i).timeout
		spawn_phantom()
	
	# Draw cards for this run
	draw_cards()

func draw_cards():
	if card_resources.size() == 0:
		return
	
	drawn_cards.clear()
	for i in 3:
		var card = card_resources.pick_random()
		drawn_cards.append(card)
		apply_card_effect(card)
	
	# Show drawn cards
	show_drawn_cards()

func apply_card_effect(card: CardData):
	match card.effect:
		"typing_speed":
			typing_speed_multiplier += card.value
		"damage_reduction":
			damage_reduction += card.value
		"health_regen":
			health_regen_bonus += card.value
		"max_phantoms":
			max_phantoms_bonus += int(card.value)
		"power_up_chance":
			power_up_chance_bonus += card.value

func apply_upgrade(upgrade: String):
	match upgrade:
		"speed":
			typing_speed_multiplier += 0.2
		"health":
			heal_lucidity(20.0)
		"damage":
			damage_reduction += 0.2

func show_drawn_cards():
	# For now, print to console
	print("Drawn cards:")
	for card in drawn_cards:
		print(card.name + ": " + card.description)

func _process(delta):
	if not can_accept_input:
		return

	# track survival time for escalation
	survival_time += delta
	
	# HIGH STAKES: Constant health drain (gets faster over time)
	var drain_rate = health_drain_per_second * time_pressure_multiplier
	damage_lucidity(drain_rate * delta)
	
	# Card bonus: Health regen
	if health_regen_bonus > 0:
		heal_lucidity(health_regen_bonus * delta)
	
	# Track idle time for phantom attacks
	idle_timer += delta
	update_phantom_attack_state()
	
	# check for transformation every 20 seconds
	if survival_time - last_transformation >= transformation_interval:
		trigger_transformation()
		last_transformation = survival_time
	
	# update combo timer
	if combo_count > 0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			reset_combo()
	
	# calculate flow intensity based on performance
	update_flow_state(delta)
	
	# apply screen shake decay
	if screen_shake_amount > 0.0:
		screen_shake_amount = lerp(screen_shake_amount, 0.0, delta * 10.0)
		apply_screen_shake()
	
	# check for near misses (danger zone)
	check_near_misses()
	
	# update streak multiplier
	if perfect_streak > 0:
		streak_multiplier = 1.0 + (perfect_streak * 0.1)
	else:
		streak_multiplier = 1.0
	
	# Always animate health static bar for abstract movement
	animate_health_static(delta)

	# Handle phantom spawning - gets faster with transformations
	var adjusted_spawn_interval = spawn_interval / typing_speed_multiplier
	spawn_timer -= delta
	if spawn_timer <= 0.0 and active_phantoms.size() < max_phantoms + max_phantoms_bonus:
		spawn_phantom()
		spawn_timer = adjusted_spawn_interval

	# Update cursor position and pulse
	update_cursor()

	# Check for game over
	if lucidity <= 0.0:
		trigger_wake_up()

func _unhandled_input(event):
	if not can_accept_input or is_typing_blocked:
		return

	if event is InputEventKey and event.pressed and not event.is_echo():
		handle_key_input(event)

func handle_key_input(event: InputEventKey):
	# Get the typed character
	var keycode = event.keycode
	var character = ""

	# Handle special keys
	if keycode == KEY_BACKSPACE:
		handle_backspace()
		return
	elif keycode == KEY_SPACE:
		character = " "
	elif keycode >= KEY_A and keycode <= KEY_Z:
		character = char(keycode + 32)  # Convert to lowercase
		if event.shift_pressed:
			character = character.to_upper()
	elif keycode >= KEY_0 and keycode <= KEY_9:
		character = char(keycode)
	else:
		# Handle other printable characters
		character = OS.get_keycode_string(keycode).to_lower()
		if character.length() != 1:
			return  # Ignore non-printable characters

	process_character_input(character)

func process_character_input(character: String):
	# Reset idle timer - player is typing!
	idle_timer = 0.0
	
	if choosing_upgrade:
		current_typed_string += character
		if current_typed_string in upgrade_options:
			apply_upgrade(current_typed_string)
			current_typed_string = ""
			choosing_upgrade = false
			can_accept_input = true
			return
	
	# track rhythm for flow state
	var current_time = Time.get_ticks_msec() / 1000.0
	if last_keypress_time > 0:
		var interval = current_time - last_keypress_time
		last_intervals.append(interval)
		if last_intervals.size() > 10:
			last_intervals.pop_front()
	last_keypress_time = current_time
	
	# play type sound on each keystroke
	SoundManager.play_type()

	if focused_phantom == null:
		# Try to find a phantom that starts with this character
		find_and_focus_phantom(character)
	else:
		# Continue typing the focused phantom
		var expected_char = get_next_expected_character()

		if character == expected_char:
			# Correct character - juice it up
			current_typed_string += character
			focused_phantom.update_typing_progress(current_typed_string)
			
			# tiny screen shake per keystroke
			add_screen_shake(0.5 + (combo_count * 0.1))
			
			# spawn mini particle at phantom
			spawn_keystroke_particle(focused_phantom.position)

			# Check if phantom is complete
			if current_typed_string == focused_phantom.phantom_data.text_to_type:
				complete_focused_phantom()
		else:
			# Wrong character - trigger typo
			trigger_typo()

func find_and_focus_phantom(character: String):
	for phantom in active_phantoms:
		if phantom.phantom_data.text_to_type.begins_with(character.to_lower()):
			set_focused_phantom(phantom)
			current_typed_string = character.to_lower()
			phantom.update_typing_progress(current_typed_string)
			return

	# No phantom found starting with this character
	trigger_typo()

func set_focused_phantom(phantom: Phantom):
	# Unfocus current phantom
	if focused_phantom:
		focused_phantom.set_focused(false)

	# Focus new phantom
	focused_phantom = phantom
	if focused_phantom:
		focused_phantom.set_focused(true)

		# Blur other phantoms
		for other_phantom in active_phantoms:
			if other_phantom != focused_phantom:
				other_phantom.set_focused(false)

func get_next_expected_character() -> String:
	if focused_phantom and current_typed_string.length() < focused_phantom.phantom_data.text_to_type.length():
		return focused_phantom.phantom_data.text_to_type[current_typed_string.length()]
	return ""

func complete_focused_phantom():
	if not focused_phantom:
		return
	
	# increment combo first so we can use it
	increment_combo()
	perfect_streak += 1
	score += 10 + (combo_count * 5)

	# HIGH STAKES: Heal on completion (lifeline!)
	var heal_amount = 5.0 + (combo_count * 0.5)  # More healing with combo
	heal_lucidity(heal_amount)

	# Play dealt sound when word completed
	SoundManager.play_dealt()
	
	# Protagonist attack animation
	if protagonist and protagonist.has_method("attack_pulse"):
		protagonist.attack_pulse()
		protagonist.face_direction(focused_phantom.position)
		protagonist.set_combo_level(combo_count)

	# Update synchronicity
	synchronicity_counter += 1
	check_synchronicity_state()

	# Award resonance if in sync
	if is_in_sync:
		resonance += 2
	else:
		resonance += 1
	
	# big screen shake for completion
	add_screen_shake(5.0 + (combo_count * 0.5))
	
	# spawn explosion particle burst at phantom position
	spawn_completion_burst(focused_phantom.position)
	
	# Static burst at completion
	spawn_static_burst(focused_phantom.position)
	
	# CRT glitch on high combos
	if combo_count >= 5:
		apply_crt_glitch(0.3 + (combo_count * 0.1), 0.1)
	
	# check for chain reactions - nearby phantoms explode
	check_chain_reaction(focused_phantom.position)

	# Remove phantom from active list
	active_phantoms.erase(focused_phantom)
	
	# Chance to spawn power-up
	maybe_spawn_power_up(focused_phantom.position)

	# Trigger completion animation
	focused_phantom.complete_phantom()

	# Reset focus
	focused_phantom = null
	current_typed_string = ""

	# Unfocus all phantoms
	for phantom in active_phantoms:
		phantom.set_focused(false)

func trigger_typo():
	# Play hurt sound on wrong character
	SoundManager.play_hurt()

	# Reset combo and synchronicity
	reset_combo()
	perfect_streak = 0
	synchronicity_counter = 0
	is_in_sync = false
	
	# HIGH STAKES: Big damage on mistakes
	damage_lucidity(mistake_damage)
	
	# Protagonist takes damage
	if protagonist and protagonist.has_method("take_damage"):
		protagonist.take_damage()
	
	# massive screen shake for mistakes
	add_screen_shake(20.0)  # INCREASED: was 15.0
	
	# Full screen static flash on mistake
	spawn_screen_static_flash()
	
	# Heavy CRT glitch
	apply_crt_glitch(1.5, 0.4)  # STRONGER

	# inverse flash - everything goes black briefly
	if has_node("Background/ColorRect"):
		var bg = $Background/ColorRect
		bg.color = Color.WHITE
		await get_tree().create_timer(0.05).timeout
		bg.color = Color.BLACK
	
	# Return phantoms to normal
	for phantom in active_phantoms:
		if phantom != focused_phantom:
			phantom.modulate = Color(1, 1, 1, 0.4)

	# Block input briefly
	is_typing_blocked = true
	var timer = create_tween()
	timer.tween_callback(func(): is_typing_blocked = false).set_delay(0.2)

	# Lose lucidity
	damage_lucidity(5.0)
	
	# show miss indicator
	show_floating_text("miss", Vector2(640, 360), Color.RED)

func handle_backspace():
	if current_typed_string.length() > 0:
		current_typed_string = current_typed_string.substr(0, current_typed_string.length() - 1)

		if focused_phantom:
			focused_phantom.update_typing_progress(current_typed_string)

			# If we backspaced everything, unfocus
			if current_typed_string.is_empty():
				set_focused_phantom(null)

func check_synchronicity_state():
	if synchronicity_counter >= 5 and not is_in_sync:
		enter_synchronicity()
	elif synchronicity_counter < 5 and is_in_sync:
		exit_synchronicity()

func enter_synchronicity():
	is_in_sync = true
	print("Entered synchronicity!")

	# Make all phantoms slightly brighter when in sync
	for phantom in active_phantoms:
		if phantom != focused_phantom:
			phantom.modulate = Color(1, 1, 1, 0.6)

	# Notify sound manager
	SoundManager.enter_synchronicity()

func exit_synchronicity():
	is_in_sync = false
	print("Exited synchronicity.")

	# Return phantoms to normal opacity
	for phantom in active_phantoms:
		if phantom != focused_phantom:
			phantom.modulate = Color(1, 1, 1, 0.4)

	# Notify sound manager
	SoundManager.exit_synchronicity()

func spawn_phantom():
	if phantom_resources.is_empty():
		return

	# Choose random phantom
	var phantom_data = phantom_resources.pick_random()

	# Load phantom scene
	var phantom_scene = load("res://scenes/phantom.tscn")
	var phantom_instance = phantom_scene.instantiate() as Phantom

	# spawn phantoms at random positions around the edge - they'll spiral inward
	var angle = randf() * TAU  # random angle around circle
	var distance = 500.0  # start far from center
	var center = Vector2(640, 360)
	var spawn_pos = center + Vector2(cos(angle), sin(angle)) * distance
	
	phantom_instance.position = spawn_pos
	
	# randomize spiral properties for variety
	phantom_instance.spiral_radius = distance
	# HIGH STAKES: Much faster spiral speed
	var base_spiral_speed = 0.4 + (transformation_level * 0.08)  # FASTER
	phantom_instance.spiral_speed = randf_range(base_spiral_speed, base_spiral_speed + 0.5)
	phantom_instance.spiral_time = randf() * TAU  # random starting rotation
	
	# HIGH STAKES: More frequent attacks
	phantom_instance.attack_interval = randf_range(2.5, 5.0)  # FASTER: was 4-8

	# Setup phantom
	phantom_instance.setup_phantom(phantom_data)

	# Connect signals
	phantom_instance.phantom_completed.connect(_on_phantom_completed)
	phantom_instance.phantom_attacks.connect(_on_phantom_attacks)

	# Add to scene and track
	phantom_container.add_child(phantom_instance)
	active_phantoms.append(phantom_instance)
	
	# spawn effect - tiny screen shake and particle burst
	add_screen_shake(1.0)
	spawn_keystroke_particle(spawn_pos)

func _on_phantom_completed(_phantom: Phantom):
	# Already handled in complete_focused_phantom()
	pass

func damage_lucidity(amount: float):
	lucidity = max(0.0, lucidity - amount * (1.0 - damage_reduction))
	update_health_bar()

func heal_lucidity(amount: float):
	lucidity = min(max_lucidity, lucidity + amount)
	update_health_bar()

func update_health_bar():
	var health_percentage = lucidity / max_lucidity
	# Health bar occupies 880px width (scaled for 1280x720)
	var full_width = 880.0
	var bar_width = full_width * health_percentage
	
	# animate health bar changes
	var tween = create_tween()
	tween.tween_property(health_bar, "size:x", bar_width, 0.2)

	# Position static effect to start where health ends
	if health_static:
		health_static.position.x = 160 + bar_width
		health_static.size.x = full_width - bar_width
		# Make static more visible as health decreases - MORE SURREAL
		var static_intensity = 1.0 - health_percentage
		health_static.modulate.a = 0.3 + (static_intensity * 0.7)
		
		# Particle-like glitch effect
		if health_static.material:
			var shader_mat = health_static.material as ShaderMaterial
			if shader_mat:
				var glitch_amount = static_intensity * 60.0
				shader_mat.set_shader_parameter("noise_speed", glitch_amount)
	
	# Update status text with transformation info
	if status_text:
		var status = "lucidity: %d%%" % int(health_percentage * 100)
		if transformation_level > 0:
			status += " | lv:" + str(transformation_level)
		status += " | score:" + str(score)
		status_text.text = status
		
		# pulse text when low health
		if health_percentage < 0.3:
			var pulse = (sin(Time.get_ticks_msec() * 0.01) + 1.0) * 0.5
			status_text.modulate.a = 0.5 + (pulse * 0.5)

func update_cursor():
	# faster pulsing with flow state
	var pulse_speed = 0.005 + (flow_intensity * 0.01)
	var pulse = (sin(Time.get_ticks_msec() * pulse_speed) + 1.0) * 0.5
	cursor.modulate.a = 0.6 + pulse * 0.4

	# Show typing progress with combo indicator
	var cursor_text = ">_ "
	if combo_count > 0:
		cursor_text = "x" + str(combo_count) + " >_ "
	
	if focused_phantom and not current_typed_string.is_empty():
		cursor.text = cursor_text + current_typed_string
	else:
		cursor.text = cursor_text

func animate_cursor():
	# Additional cursor animations can go here
	pass

func trigger_wake_up():
	can_accept_input = false
	
	# massive screen shake
	add_screen_shake(30.0)
	
	# show stats before reset
	show_game_over_stats()
	save_high_score()

	# white flash
	var flash = create_tween()
	flash.tween_property(transition_rect, "modulate:a", 1.0, 0.3)
	flash.tween_property(transition_rect, "modulate:a", 0.0, 0.5).set_delay(2.0)

	# reset game after flash
	flash.finished.connect(reset_game)

func show_game_over_stats():
	var stats_text = "survived: " + str(int(survival_time)) + "s\n"
	stats_text += "level: " + str(transformation_level) + "\n"
	stats_text += "best combo: " + str(combo_count) + "\n"
	stats_text += "score: " + str(score)
	
	var label = Label.new()
	label.text = stats_text
	if monogram_font:
		label.add_theme_font_override("font", monogram_font)
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.position = Vector2(480, 200)
	label.z_index = 200
	add_child(label)
	
	# fade in
	label.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.5)
	tween.tween_property(label, "modulate:a", 0.0, 0.5).set_delay(2.0)
	tween.finished.connect(func(): label.queue_free())

func reset_game():
	# Clear all phantoms
	for phantom in active_phantoms:
		phantom.queue_free()
	active_phantoms.clear()

	# Reset game state
	focused_phantom = null
	current_typed_string = ""
	lucidity = max_lucidity
	synchronicity_counter = 0
	is_in_sync = false
	survival_time = 0.0
	last_transformation = 0.0
	transformation_level = 0
	typing_speed_multiplier = 1.0
	combo_count = 0
	combo_timer = 0.0
	perfect_streak = 0
	flow_intensity = 0.0
	score = 0
	damage_reduction = 0.0
	health_regen_bonus = 0.0
	max_phantoms_bonus = 0
	power_up_chance_bonus = 0.0
	drawn_cards.clear()
	choosing_upgrade = false
	upgrade_options.clear()

	# Update UI
	update_health_bar()

	# Restart
	start_game()

# ============================================
# escalation system - transformations
# ============================================

func trigger_transformation():
	transformation_level += 1
	typing_speed_multiplier += 0.15
	
	# increase max phantoms gradually
	if transformation_level % 2 == 0:
		max_phantoms = min(max_phantoms + 1, 8)
	
	# show transformation message
	var messages = [
		"accelerating",
		"syncing",
		"fragmenting",
		"merging",
		"cascading",
		"amplifying",
		"distorting",
		"evolving"
	]
	show_transformation_message(messages[transformation_level % messages.size()])
	
	# Pause for upgrade choice
	can_accept_input = false
	choosing_upgrade = true
	upgrade_options = ["speed", "health", "damage"]
	
	# Show choices
	if status_text:
		status_text.text = "choose upgrade:\ntype 'speed', 'health', or 'damage'"
	
	# massive screen shake
	add_screen_shake(20.0)
	
	# JUICE: Multiple static bursts
	for i in range(5):
		var random_pos = Vector2(randf_range(200, 760), randf_range(100, 440))
		spawn_static_burst(random_pos)
		await get_tree().create_timer(0.05).timeout
	
	# JUICE: Heavy CRT glitch
	apply_crt_glitch(2.0, 0.5)
	
	# HIGH STAKES: Less healing, more pressure
	heal_lucidity(10.0)  # REDUCED: was 15.0
	
	# Increase time pressure
	time_pressure_multiplier += 0.15  # Health drains faster each transformation

func show_transformation_message(msg: String):
	# create temporary label for transformation message
	var label = Label.new()
	label.text = msg
	if monogram_font:
		label.add_theme_font_override("font", monogram_font)
	label.add_theme_font_size_override("font_size", 64)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = Vector2(640, 360)
	label.size = Vector2(400, 100)
	label.pivot_offset = Vector2(200, 50)
	label.z_index = 100
	add_child(label)
	
	# Static burst effect
	spawn_screen_static_flash()
	
	# explosive entrance
	label.modulate.a = 0.0
	label.scale = Vector2(0.3, 0.3)
	label.rotation = randf_range(-0.2, 0.2)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "modulate:a", 1.0, 0.1)
	tween.tween_property(label, "scale", Vector2(1.2, 1.2), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "rotation", 0.0, 0.2)
	tween.chain().tween_property(label, "scale", Vector2(1.0, 1.0), 0.1)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.5).set_delay(0.8)
	tween.finished.connect(func(): label.queue_free())

# ============================================
# juice system - screen shake and particles
# ============================================

func add_screen_shake(amount: float):
	screen_shake_amount = min(screen_shake_amount + amount, 30.0)

func apply_screen_shake():
	if screen_shake_amount > 0.1:
		var shake_offset = Vector2(
			randf_range(-screen_shake_amount, screen_shake_amount),
			randf_range(-screen_shake_amount, screen_shake_amount)
		)
		$Camera2D.offset = shake_offset if has_node("Camera2D") else Vector2.ZERO
	else:
		if has_node("Camera2D"):
			$Camera2D.offset = Vector2.ZERO

# ============================================
# combo system
# ============================================

func increment_combo():
	combo_count += 1
	combo_timer = combo_window
	
	# scale screen shake with combo
	var shake = 2.0 + (combo_count * 0.5)
	add_screen_shake(shake)
	
	# show combo text
	if combo_count >= 3:
		show_combo_indicator()

func reset_combo():
	if combo_count >= 5:
		# lose combo message
		show_floating_text("lost", Vector2(480, 100), Color.RED)
	combo_count = 0
	perfect_streak = 0
	flow_intensity = max(0.0, flow_intensity - 0.3)

func show_combo_indicator():
	var combo_label = status_text.duplicate() if status_text else Label.new()
	combo_label.text = "x" + str(combo_count)
	combo_label.position = Vector2(850, 50)
	if monogram_font:
		combo_label.add_theme_font_override("font", monogram_font)
	combo_label.add_theme_font_size_override("font_size", 32)
	combo_label.modulate = Color.WHITE
	add_child(combo_label)
	
	# Static burst on combo indicator
	spawn_static_burst(Vector2(880, 65))
	
	var tween = create_tween()
	tween.tween_property(combo_label, "position:y", 30.0, 0.3)
	tween.parallel().tween_property(combo_label, "modulate:a", 0.0, 0.3).set_delay(0.5)
	tween.finished.connect(func(): combo_label.queue_free())

func show_floating_text(text: String, pos: Vector2, color: Color = Color.WHITE):
	var label = Label.new()
	label.text = text
	if monogram_font:
		label.add_theme_font_override("font", monogram_font)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", color)
	label.position = pos - Vector2(50, 0)  # Center the text better
	label.size = Vector2(100, 50)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)
	
	# Add static glitch on spawn
	spawn_static_burst(pos)
	
	var tween = create_tween()
	tween.tween_property(label, "position:y", pos.y - 50, 1.0)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.0)
	tween.finished.connect(func(): label.queue_free())

# ============================================
# flow state system
# ============================================

func update_flow_state(delta: float):
	# calculate rhythm consistency from recent keypress intervals
	if last_intervals.size() >= 3:
		var avg_interval = 0.0
		for interval in last_intervals:
			avg_interval += interval
		avg_interval /= last_intervals.size()
		
		# calculate variance
		var variance = 0.0
		for interval in last_intervals:
			variance += abs(interval - avg_interval)
		variance /= last_intervals.size()
		
		# low variance = high consistency = flow state
		rhythm_consistency = 1.0 - clamp(variance / 0.5, 0.0, 1.0)
	
	# flow intensity increases with combo and rhythm
	var target_flow = 0.0
	if combo_count >= 3:
		target_flow = clamp(combo_count / 10.0, 0.0, 1.0) * rhythm_consistency
	
	flow_intensity = lerp(flow_intensity, target_flow, delta * 2.0)
	
	# apply flow state visuals
	apply_flow_visuals()

func apply_flow_visuals():
	if flow_intensity > 0.3:
		# pulse background based on flow
		var pulse = sin(Time.get_ticks_msec() * 0.01 * (1.0 + flow_intensity))
		if has_node("Background/ColorRect"):
			var bg = $Background/ColorRect
			# subtle pulse between black and very dark grey
			var intensity = 0.0 + (pulse * 0.05 * flow_intensity)
			bg.color = Color(intensity, intensity, intensity, 1.0)
	else:
		# return to pure black
		if has_node("Background/ColorRect"):
			$Background/ColorRect.color = Color.BLACK
	
	# increase phantom visibility in flow state
	for phantom in active_phantoms:
		if phantom != focused_phantom:
			var alpha = 0.4 + (flow_intensity * 0.3)
			phantom.modulate.a = alpha

# ============================================
# particle system - juice
# ============================================

func spawn_keystroke_particle(pos: Vector2):
	var particle = Node2D.new()
	particle.position = pos
	phantom_container.add_child(particle)
	
	# create visual particle
	var particles_count = 3
	var particle_data = []
	for i in particles_count:
		var angle = randf() * TAU
		var speed = randf_range(50, 100)
		particle_data.append({
			"pos": Vector2.ZERO,
			"vel": Vector2(cos(angle), sin(angle)) * speed,
			"life": 0.3
		})
	
	particle.set_meta("particles", particle_data)
	particle.set_process(true)
	
	particle.set_script(load("res://scripts/simple_particle.gd"))

func spawn_completion_burst(pos: Vector2):
	# much bigger burst for completion
	var particle = Node2D.new()
	particle.position = pos
	phantom_container.add_child(particle)
	
	var particles_count = 20 + (combo_count * 2)
	var particle_data = []
	for i in particles_count:
		var angle = (i / float(particles_count)) * TAU
		var speed = randf_range(100, 200) * (1.0 + combo_count * 0.1)
		particle_data.append({
			"pos": Vector2.ZERO,
			"vel": Vector2(cos(angle), sin(angle)) * speed,
			"life": randf_range(0.5, 1.0)
		})
	
	particle.set_meta("particles", particle_data)
	particle.set_process(true)
	
	particle.set_script(load("res://scripts/simple_particle.gd"))

# ============================================
# chain reaction system
# ============================================

func check_chain_reaction(explosion_pos: Vector2):
	# if combo is high enough, trigger chain reactions
	if combo_count < 5:
		return
	
	var chain_radius = 150.0 + (combo_count * 10.0)
	
	# find phantoms in radius
	for phantom in active_phantoms:
		if phantom == focused_phantom:
			continue
		
		var distance = phantom.position.distance_to(explosion_pos)
		if distance < chain_radius:
			# trigger chain explosion
			spawn_completion_burst(phantom.position)
			add_screen_shake(3.0)
			
			# damage phantom or remove it
			if randf() < 0.3:  # 30% chance to chain complete
				active_phantoms.erase(phantom)
				phantom.queue_free()
				increment_combo()
				show_floating_text("chain", phantom.position, Color.WHITE)

func check_near_misses():
	# Check for phantoms in danger zone and create tension
	near_miss_count = 0
	var center = Vector2(640, 360)
	
	for phantom in active_phantoms:
		var distance = phantom.position.distance_to(center)
		if distance < danger_zone_radius:
			near_miss_count += 1
	
	# Visual feedback for danger
	if near_miss_count > 0:
		var danger_intensity = float(near_miss_count) / float(max_phantoms)
		# Pulse health bar faster when in danger
		if health_static:
			var shader_mat = health_static.material as ShaderMaterial
			if shader_mat:
				shader_mat.set_shader_parameter("noise_speed", 12.0 + (danger_intensity * 20.0))

func update_phantom_attack_state():
	# Enable phantom attacks only when player is idle for too long
	var should_attack = idle_timer >= idle_attack_threshold
	
	for phantom in active_phantoms:
		phantom.can_attack = should_attack
	
	# Visual warning when idle too long
	if should_attack and not is_near_death:
		# Flash the cursor or show warning
		if fmod(idle_timer, 0.5) < 0.25:
			if protagonist:
				protagonist.modulate = Color(1.0, 0.5, 0.5)  # Reddish tint
		else:
			if protagonist:
				protagonist.modulate = Color.WHITE

func animate_health_static(_delta: float):
	# Constantly animate health static bar for abstract feel
	if health_static:
		var shader_mat = health_static.material as ShaderMaterial
		if shader_mat:
			# Base speed that varies over time
			var time = Time.get_ticks_msec() * 0.001
			var base_speed = 15.0 + sin(time * 0.5) * 8.0
			
			# Add danger intensity if applicable
			if near_miss_count > 0:
				var danger_intensity = float(near_miss_count) / float(max_phantoms)
				base_speed += danger_intensity * 25.0
			
			shader_mat.set_shader_parameter("noise_speed", base_speed)

func maybe_spawn_power_up(pos: Vector2):
	if power_up_resources.size() == 0:
		return
	
	# Higher combo = higher chance
	var spawn_chance = 0.1 + (combo_count * 0.02) + power_up_chance_bonus
	if randf() < spawn_chance:
		var power_data = power_up_resources.pick_random()
		var power_up = PowerUpScene.instantiate()
		power_up_container.add_child(power_up)
		# Wait for node to be ready before calling setup
		await power_up.ready
		if power_up.has_method("setup"):
			power_up.setup(power_data, pos)
		power_up.tree_exited.connect(_on_power_up_collected.bind(power_data))

func _on_power_up_collected(power_data: PowerUpData):
	# Apply power-up effect
	match power_data.power_type:
		"shield":
			if protagonist and protagonist.has_method("activate_shield"):
				protagonist.activate_shield(power_data.duration)
			show_floating_text("shield", Vector2(640, 360), Color.CYAN)
		"slow":
			typing_speed_multiplier = max(0.5, typing_speed_multiplier - 0.2)
			await get_tree().create_timer(power_data.duration).timeout
			typing_speed_multiplier += 0.2
			show_floating_text("slow", Vector2(640, 360), Color.GREEN)
		"rapid":
			typing_speed_multiplier += 0.3
			await get_tree().create_timer(power_data.duration).timeout  
			typing_speed_multiplier -= 0.3
			show_floating_text("rapid", Vector2(640, 360), Color.YELLOW)
		"clear":
			# Clear closest phantom
			if active_phantoms.size() > 0:
				var closest = active_phantoms[0]
				var center = Vector2(640, 360)
				for phantom in active_phantoms:
					if phantom.position.distance_to(center) < closest.position.distance_to(center):
						closest = phantom
				active_phantoms.erase(closest)
				spawn_completion_burst(closest.position)
				closest.queue_free()
				show_floating_text("clear", Vector2(640, 360), Color.RED)

# ============================================
# JUICE & EFFECTS
# ============================================

func spawn_static_burst(pos: Vector2):
	# Create temporary static effect at position
	var static_rect = ColorRect.new()
	static_rect.size = Vector2(60, 60)
	static_rect.position = pos - Vector2(30, 30)
	static_rect.color = Color.WHITE
	
	# Add static shader
	var shader_mat = ShaderMaterial.new()
	var static_shader = load("res://shaders/static_shader.gdshader")
	shader_mat.shader = static_shader
	shader_mat.set_shader_parameter("noise_speed", 50.0)
	static_rect.material = shader_mat
	
	add_child(static_rect)
	
	# Fade out quickly
	var tween = create_tween()
	tween.tween_property(static_rect, "modulate:a", 0.0, 0.3)
	tween.finished.connect(func(): static_rect.queue_free())

func spawn_screen_static_flash():
	# Full screen static flash
	var static_rect = ColorRect.new()
	static_rect.size = Vector2(960, 540)
	static_rect.position = Vector2.ZERO
	static_rect.color = Color.WHITE
	static_rect.z_index = 99
	
	# Add static shader
	var shader_mat = ShaderMaterial.new()
	var static_shader = load("res://shaders/static_shader.gdshader")
	shader_mat.shader = static_shader
	shader_mat.set_shader_parameter("noise_speed", 100.0)
	static_rect.material = shader_mat
	
	add_child(static_rect)
	
	# Quick flash
	var tween = create_tween()
	tween.tween_property(static_rect, "modulate:a", 0.0, 0.15)
	tween.finished.connect(func(): static_rect.queue_free())

func apply_crt_glitch(intensity: float, duration: float = 0.2):
	# Apply CRT glitch effect
	if dither_shader_rect and dither_shader_rect.material:
		# We'll pulse the contrast briefly
		var original_contrast = 1.3
		var glitch_contrast = original_contrast + intensity
		
		var shader_mat = dither_shader_rect.material as ShaderMaterial
		if shader_mat:
			shader_mat.set_shader_parameter("contrast", glitch_contrast)
			await get_tree().create_timer(duration).timeout
			shader_mat.set_shader_parameter("contrast", original_contrast)

func _on_phantom_attacks(phantom: Phantom):
	# Phantom shoots static at player
	spawn_static_projectile(phantom.position, Vector2(640, 360))
	
	# HIGH STAKES: More damage from phantom attacks
	damage_lucidity(phantom_damage)
	
	# Play hurt sound
	SoundManager.play_hurt()
	
	# Protagonist takes damage
	if protagonist and protagonist.has_method("take_damage"):
		protagonist.take_damage()
	
	# Screen shake
	add_screen_shake(10.0)  # INCREASED
	
	# Static burst at player
	spawn_static_burst(Vector2(640, 360))
	
	# CRT glitch on hit
	apply_crt_glitch(0.5, 0.2)

func spawn_static_projectile(from_pos: Vector2, to_pos: Vector2):
	# Create static projectile that travels to player
	var projectile = ColorRect.new()
	projectile.size = Vector2(40, 40)
	projectile.position = from_pos - Vector2(20, 20)
	projectile.color = Color.WHITE
	projectile.z_index = 10
	
	# Add static shader
	var shader_mat = ShaderMaterial.new()
	var static_shader = load("res://shaders/static_shader.gdshader")
	shader_mat.shader = static_shader
	shader_mat.set_shader_parameter("noise_speed", 80.0)
	projectile.material = shader_mat
	
	add_child(projectile)
	
	# Animate to target
	var tween = create_tween()
	tween.tween_property(projectile, "position", to_pos - Vector2(20, 20), 0.3)
	tween.finished.connect(func(): 
		spawn_static_burst(to_pos)
		projectile.queue_free()
	)

# ============================================
# high score system
# ============================================

func save_high_score():
	var high_score = load_high_score()
	if score > high_score:
		var file = FileAccess.open("user://high_score.txt", FileAccess.WRITE)
		if file:
			file.store_string(str(score))
			file.close()

func load_high_score() -> int:
	var file = FileAccess.open("user://high_score.txt", FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		return int(content)
	return 0
