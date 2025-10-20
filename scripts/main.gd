"""
main.gd - DREAM GATE DEFENSE
Coordinate System Refactor:
The world now uses a CENTER ORIGIN. (0,0) is the middle of the 1280x720 playfield.
Screen extents therefore run from -640..+640 (x) and -360..+360 (y).
UI remains in a separate CanvasLayer and still treats its own (0,0) as top-left.
"""
extends Node2D

const VIEW_SIZE: Vector2 = Vector2(1080, 1080)
const HALF_VIEW: Vector2 = VIEW_SIZE * 0.5
const CENTER_ORIGIN: bool = true  # Toggle if you ever want to revert
const PLAYER_POSITION: Vector2 = Vector2.ZERO
const DEBUG_SPAWN := false

# Scenes
const ProtagonistScene = preload("res://scenes/protagonist.tscn")
const PhantomScene = preload("res://scenes/phantom.tscn")
const GateIndicatorScene = preload("res://scenes/gate_indicator.tscn")
const PhantomBurstScript = preload("res://scripts/phantom_burst.gd")
const LevelManagerRes = preload("res://scripts/level_manager.gd")
const CardChoiceModalScene = preload("res://scenes/card_choice_modal.tscn")
const LevelMapScene = preload("res://scenes/level_map.tscn")
const UpgradeShopScene = preload("res://scenes/upgrade_shop.tscn")

# Nodes
@onready var phantom_container = $GameplayArea/PhantomContainer
@onready var protagonist_container = $GameplayArea/ProtagonistContainer
@onready var gate_container = $GameplayArea/GateContainer
@onready var status_text = $UILayer/StatusText
@onready var camera = $Camera2D
@onready var level_progress_bar = $UILayer/LevelProgressBar
@onready var level_progress_label = $UILayer/LevelProgressLabel

var combo_flash = null
var level_text = null

# Gate indicators
var gate_indicators: Dictionary = {}

# Resources
var phantom_resources: Array[PhantomData] = []
var monogram_font: FontFile

# Poetry-themed word pools by wave
var poem_word_pools: Dictionary = {
	1: ["because", "could", "not", "stop", "death", "kindly", "stopped", "carriage", "held", "just", "ourselves", "immortality"],
	2: ["out", "night", "covers", "black", "pit", "pole", "thank", "gods", "unconquerable", "soul", "bloody", "unbowed", "master", "fate", "captain"],
	3: ["hope", "thing", "feathers", "perches", "soul", "sings", "tune", "words", "never", "stops", "heard", "fly", "buzz", "died", "stillness"],
	4: ["happy", "heath", "smiled", "winters", "snow", "clothed", "clothes", "death", "taught", "sing", "notes", "woe"],
	5: ["captain", "fearful", "trip", "done", "ship", "weatherd", "rack", "prize", "sought", "won"],
	6: ["brazen", "giant", "greek", "fame", "stands", "silent", "lips", "give", "tired", "poor", "huddled", "masses", "yearning", "breathe", "free"],
	7: ["let", "us", "go", "then", "you", "and", "evening", "spread", "sky", "patient", "etherised", "table", "measured", "life", "coffee", "spoons"],
	8: ["certain", "slant", "light", "winter", "afternoons", "oppresses", "heft", "cathedral", "tunes", "sound", "barbaric", "yawp", "roofs", "world"],
	9: ["questions", "recurring", "endless", "trains", "faithless", "cities", "filled", "foolish", "good", "amid", "answer", "here", "exists", "identity", "powerful", "play", "contribute", "verse"],
	10: ["celebrate", "myself", "sing", "assume", "shall", "every", "atom", "belonging", "good", "belongs"],
	11: ["wandered", "lonely", "cloud", "floats", "high", "vales", "hills", "once", "saw", "crowd", "host", "golden", "daffodils"],
	12: ["see", "world", "grain", "sand", "heaven", "wild", "flower", "hold", "infinity", "palm", "hand", "eternity", "hour"],
	13: ["tyger", "burning", "bright", "forests", "night", "immortal", "hand", "eye", "frame", "fearful", "symmetry"],
	14: ["brillig", "slithy", "toves", "gyre", "gimble", "wabe", "mimsy", "borogoves", "mome", "raths", "outgrabe"],
	15: ["woods", "lovely", "dark", "deep", "promises", "keep", "miles", "before", "sleep"],
	16: ["what", "life", "full", "care", "time", "stand", "stare", "shut", "eyes", "world", "drops", "dead", "lift", "lids", "born", "again"],
	17: ["dwell", "possibility", "fairer", "house", "prose", "numerous", "windows", "superior", "doors", "success", "counted", "sweetest", "neer", "succeed"],
	18: ["strive", "seek", "find", "not", "yield", "much", "taken", "abides", "strength", "moved", "earth", "heaven", "equal", "temper", "heroic", "hearts", "weak", "time", "fate", "strong", "will"],
	19: ["gather", "rosebuds", "while", "may", "old", "time", "still", "aflying", "flower", "smiles", "today", "tomorrow", "dying", "death", "not", "proud", "mighty", "dreadful"],
	20: ["stand", "grave", "weep", "there", "not", "sleep", "part", "all", "met", "experience", "arch", "wherethrough", "gleams", "untravelld", "world", "margin", "fades", "forever"]
}

var curated_words: PackedStringArray = []  # Will be set based on wave

# Optional human-readable poem names (best-effort). Unknown ones fallback to "poem n".
var poem_names: Dictionary = {
	1: "because i could not stop for death - emily dickinson",
	2: "invictus - william ernest henley",
	3: "hope is the thing with feathers - emily dickinson",
	4: "ode to winter - unknown",
	5: "rime of the ancient mariner - samuel taylor coleridge",
	6: "the new colossus - emma lazarus",
	7: "the love song of j. alfred prufrock - t.s. eliot",
	8: "there is a certain slant of light - emily dickinson",
	9: "unknown poem 9",
	10: "song of myself - walt whitman",
	11: "i wandered lonely as a cloud - william wordsworth",
	12: "to see a world in a grain of sand - william blake",
	13: "the tyger - william blake",
	14: "jabberwocky - lewis carroll",
	15: "stopping by woods on a snowy evening - robert frost",
	16: "unknown poem 16",
	17: "i dwell in possibility - emily dickinson",
	18: "ulysses - alfred lord tennyson",
	19: "to the virgins, to make much of time",
	20: "unknown poem 20"
}

