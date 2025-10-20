extends Control

# TypingMinigame: minimal typing minigame control for roguelike encounters.
# Usage:
# - call `start(target_text, time_limit, difficulty)` to begin
# - it emits `minigame_result` with {"success":bool, "time":float}

signal minigame_result(result: Dictionary)

@onready var prompt_label: Label = $PromptLabel
@onready var input_label: Label = $InputLabel

var target_text: String = ""
var typed_text: String = ""
var start_time: float = 0.0
var time_limit: float = 8.0
var running: bool = false
var difficulty: int = 1

func _ready():
	if prompt_label:
		prompt_label.visible = false
	if input_label:
		input_label.text = ""

func start(target: String, new_time_limit: float = 8.0, new_difficulty: int = 1):
	target_text = target
	time_limit = new_time_limit
	difficulty = new_difficulty
	typed_text = ""
	running = true
	start_time = Time.get_ticks_msec() / 1000.0
	if prompt_label:
		prompt_label.text = target_text
		prompt_label.visible = true
	if input_label:
		input_label.text = ""

func _unhandled_input(event):
	if not running:
		return
	if event is InputEventKey and event.pressed and not event.is_echo():
		# Handle backspace
		if event.scancode == KEY_BACKSPACE:
			if typed_text.length() > 0:
				typed_text = typed_text.substr(0, typed_text.length() - 1)
				input_label.text = typed_text
				return
		# Use event.unicode for a reliable character from the key event
		var uni = event.unicode
		if uni == 0:
			return
		var ch = char(uni)
		# Append and check progress
		typed_text += ch
		if input_label:
			input_label.text = typed_text
		_check_progress()

func _process(delta):
	if not running:
		return
	# Check timeout
	var elapsed = (Time.get_ticks_msec() / 1000.0) - start_time
	if elapsed >= time_limit:
		running = false
		emit_signal("minigame_result", {"success": false, "time": elapsed})

func _check_progress():
	# naive match: check prefix
	if typed_text == target_text:
		running = false
		var elapsed = (Time.get_ticks_msec() / 1000.0) - start_time
		emit_signal("minigame_result", {"success": true, "time": elapsed})

func reset():
	target_text = ""
	typed_text = ""
	running = false
	if input_label:
		input_label.text = ""
	if prompt_label:
		prompt_label.visible = false
