# level_map.gd
extends Control

@onready var map_container = $Content/MapContainer
@onready var level_info = $Content/LevelInfo
@onready var continue_label = $Content/ContinueLabel
@onready var monogram = preload("res://fonts/monogram-extended.ttf")

var current_level: int = 1
var level_manager

signal map_dismissed

func _ready():
	# Play menu music during map view (pauses gameplay)
	SoundManager.stop_background_music()
	SoundManager.start_menu_music()

	# Blink the continue prompt
	start_blink_animation()

	# Auto-dismiss the map after a timeout in case input isn't received
	var auto_timer = get_tree().create_timer(8.0)
	var _cb_auto_dismiss = func():
		_dismiss_and_resume()
	auto_timer.timeout.connect(_cb_auto_dismiss)

	# Debug: confirm this script was loaded by the engine
	print("[level_map.gd] _ready() loaded - map_container=" , map_container)

func setup(level: int, lm):
	current_level = level
	level_manager = lm
	generate_ascii_map()
	update_level_info()

func generate_ascii_map():
	# Create a fantasy-style map with locations
	var map_lines = []

	# Map border top
	map_lines.append("╔══════════════════════════════════════════════════════════════╗")
	map_lines.append("║                                                              ║")

	# Level positions arranged like a real map
	var level_positions = {
		1: {"x": 8, "y": 2, "name": "Surface"},
		2: {"x": 25, "y": 4, "name": "Archives"},
		3: {"x": 12, "y": 6, "name": "Logic Engine"},
		4: {"x": 35, "y": 7, "name": "Syntax"},
		5: {"x": 20, "y": 9, "name": "The Ego"},
		6: {"x": 40, "y": 10, "name": "Labyrinth"},
		7: {"x": 15, "y": 12, "name": "Signal Sea"},
		8: {"x": 30, "y": 13, "name": "Recursion"},
		9: {"x": 10, "y": 15, "name": "Boundary"},
		10: {"x": 25, "y": 16, "name": "Singular"}
	}

	# Create empty map grid (18 rows, 62 chars wide)
	for i in range(18):
		map_lines.append("║" + " ".repeat(62) + "║")

	# Place locations on map
	for level in range(1, 11):
		var pos = level_positions[level]
		var y = pos["y"]
		var x = pos["x"]
		var location_name = pos["name"]  # Renamed to avoid shadowing Node.name

		var marker = ""
		if level < current_level:
			marker = "[✓%d]" % level  # Completed
		elif level == current_level:
			marker = "►[%d]◄" % level  # Current
		else:
			marker = "[?]"  # Unknown

		# Draw location marker
		var line = map_lines[y]
		line = line.substr(0, x + 1) + marker + line.substr(x + 1 + marker.length())
		map_lines[y] = line

		# Draw location name below marker
		if level <= current_level:
			var name_line = map_lines[y + 1]
			name_line = name_line.substr(0, x + 1) + location_name + name_line.substr(x + 1 + location_name.length())
			map_lines[y + 1] = name_line

	# Draw paths between locations
	for level in range(1, 10):
		var from_pos = level_positions[level]
		var to_pos = level_positions[level + 1]

		if level < current_level:
			# Draw line between completed levels
			var from_y = from_pos["y"]
			var to_y = to_pos["y"]
			var from_x = from_pos["x"] + 2
			var to_x = to_pos["x"] + 2

			# Simple vertical/diagonal connectors
			for y in range(from_y + 2, to_y):
				var line = map_lines[y]
				var draw_x = from_x + int((to_x - from_x) * float(y - from_y - 2) / float(to_y - from_y - 2))
				if draw_x >= 1 and draw_x < 61:
					line = line.substr(0, draw_x + 1) + "·" + line.substr(draw_x + 2)
					map_lines[y] = line

	map_lines.append("║                                                              ║")
	map_lines.append("╚══════════════════════════════════════════════════════════════╝")

	# Ensure the label is configured for ASCII map display
	if map_container:
		# Ensure font and properties
		map_container.add_theme_font_override("font", monogram)
		# Use project constants for alignment and correct autowrap property
		map_container.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		map_container.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		# Label will display explicit newlines; avoid forcing autowrap here to prevent API mismatch
		# Assign the assembled ASCII map
		map_container.text = "\n".join(map_lines)

func update_level_info():
	var level_info_data = level_manager.get_level_info(current_level)
	var level_name = level_info_data.get("name", "unknown")
	var level_desc = level_info_data.get("description", "")

	# Use lowercase UI
	var formatted_text = "level %d: %s\n%s" % [current_level, level_name.to_lower(), level_desc.to_lower()]
	level_info.text = formatted_text.to_lower()

func start_blink_animation():
	var tween = create_tween()
	tween.set_loops(-1)
	tween.tween_property(continue_label, "modulate:a", 0.3, 0.8)
	tween.tween_property(continue_label, "modulate:a", 1.0, 0.8)

func _dismiss_and_resume():
	# Resume gameplay music when leaving map
	SoundManager.stop_menu_music()
	SoundManager.start_background_music()
	map_dismissed.emit()
	queue_free()

func _input(event):
	# Accept both keypress and mouse click so players using mouse can dismiss
	if event is InputEventKey and event.pressed:
		accept_event()
		SoundManager.play_dealt()
		_dismiss_and_resume()
	elif event is InputEventMouseButton and event.pressed:
		accept_event()
		SoundManager.play_dealt()
		_dismiss_and_resume()