func format_ui(s: String) -> String:
	if s == null:
		return ""
	return s.to_lower()

# Game State
var protagonist = null
var active_phantoms: Array = []
var focused_phantom = null
var current_typed_string: String = ""

# Core Stats (health removed!)
var score: int = 0
var high_score: int = 0
var wave: int = 1
var phantoms_defeated_this_run: int = 0
var fragments_earned_this_run: int = 0

# NEW MECHANIC: Dream Gates (center-origin positions)
var gates: Dictionary = {
	"north": {"position": Vector2(0, -HALF_VIEW.y + 100), "breached": false, "threat_level": 0},
	"south": {"position": Vector2(0, HALF_VIEW.y - 100), "breached": false, "threat_level": 0},
	"east": {"position": Vector2(HALF_VIEW.x - 100, 0), "breached": false, "threat_level": 0},
	"west": {"position": Vector2(-HALF_VIEW.x + 100, 0), "breached": false, "threat_level": 0}
}

# NEW: Spawn zones at edges (slightly inside the boundary for visibility)
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

# NEW: Typing statistics for wave completion
var wave_start_time: float = 0.0
var total_keystrokes_this_wave: int = 0
var correct_keystrokes_this_wave: int = 0
var wave_wpm: float = 0.0
var wave_accuracy: float = 0.0

# Spawn control
var spawn_timer: float = 0.0
var spawn_interval: float = 0.8  # Steady spawn rate
var max_phantoms: int = 999  # Unlimited - only limited by wave total
var phantoms_per_wave: int = 30  # Longer waves
var phantoms_spawned_this_wave: int = 0

# Card and level systems
var level_manager := LevelManagerRes.new()
var phantoms_resolved_total: int = 0
var card_resources: Array[CardData] = []
var drawn_cards: Array[CardData] = []
var choosing_card: bool = false
var current_deck: Array[CardData] = []

# Visual progress fill (0.0 .. 1.0) used for the black/white progress bar
var level_progress_fill: float = 0.0
const MISTAKE_PROGRESS_PENALTY: float = 0.08

# Control
var can_accept_input: bool = false
var game_over: bool = false
var wave_transitioning: bool = false  # Prevent calling show_poem_then_next multiple times

func _ready():
	# Load font
	monogram_font = load("res://fonts/monogram-extended.ttf")

	# Load high score
	load_high_score()

	# Get optional nodes
	if has_node("UILayer/ComboFlash"):
		combo_flash = $UILayer/ComboFlash

	# Create level indicator label
	create_level_indicator()

	# Apply upgrades
	apply_upgrades()

	# Load phantom resources
	load_phantom_resources()

	# Position camera so (0,0) is the center of playfield
	if camera:
		camera.position = Vector2.ZERO

	# Spawn protagonist
	protagonist = ProtagonistScene.instantiate()
	protagonist_container.add_child(protagonist)

	# Spawn gate indicators
	if gate_container:
		spawn_gate_indicators()

	# Setup UI
	update_ui()

	# Load cards
	_load_card_resources()

	# Start game
	await get_tree().create_timer(1.0).timeout
	start_game()

func create_level_indicator():
	# Create a label to show current level info
	level_text = Label.new()
	level_text.name = "LevelText"
	level_text.position = Vector2(120, 54)
	level_text.size = Vector2(800, 30)
	level_text.add_theme_font_override("font", monogram_font)
	level_text.add_theme_font_size_override("font_size", 20)
	level_text.add_theme_color_override("font_color", Color(2.0, 2.0, 2.0, 1.0))
	level_text.text = format_ui("level 1: the surface dream")
	$UILayer.add_child(level_text)

func apply_upgrades():
	# apply persistent upgrades from UpgradeManager (health upgrades removed!)
	if UpgradeManager:
		combo = int(UpgradeManager.get_upgrade_value("starting_combo"))
		on_beat_window += UpgradeManager.get_upgrade_value("rhythm_window")
		combo_timeout += UpgradeManager.get_upgrade_value("combo_duration")
	else:
		print("ERROR: UpgradeManager not found!")

func spawn_gate_indicators():
	for gate_name in gates:
		var indicator = GateIndicatorScene.instantiate()
		indicator.position = gates[gate_name]["position"]
		gate_container.add_child(indicator)
		# Set properties after adding to tree
		if indicator.has_method("set_gate_name"):
			indicator.set_gate_name(gate_name)
		gate_indicators[gate_name] = indicator

func load_phantom_resources():
	var loaded_count := 0
	var dir = DirAccess.open("res://phantoms")
	if dir:
		# Attempt directory listing (may fail on HTML5 exports)
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

	# If nothing was loaded (common on some HTML5 exports), fall back to a static registry
	if loaded_count == 0:
		print("[load_phantom_resources] DirAccess returned no files; using phantom_registry fallback.")
		# Prefer preloaded resources (ensures exporter included them)
		var reg := preload("res://scripts/phantom_registry.gd")
		if reg.PHANTOM_RESOURCES and reg.PHANTOM_RESOURCES.size() > 0:
			for r in reg.PHANTOM_RESOURCES:
				if r:
					phantom_resources.append(r)
					loaded_count += 1
		else:
			# As a last resort, try the path list (older fallback)
			for p in reg.PHANTOM_PATHS:
				var phantom_data = load(p) as PhantomData
				if phantom_data:
					phantom_resources.append(phantom_data)
					loaded_count += 1

	if loaded_count == 0:
		push_error("Failed to load any phantom resources. Check that res://phantoms/*.tres are exported.")
	else:
		print("[load_phantom_resources] Loaded %d phantom resources." % loaded_count)
func _load_card_resources():
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

func _apply_card_effect(card: CardData):
	match card.effect:
		"typing_speed":
			# improve rhythm window as proxy for speed feel
			on_beat_window += card.value
		"damage_reduction":
			# Health removed! This now gives combo duration instead
			combo_timeout += card.value * 2.0
		"health_regen":
			# Health removed! This now gives starting combo instead
			combo += int(card.value * 3.0)
		"max_phantoms":
			max_phantoms += int(card.value)
		"power_up_chance":
			spawn_interval = max(0.6, spawn_interval - 0.1)

func _draw_cards_and_choose():
	if choosing_card or card_resources.is_empty():
		return

	print("[debug] _draw_cards_and_choose() starting")
	choosing_card = true
	can_accept_input = false  # Disable game input during card choice

	drawn_cards.clear()
	for i in 3:
		var c = card_resources.pick_random()
		drawn_cards.append(c)

	# Spawn pretty modal
	var modal = CardChoiceModalScene.instantiate()
	modal.cards = drawn_cards.duplicate()
	add_child(modal)
	modal.card_chosen.connect(func(card: CardData):
		print("[debug] card chosen:", card.name)
		_apply_card_effect(card)
		current_deck.append(card)
		_recalculate_synergies()
		_clear_card_choices()
	)

func _clear_card_choices():
	print("[debug] _clear_card_choices() called, re-enabling input")
	choosing_card = false
	# Re-enable gameplay input after card choice
	if not game_over:
		can_accept_input = true

func update_word_pool():
	# Set the word pool based on current wave
	if poem_word_pools.has(wave):
		curated_words = PackedStringArray(poem_word_pools[wave])
	else:
		# For waves beyond 20, cycle through the poems
		var cycle_wave = ((wave - 1) % 20) + 1
		if poem_word_pools.has(cycle_wave):
			curated_words = PackedStringArray(poem_word_pools[cycle_wave])
		else:
			# Fallback to first poem
			curated_words = PackedStringArray(poem_word_pools[1])

func start_game():
	can_accept_input = false  # Disable input until popup is dismissed
	spawn_timer = spawn_interval
	status_text.text = format_ui("defend the gates | wave %d" % wave)

	# New run deck
	current_deck.clear()

	# Reset run-specific counters
	phantoms_spawned_this_wave = 0
	phantoms_defeated_this_run = 0
	fragments_earned_this_run = 0

	# Set initial word pool (ensure PackedStringArray type)
	update_word_pool()
	if typeof(curated_words) != TYPE_ARRAY:
		# coerce Dictionary/PackedArray to PackedStringArray if necessary
		curated_words = PackedStringArray(curated_words)

	# Reset visual progress fill
	level_progress_fill = 0.0

	# Start background music for gameplay
	SoundManager.start_background_music()

	# SHOW WAVE START POPUP IMMEDIATELY
	show_wave_start_popup()

func _process(delta):
	if game_over:
		# Don't update UI during game over
		return

	# Clean up any dead/queued phantoms left in the active_phantoms array
	_cleanup_active_phantoms()

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
				status_text.text = format_ui("combo lost | wave %d" % wave)
	
	# Spawn phantoms (but not during card choice!)
	if not choosing_card:
		spawn_timer -= delta
		if spawn_timer <= 0:
			if phantoms_spawned_this_wave < phantoms_per_wave:
				spawn_phantom()
				spawn_timer = spawn_interval
	
	# Update phantoms - move directly toward player center
	for phantom in active_phantoms:
		if phantom and is_instance_valid(phantom):
			phantom.target_position = PLAYER_POSITION
			if phantom.position.distance_to(PLAYER_POSITION) < 40:
				phantom_hits_player(phantom)

	# Debug: constantly check wave status
	if phantoms_spawned_this_wave >= phantoms_per_wave - 2:  # Near end of wave
		if not has_meta("debug_printed_this_frame"):
			print("[DEBUG] wave status: spawned=", phantoms_spawned_this_wave, "/", phantoms_per_wave, " active=", active_phantoms.size(), " transitioning=", wave_transitioning)
			set_meta("debug_printed_this_frame", true)
			var _tmp_timer = get_tree().create_timer(0.5)
			var _cb_clear_meta = func():
				remove_meta("debug_printed_this_frame")
			_tmp_timer.timeout.connect(_cb_clear_meta)

	# Check wave completion (even if player isn't typing!)
	if not wave_transitioning and phantoms_spawned_this_wave >= phantoms_per_wave and active_phantoms.size() == 0:
		print("[DEBUG] ========== WAVE COMPLETED ==========")
		print("[DEBUG] spawned:", phantoms_spawned_this_wave, "/ required:", phantoms_per_wave)
		print("[DEBUG] active phantoms:", active_phantoms.size())
		print("[DEBUG] wave_transitioning:", wave_transitioning)
		print("[DEBUG] game_over:", game_over)
		print("[DEBUG] calling show_poem_then_next()...")
		wave_transitioning = true
		# Await the poem popup sequence so flow is sequential and wave increments reliably
		await show_poem_then_next()

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
	# Create a new data resource so we can safely override the word with a curated one
	var new_data := PhantomData.new()
	new_data.art = phantom_data.art

	# Choose curated word when available, otherwise fall back to phantom_data
	var word: String = phantom_data.text_to_type
	if curated_words and curated_words.size() > 0:
		# pick a random word from curated list
		word = String(curated_words[randi() % curated_words.size()])

	new_data.text_to_type = word
	var len_scale: float = clamp(float(word.length()) / 5.0, 0.8, 1.4)
	new_data.base_speed = phantom_data.base_speed * len_scale * 1.8  # 80% faster!
	new_data.level = phantom_data.level
	new_data.rarity = phantom_data.rarity
	phantom.setup_phantom(new_data)

	# apply phantom slowdown upgrade
	if UpgradeManager:
		var slowdown = UpgradeManager.get_upgrade_value("phantom_slowdown")
		phantom.move_speed *= (1.0 - slowdown)

	phantom.position = spawn_pos + Vector2(randf_range(-40, 40), randf_range(-40, 40))
	phantom_container.add_child(phantom)

	# Enhanced spawn animation with flash
	phantom.scale = Vector2(0.3, 0.3)
	phantom.modulate = Color(2.0, 2.0, 2.0, 1.0)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(phantom, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(phantom, "modulate", Color.WHITE, 0.3)

	active_phantoms.append(phantom)

	# Ensure we remove the phantom from active_phantoms when it completes
	if phantom.has_signal("phantom_completed"):
		phantom.phantom_completed.connect(_on_phantom_completed)

	phantoms_spawned_this_wave += 1
	phantom.target_position = PLAYER_POSITION

	# Screen flash on spawn
	add_screen_shake(0.5)

	if DEBUG_SPAWN:
		print("Spawn phantom at", phantom.position, "word=", phantom.phantom_data.text_to_type)

	# Increase visual progress fill slightly when a new phantom spawns (so bar moves forward as wave fills)
	if phantoms_per_wave > 0:
		level_progress_fill = clamp(float(phantoms_spawned_this_wave) / float(phantoms_per_wave), 0.0, 1.0)


func _cleanup_active_phantoms():
	# Remove invalid or freed phantom references from the active_phantoms array
	for i in range(active_phantoms.size() - 1, -1, -1):
		var p = active_phantoms[i]
		if not is_instance_valid(p):
			active_phantoms.remove_at(i)


func get_nearest_gate(_pos: Vector2) -> Vector2:
	# Legacy helper kept for compatibility; not used in center-seeking mode
	return PLAYER_POSITION

func update_gate_threats():
	# Threat levels no longer used (phantoms go straight to center). Left as stub.
	pass

func gate_breach(_phantom, _gate_name):
	# Legacy function; no longer used.
	pass

func phantom_hits_player(phantom):
	# No damage - just remove the phantom and give feedback
	active_phantoms.erase(phantom)
	phantom.queue_free()
	add_screen_shake(2.0)
	SoundManager.play_hurt()
	if status_text:
		status_text.text = format_ui("phantom escaped! | wave %d" % wave)


func _on_phantom_completed(_phantom: Node) -> void:
	# Called when a phantom finishes (emits phantom_completed)
	if _phantom in active_phantoms:
		active_phantoms.erase(_phantom)
	# Ensure the node is freed if still valid
	if is_instance_valid(_phantom):
		_phantom.queue_free()

func _unhandled_input(event: InputEvent):
	if not can_accept_input or game_over:
		return
	
	if event is InputEventKey and event.pressed and not event.is_echo():
			handle_key_input(event)

func _recalculate_synergies():
	# simple synergy examples: stacking same effect increases potency
	var typing_speed_count = 0
	var regen_count = 0
	for c in current_deck:
		if c.effect == "typing_speed":
			typing_speed_count += 1
		elif c.effect == "health_regen":
			regen_count += 1
	# apply lightweight synergies (health removed!)
	if typing_speed_count >= 2:
		on_beat_window = min(on_beat_window + 0.02 * (typing_speed_count - 1), 0.5)
	if regen_count >= 2:
		# Health removed! Regen cards now give combo bonuses
		combo += regen_count - 1

func handle_key_input(event: InputEventKey):
	if event.keycode == KEY_BACKSPACE:
		if current_typed_string.length() > 0:
			current_typed_string = current_typed_string.left(current_typed_string.length() - 1)
			if focused_phantom:
				focused_phantom.update_typing_progress(current_typed_string)
		return
	elif event.keycode == KEY_TAB:
		cycle_focus()
		return
	elif event.keycode == KEY_ESCAPE:
		clear_focus()
		return

	var uni = event.unicode
	if uni == 0:
		return
	var character = char(uni).to_lower()
	if character == "\n" or character == "\r":
		return
	process_character(character)

func process_character(character: String):
	var current_time = Time.get_ticks_msec() / 1000.0
	last_input_time = current_time

	# Track total keystrokes for WPM calculation
	total_keystrokes_this_wave += 1

	SoundManager.play_type()

	if focused_phantom == null:
		# Find phantom whose first char matches (case-insensitive)
		for phantom in active_phantoms:
			if phantom and is_instance_valid(phantom):
				var text: String = phantom.phantom_data.text_to_type
				if text.length() > 0 and text[0].to_lower() == character:
					focus_phantom(phantom)
					current_typed_string = character
					phantom.update_typing_progress(current_typed_string)
					return
		# Provide feedback if no match (no damage!)
		add_screen_shake(0.4)
		SoundManager.play_hurt()
	else:
		# Continue typing focused phantom
		var expected = focused_phantom.phantom_data.text_to_type

		if expected.begins_with(current_typed_string + character):
			current_typed_string += character
			correct_keystrokes_this_wave += 1  # Track correct keystrokes
			focused_phantom.update_typing_progress(current_typed_string)
			# Fire tracer for satisfying feedback and pulse the player
			if is_instance_valid(protagonist) and is_instance_valid(focused_phantom):
				_spawn_tracer(protagonist.global_position, focused_phantom.global_position + Vector2(0, 30))
				if protagonist.has_method("attack_pulse"):
					protagonist.attack_pulse()

			# Check completion
			if current_typed_string == expected:
				complete_phantom()
		else:
			# Mistake - try to start a new phantom with this character
			mistake()
			# After mistake, try to start typing a new phantom
			process_character(character)

func focus_phantom(phantom):
	focused_phantom = phantom
	phantom.set_focused(true)
	# Fire a lock-on tracer from player to the focused phantom text
	if is_instance_valid(protagonist):
		_spawn_tracer(protagonist.global_position, phantom.global_position + Vector2(0, 30))

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

	# award dream fragments (1 per phantom + bonus for combo)
	var fragments: int = 1 + int(float(combo) / 5.0)
	fragments_earned_this_run += fragments
	phantoms_defeated_this_run += 1
	phantoms_resolved_total += 1

	# Visual feedback with explosion animation
	SoundManager.play_dealt()
	var shake_power = min(2.0 + (combo * 0.2), 5.0)
	add_screen_shake(shake_power)

	# combo flash on screen edges
	if combo > 5:
		add_combo_flash()

	# create particle burst at phantom position
	var explosion_pos = focused_phantom.position
	var burst = Node2D.new()
	burst.set_script(PhantomBurstScript)
	burst.position = explosion_pos
	get_node("GameplayArea").add_child(burst)

	# create fragment label
	var explosion_label = Label.new()
	explosion_label.position = explosion_pos
	explosion_label.text = "+%d" % fragments
	explosion_label.add_theme_font_override("font", monogram_font)
	explosion_label.add_theme_font_size_override("font_size", 36)
	explosion_label.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0, 1.0))
	explosion_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	explosion_label.add_theme_constant_override("outline_size", 2)
	get_node("GameplayArea").add_child(explosion_label)

	var explosion_tween = create_tween()
	explosion_tween.set_parallel(true)
	explosion_tween.tween_property(explosion_label, "scale", Vector2(2.0, 2.0), 0.4)
	explosion_tween.tween_property(explosion_label, "modulate:a", 0.0, 0.4)
	explosion_tween.tween_property(explosion_label, "position", explosion_pos + Vector2(0, -50), 0.4)
	var _cb_explosion = func():
		explosion_label.queue_free()
	explosion_tween.finished.connect(_cb_explosion)

	# remove phantom with dissolve effect
	var death_tween = create_tween()
	death_tween.set_parallel(true)
	death_tween.tween_property(focused_phantom, "modulate:a", 0.0, 0.2)
	death_tween.tween_property(focused_phantom, "scale", Vector2(1.5, 1.5), 0.2)
	death_tween.tween_property(focused_phantom, "rotation", randf_range(-PI/4, PI/4), 0.2)
	var _cb_death = func():
		if is_instance_valid(focused_phantom):
			focused_phantom.queue_free()
	death_tween.finished.connect(_cb_death)

	active_phantoms.erase(focused_phantom)
	focused_phantom = null
	current_typed_string = ""

	# Note: Wave completion is now checked in _process() so it happens automatically

	update_ui()

func mistake():
	combo = 0
	current_typed_string = ""
	if focused_phantom:
		focused_phantom.set_focused(false)
		focused_phantom = null

	# No damage! Just lose combo and visual feedback

	# Regress progress visually on mistake
	level_progress_fill = max(0.0, level_progress_fill - MISTAKE_PROGRESS_PENALTY)
	# Also update the progress bar immediately
	update_level_progress_bar()

	SoundManager.play_hurt()
	add_screen_shake(3.0)

	# Red flash for mistakes
	add_mistake_flash()

func take_damage(amount: float):
	# Health system removed! This function is kept for compatibility but does nothing
	print("[take_damage] called with amount=", amount, " but health system is disabled")

func next_wave():
	print("[DEBUG] ========== next_wave() START ==========")
	print("[DEBUG] previous wave:", wave)
	wave += 1
	print("[DEBUG] new wave:", wave)
	phantoms_spawned_this_wave = 0
	wave_transitioning = false  # Reset transition flag for new wave
	spawn_interval = max(0.4, spawn_interval - 0.05)  # Gets intense gradually
	# max_phantoms stays unlimited

	# Reset typing statistics for new wave
	wave_start_time = Time.get_ticks_msec() / 1000.0
	total_keystrokes_this_wave = 0
	correct_keystrokes_this_wave = 0

	# Reset visual progress fill for the new wave
	level_progress_fill = 0.0

	# Update word pool for new wave
	print("[DEBUG] updating word pool...")
	update_word_pool()

	# Level progression check and card reward
	var info = level_manager.get_level_info(wave)
	if info.has("spawn_rate"):
		spawn_interval = max(0.6, info["spawn_rate"])
	if info.has("phantom_speed_multiplier"):
		for p in active_phantoms:
			if p and is_instance_valid(p):
				p.move_speed *= info["phantom_speed_multiplier"]

	# Wave transition with screen flash
	add_screen_shake(4.0)

	# Flash the screen
	var flash = ColorRect.new()
	flash.color = Color.WHITE
	flash.modulate.a = 0.6
	flash.position = Vector2(-540, -540)
	flash.size = Vector2(1080, 1080)
	get_node("GameplayArea").add_child(flash)

	var flash_tween = create_tween()
	flash_tween.tween_property(flash, "modulate:a", 0.0, 0.5)
	var _cb_flash = func():
		flash.queue_free()
	flash_tween.finished.connect(_cb_flash)

	if status_text:
		status_text.text = format_ui("wave %d | combo x%d" % [wave, combo])

	# Level-specific visuals (tweak vignette as a cue)
	var info2 = level_manager.get_level_info(wave)
	if info2.has("phantom_speed_multiplier") and has_node("Background/Vignette"):
		var vig = $Background/Vignette
		if vig.material and vig.material is ShaderMaterial:
			var sm: ShaderMaterial = vig.material
			var falloff = 0.6 - (0.02 * (wave - 1))
			sm.set_shader_parameter("falloff", clamp(falloff, 0.3, 0.6))

	# Show ASCII level map before cards (skip for wave 2 after completing wave 1)
	if wave != 2:
		print("[DEBUG] about to await show_level_map()...")
		await show_level_map()
		print("[DEBUG] show_level_map() await completed!")

		# Offer cards each wave (after map is dismissed)
		print("[DEBUG] calling _draw_cards_and_choose()...")
		_draw_cards_and_choose()
	else:
		# After wave 1 completion, show upgrade shop instead
		print("[DEBUG] wave 2 reached (after wave 1), showing upgrade shop...")
		await show_upgrade_shop_after_wave_1()
		print("[DEBUG] upgrade shop dismissed, showing wave start popup...")
		# Show wave start popup for wave 2
		show_wave_start_popup()
	print("[DEBUG] ========== next_wave() END ==========")

func show_upgrade_shop_after_wave_1():
	# Create and show upgrade shop after wave 1 completion
	var upgrade_shop = UpgradeShopScene.instantiate()
	add_child(upgrade_shop)

	# Wait for upgrade shop to be dismissed (when player continues)
	await upgrade_shop.tree_exited

	print("[DEBUG] upgrade shop dismissed, continuing to wave 2...")

	# Restart gameplay music (lucidity.mp3) after shop closes
	SoundManager.start_background_music()

func show_poem_then_next():
	print("[DEBUG] ========== show_poem_then_next() START ==========")
	print("[DEBUG] current wave:", wave)
	print("[DEBUG] game_over:", game_over)

	# Check if game is over - don't advance if player died
	if game_over:
		print("[DEBUG] game_over is true, skipping wave transition")
		return

	# Disable input while showing victory popup
	can_accept_input = false

	# Determine poem name for the current wave (use cycle logic to match update_word_pool)
	var poem_idx = wave
	if not poem_word_pools.has(poem_idx):
		poem_idx = ((wave - 1) % 20) + 1

	var poem_name = poem_names.get(poem_idx, "poem %d" % poem_idx)
	print("[DEBUG] showing poem:", poem_name)

	# Calculate typing statistics for this wave
	var wave_end_time = Time.get_ticks_msec() / 1000.0
	var wave_duration_minutes = max(0.1, (wave_end_time - wave_start_time) / 60.0)  # Avoid division by zero
	
	if total_keystrokes_this_wave > 0:
		wave_accuracy = float(correct_keystrokes_this_wave) / float(total_keystrokes_this_wave) * 100.0
	else:
		wave_accuracy = 0.0
	
	# WPM = (characters typed / 5) / time in minutes
	wave_wpm = (correct_keystrokes_this_wave / 5.0) / wave_duration_minutes

	# Create BIG CENTRAL VICTORY POPUP IMMEDIATELY
	show_wave_complete_popup(poem_name)

	# Wait for player to press any key to continue
	print("[DEBUG] waiting for player to press any key...")
	var key_pressed = false
	while not key_pressed and not game_over:
		await get_tree().process_frame
		# Check for any key press
		for key in range(KEY_0, KEY_Z + 1):
			if Input.is_key_pressed(key):
				key_pressed = true
				SoundManager.play_dealt()
				break
		# Also check common keys
		if Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_ENTER) or Input.is_key_pressed(KEY_ESCAPE):
			key_pressed = true
			SoundManager.play_dealt()

	# Remove popup
	if has_node("UILayer/WaveCompletePopup"):
		$UILayer/WaveCompletePopup.queue_free()

	print("[DEBUG] key pressed, calling next_wave...")
	if not game_over:
		next_wave()  # Call directly instead of deferred

	print("[DEBUG] ========== show_poem_then_next() END ==========")

func show_wave_start_popup():
	# Create a BIG CENTRAL POPUP for wave start
	print("[DEBUG] ========== SHOWING WAVE START POPUP ==========")
	var popup = Control.new()
	popup.name = "WaveStartPopup"
	popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup.mouse_filter = Control.MOUSE_FILTER_STOP
	popup.z_index = 100  # Make sure it's on top!

	# Dark overlay background
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.85)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup.add_child(overlay)

	# Center container
	var center = VBoxContainer.new()
	center.set_anchors_preset(Control.PRESET_CENTER)
	center.offset_left = -400
	center.offset_top = -200
	center.offset_right = 400
	center.offset_bottom = 200
	center.add_theme_constant_override("separation", 30)

	# Wave number - BIG
	var wave_title = Label.new()
	wave_title.text = format_ui("wave %d" % wave)
	wave_title.add_theme_font_override("font", monogram_font)
	wave_title.add_theme_font_size_override("font_size", 100)
	wave_title.add_theme_color_override("font_color", Color(2.5, 2.5, 2.5))
	wave_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(wave_title)

	# Get poem name for this wave
	var poem_idx = wave
	if not poem_word_pools.has(poem_idx):
		poem_idx = ((wave - 1) % 20) + 1
	var poem_name = poem_names.get(poem_idx, "poem %d" % poem_idx)

	# Poem name
	var poem_label = Label.new()
	poem_label.text = poem_name.to_lower()
	poem_label.add_theme_font_override("font", monogram_font)
	poem_label.add_theme_font_size_override("font_size", 36)
	poem_label.add_theme_color_override("font_color", Color(1.8, 1.8, 1.8))
	poem_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(poem_label)

	# Ready prompt
	var ready_prompt = Label.new()
	ready_prompt.text = format_ui("press any key to start")
	ready_prompt.add_theme_font_override("font", monogram_font)
	ready_prompt.add_theme_font_size_override("font_size", 28)
	ready_prompt.add_theme_color_override("font_color", Color(2.0, 2.0, 2.0))
	ready_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(ready_prompt)

	# Blink animation for ready prompt
	# Start a safe coroutine-based blink (avoid set_loops to prevent engine infinite-loop detection)
	_start_blink(ready_prompt, 0.3, 0.8, 1.0, 0.8)

	popup.add_child(center)
	$UILayer.add_child(popup)

	# Animate popup entrance
	popup.modulate.a = 0.0
	var entrance_tween = create_tween()
	entrance_tween.tween_property(popup, "modulate:a", 1.0, 0.3)

	# Wait for player to press any key
	print("[DEBUG] waiting for key press to start wave...")
	await _wait_for_any_key()

	# Remove popup
	print("[DEBUG] key pressed! removing popup and starting wave...")
	popup.queue_free()

	# Enable input
	can_accept_input = true
	print("[DEBUG] wave started! input enabled!")

func _wait_for_any_key():
	var key_pressed = false
	while not key_pressed:
		await get_tree().process_frame
		# Check for any key press
		if Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_ENTER):
			key_pressed = true
			SoundManager.play_dealt()
			break
		# Check any letter/number key
		for key in range(KEY_A, KEY_Z + 1):
			if Input.is_key_pressed(key):
				key_pressed = true
				SoundManager.play_dealt()
				break
		if key_pressed:
			break




func show_wave_complete_popup(poem_name: String):
	# Create a BIG CENTRAL POPUP for wave completion
	var popup = Control.new()
	popup.name = "WaveCompletePopup"
	popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup.mouse_filter = Control.MOUSE_FILTER_STOP
	popup.z_index = 100  # Make sure it's on top!

	# Dark overlay background
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.8)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup.add_child(overlay)

	# Center container
	var center = VBoxContainer.new()
	center.set_anchors_preset(Control.PRESET_CENTER)
	center.offset_left = -400
	center.offset_top = -200
	center.offset_right = 400
	center.offset_bottom = 200
	center.add_theme_constant_override("separation", 20)

	# Title
	var title = Label.new()
	title.text = format_ui("WAVE %d CLEARED!" % wave)
	title.add_theme_font_override("font", monogram_font)
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", Color(2.0, 2.0, 2.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(title)

	# Poem name
	var poem_label = Label.new()
	poem_label.text = format_ui("poem: %s" % poem_name.to_lower())
	poem_label.add_theme_font_override("font", monogram_font)
	poem_label.add_theme_font_size_override("font_size", 32)
	poem_label.add_theme_color_override("font_color", Color(1.5, 1.5, 1.5))
	poem_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(poem_label)

	# Stats
	var stats = Label.new()
	stats.text = format_ui("score: %d | combo: x%d | fragments: +%d\nwpm: %.1f | accuracy: %.1f%%" % [score, max_combo, fragments_earned_this_run, wave_wpm, wave_accuracy])
	stats.add_theme_font_override("font", monogram_font)
	stats.add_theme_font_size_override("font_size", 28)
	stats.add_theme_color_override("font_color", Color(1.2, 1.2, 1.2))
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(stats)

	# Continue prompt
	var continue_prompt = Label.new()
	continue_prompt.text = format_ui("press any key to continue")
	continue_prompt.add_theme_font_override("font", monogram_font)
	continue_prompt.add_theme_font_size_override("font_size", 24)
	continue_prompt.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	continue_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(continue_prompt)

	# Blink animation for continue prompt
	# Start a safe coroutine-based blink (avoid set_loops to prevent engine infinite-loop detection)
	_start_blink(continue_prompt, 0.3, 0.8, 1.0, 0.8)

	popup.add_child(center)
	$UILayer.add_child(popup)

	# Animate popup entrance
	popup.modulate.a = 0.0
	var entrance_tween = create_tween()
	entrance_tween.tween_property(popup, "modulate:a", 1.0, 0.3)

func show_level_map():
	print("[debug] show_level_map() called for wave:", wave)

	# Disable input during map display
	can_accept_input = false

	# Create and show level map
	var level_map = LevelMapScene.instantiate()
	add_child(level_map)
	level_map.setup(wave, level_manager)

	# Wait for map to be dismissed
	await level_map.map_dismissed

	print("[debug] level_map dismissed! re-enabling input")

	# Re-enable input
	if not game_over:
		can_accept_input = true
	else:
		print("[debug] game_over=true, not re-enabling input")

func update_level_text():
	if level_text:
		var level_info = level_manager.get_level_info(wave)
		if level_info.has("name"):
			level_text.text = format_ui("level %d: %s" % [wave, level_info["name"]])
		else:
			# For waves beyond defined levels, show generic text
			level_text.text = format_ui("level %d: the deep unknown" % wave)

func update_ui():
	if status_text:
		var combo_text = (" | combo x%d" % combo) if combo > 0 else ""
		var rhythm_text = " [R]" if rhythm_bonus_active else ""
		var phantoms_remaining = phantoms_per_wave - phantoms_spawned_this_wave + active_phantoms.size()
		status_text.text = format_ui("wave %d | phantoms: %d | score: %d%s%s" % [wave, phantoms_remaining, score, combo_text, rhythm_text])

	# No health bar anymore!
	update_level_text()
	update_level_progress_bar()
	# Show current input in cursor if present
	if has_node("UILayer/Cursor"):
		$UILayer/Cursor.text = ">_" + current_typed_string

func cycle_focus():
	if active_phantoms.size() == 0:
		return
	var idx = active_phantoms.find(focused_phantom)
	if idx == -1:
		focus_phantom(active_phantoms[0])
		current_typed_string = ""
		return
	focused_phantom.set_focused(false)
	idx = (idx + 1) % active_phantoms.size()
	focus_phantom(active_phantoms[idx])
	current_typed_string = ""

func clear_focus():
	if focused_phantom:
		focused_phantom.set_focused(false)
	focused_phantom = null
	current_typed_string = ""

func update_health_bar():
	# Health bar removed - using progress bar only now
	pass

func update_level_progress_bar():
	if level_progress_bar and level_progress_label:
		# Use the visual fill to size the bar; label still shows counts
		var max_width = 480.0
		var new_width = max_width * clamp(level_progress_fill, 0.0, 1.0)
		level_progress_bar.size = Vector2(new_width, 20.0)

		# Update label (concise black/white display)
		level_progress_label.text = format_ui("wave: %d/%d" % [phantoms_spawned_this_wave, phantoms_per_wave])

func add_screen_shake(amount: float):
	if camera:
		var shake_offset = Vector2(randf_range(-amount, amount), randf_range(-amount, amount))
		camera.offset = shake_offset
		var tween = create_tween()
		tween.tween_property(camera, "offset", Vector2.ZERO, 0.1)

func _spawn_tracer(from: Vector2, to: Vector2):
	var tracer := TextTracer.new()
	tracer.setup(from, to)
	get_node("GameplayArea").add_child(tracer)
	if is_instance_valid(protagonist) and protagonist.has_method("face_direction"):
		protagonist.face_direction(to)

func add_combo_flash():
	if not combo_flash:
		return

	var intensity = min(combo / 50.0, 0.3)
	combo_flash.modulate = Color(1.0, 1.0, 1.0, intensity)

	var tween = create_tween()
	tween.tween_property(combo_flash, "modulate:a", 0.0, 0.2)

func add_mistake_flash():
	# Create a red flash overlay for mistakes
	var flash = ColorRect.new()
	flash.color = Color.RED
	flash.modulate.a = 0.4
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Add to UILayer so it appears on top of everything
	if has_node("UILayer"):
		flash.set_anchors_preset(Control.PRESET_FULL_RECT)
		$UILayer.add_child(flash)
	else:
		# Fallback to GameplayArea with manual positioning
		flash.position = Vector2(-540, -540)
		flash.size = Vector2(1080, 1080)
		get_node("GameplayArea").add_child(flash)

	# Quick fade out
	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.3)
	var _cb_flash2 = func():
		flash.queue_free()
	tween.finished.connect(_cb_flash2)

func end_game():
	game_over = true
	can_accept_input = false
	choosing_card = false  # Cancel any card selection

	# Ensure the scene tree is not accidentally paused by any awaiting code or external platform
	# (some HTML5 tooling or platform integrations can pause the main loop; force unpause here)
	if Engine.has_singleton("SceneTree"):
		# In Godot 4 SceneTree.pause is controlled via get_tree().paused
		get_tree().paused = false

	print("[end_game] game_over set, inputs disabled. Forcing get_tree().paused = false")

	# Clear ALL active phantoms from screen (including any that might be spawning)
	for phantom in active_phantoms:
		if phantom and is_instance_valid(phantom):
			phantom.queue_free()
	active_phantoms.clear()
	focused_phantom = null
	current_typed_string = ""

	# Clear any lingering phantom nodes in container
	if phantom_container:
		for child in phantom_container.get_children():
			if is_instance_valid(child):
				child.queue_free()

	# Hide the progress bar and related UI since we only want the status text
	if level_progress_bar:
		level_progress_bar.visible = false
	if level_progress_label:
		level_progress_label.visible = false
	if has_node("UILayer/Cursor"):
		$UILayer/Cursor.visible = false
	if level_text:
		level_text.visible = false

	# Remove any card choice modals or level maps that might be open
	for child in get_children():
		if child is CardChoiceModal or child.name == "LevelMap":
			print("[end_game] removing lingering UI node:", child.name)
			child.queue_free()

	if score > high_score:
		high_score = score
		save_high_score()

	# save run data to UpgradeManager
	if UpgradeManager:
		UpgradeManager.add_fragments(fragments_earned_this_run)
		UpgradeManager.record_run_end(wave, max_combo, phantoms_defeated_this_run)

	# Show BIG CENTRAL GAME OVER POPUP
	show_game_over_popup()

func show_game_over_popup():
	# Create a BIG CENTRAL POPUP for game over
	var popup = Control.new()
	popup.name = "GameOverPopup"
	popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup.mouse_filter = Control.MOUSE_FILTER_STOP
	popup.z_index = 100  # Make sure it's on top!

	# Dark overlay background
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.9)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup.add_child(overlay)

	# Center container
	var center = VBoxContainer.new()
	center.set_anchors_preset(Control.PRESET_CENTER)
	center.offset_left = -450
	center.offset_top = -250
	center.offset_right = 450
	center.offset_bottom = 250
	center.add_theme_constant_override("separation", 25)

	# Title
	var title = Label.new()
	title.text = format_ui("DREAM COLLAPSED")
	title.add_theme_font_override("font", monogram_font)
	title.add_theme_font_size_override("font_size", 80)
	title.add_theme_color_override("font_color", Color(2.0, 0.5, 0.5))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(title)

	# Motivational message
	var motivator = get_motivational_message()
	var motivator_label = Label.new()
	motivator_label.text = motivator
	motivator_label.add_theme_font_override("font", monogram_font)
	motivator_label.add_theme_font_size_override("font_size", 36)
	motivator_label.add_theme_color_override("font_color", Color(1.5, 1.5, 1.5))
	motivator_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(motivator_label)

	# Stats
	var stats = Label.new()
	stats.text = format_ui("wave reached: %d\nfragments earned: %d\nscore: %d\nbest combo: x%d" % [wave, fragments_earned_this_run, score, max_combo])
	stats.add_theme_font_override("font", monogram_font)
	stats.add_theme_font_size_override("font_size", 28)
	stats.add_theme_color_override("font_color", Color(1.2, 1.2, 1.2))
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(stats)

	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	center.add_child(spacer)

	# Options
	var options = Label.new()
	options.text = format_ui("[R] RESTART        [U] UPGRADES")
	options.add_theme_font_override("font", monogram_font)
	options.add_theme_font_size_override("font_size", 32)
	options.add_theme_color_override("font_color", Color(2.0, 2.0, 2.0))
	options.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(options)

	# Blink animation for options
	# Start a safe coroutine-based blink (avoid set_loops to prevent engine infinite-loop detection)
	_start_blink(options, 0.5, 0.8, 1.0, 0.8)

	popup.add_child(center)
	$UILayer.add_child(popup)

	# Animate popup entrance
	popup.modulate.a = 0.0
	var entrance_tween = create_tween()
	entrance_tween.tween_property(popup, "modulate:a", 1.0, 0.5)

func get_motivational_message() -> String:
	var messages = []

	if UpgradeManager:
		# close call messages
		if wave >= UpgradeManager.highest_wave - 1 and wave > 1:
			messages.append("almost beat your record!")
		elif wave == UpgradeManager.highest_wave:
			messages.append("tied your best wave!")
		elif wave > UpgradeManager.highest_wave:
			messages.append("new wave record!")

		# combo messages
		if max_combo >= UpgradeManager.highest_combo - 3 and max_combo > 5:
			messages.append("impressive combo!")
		elif max_combo > UpgradeManager.highest_combo:
			messages.append("best combo yet!")

	# fragment messages
	if fragments_earned_this_run > 20:
		messages.append("abundant harvest!")
	elif fragments_earned_this_run > 10:
		messages.append("good haul!")

	# default messages
	if messages.is_empty():
		messages = [
			"try again?",
			"the dream fades...",
			"almost had it...",
			"one more try?",
			"so close...",
		]

	return messages.pick_random()

func _input(event):
	# Only handle restart/upgrade keys when game is over
	if game_over and event is InputEventKey and event.pressed and not event.is_echo():
		print("[_input] game_over=true, key pressed:", event.keycode)
		if event.keycode == KEY_R:
			# instant restart
			print("[_input] restarting game!")
			SoundManager.play_dealt()
			get_tree().reload_current_scene()
		elif event.keycode == KEY_U:
			# go to upgrade shop
			print("[_input] going to upgrade shop!")
			SoundManager.play_dealt()
			get_tree().change_scene_to_file("res://scenes/upgrade_shop.tscn")

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


# Helper to start a safe blink animation without using Tween.set_loops()
func _start_blink(target: Node, a1: float, dur1: float, a2: float, dur2: float) -> void:
	# Use call_deferred so this function can be invoked from _ready/_enter_tree without order issues
	call_deferred("_blink_loop", target, a1, dur1, a2, dur2)


func _blink_loop(target: Node, a1: float, dur1: float, a2: float, dur2: float) -> void:
	# Keep blinking while the target is valid and in the scene tree
	if target == null:
		return
	while is_instance_valid(target) and target.get_parent() != null:
		# Fade to a1 then to a2
		var tween = create_tween()
		tween.tween_property(target, "modulate:a", a1, dur1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(target, "modulate:a", a2, dur2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await tween.finished
		# Small pause to avoid hogging the main loop
		await get_tree().process_frame
