# cutscene.gd
# Displays a cutscene with an image and typewriter dialogue text
extends Control

signal cutscene_finished

@onready var image_rect: TextureRect = $ImageRect
@onready var dialogue_label: Label = $DialogueBox/MarginContainer/DialogueLabel
@onready var prompt_label: Label = $DialogueBox/PromptLabel
@onready var background: ColorRect = $Background

# Cutscene data
var cutscene_image: Texture2D
var dialogue_lines: Array = []
var current_line_index: int = 0
var typing_speed: float = 0.05  # seconds per character
var is_typing: bool = false
var current_text: String = ""
var text_index: int = 0

# Typewriter effect timer
var type_timer: float = 0.0

# Fonts
var monogram_font: FontFile

func _ready():
	# Load monogram font
	monogram_font = load("res://fonts/monogram-extended.ttf")

	# Setup UI
	setup_ui()


	# Hide prompt initially
	if prompt_label:
		prompt_label.visible = false

	# Start showing the first line
	if dialogue_lines.size() > 0:
		start_typing_line(dialogue_lines[0])

func setup_ui():
	# Setup background (black)
	if background:
		background.color = Color.BLACK

	# Setup image rect (fullscreen)
	if image_rect and cutscene_image:
		image_rect.texture = cutscene_image
		image_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		image_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	# Setup dialogue label (no box, just text in bottom 1/4)
	if dialogue_label:
		dialogue_label.add_theme_font_override("font", monogram_font)
		dialogue_label.add_theme_font_size_override("font_size", 48)
		dialogue_label.add_theme_color_override("font_color", Color.WHITE)
		dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		dialogue_label.text = ""

	# Setup prompt label (continue indicator)
	if prompt_label:
		prompt_label.add_theme_font_override("font", monogram_font)
		prompt_label.add_theme_font_size_override("font_size", 28)
		prompt_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		prompt_label.text = "[press any key to continue]"
		prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		# Start blinking animation
		start_prompt_blink()

func setup(image: Texture2D, lines: Array):
	"""Call this before adding to scene tree to configure the cutscene"""
	cutscene_image = image
	dialogue_lines = lines
	current_line_index = 0

	# Debug: log setup
	print("[cutscene] setup: lines=", dialogue_lines.size(), " image=", image)

func start_typing_line(line: String):
	# Guard: ensure current_line_index is valid and we aren't already typing the same text
	if current_line_index < 0 or current_line_index >= dialogue_lines.size():
		print("[cutscene] start_typing_line: invalid current_line_index=", current_line_index)
		return
	if is_typing and current_text == line:
		# Already typing this line — ignore
		return

	is_typing = true
	current_text = line
	text_index = 0
	type_timer = 0.0
	if dialogue_label:
		dialogue_label.text = ""
	if prompt_label:
		prompt_label.visible = false

	# Debug
	print("[cutscene] start_typing_line index=", current_line_index, " text='", current_text, "'")

func _process(delta):
	if is_typing:
		type_timer += delta

		# Type one character at a time
		if type_timer >= typing_speed:
			type_timer = 0.0

			if text_index < current_text.length():
				if dialogue_label:
					dialogue_label.text = current_text.substr(0, text_index + 1)
				text_index += 1

				# Play type sound (disabled during cutscenes)
				# SoundManager.play_type()
			else:
				# Finished typing this line
				is_typing = false
				if prompt_label:
					prompt_label.visible = true
					print("[cutscene] finished typing line index=", current_line_index)

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.is_echo():
		print("[cutscene] _unhandled_input received key; is_typing=", is_typing, " current_line_index=", current_line_index)
		if is_typing:
			# Skip typing animation - show full text immediately
			is_typing = false
			text_index = current_text.length()
			if dialogue_label:
				dialogue_label.text = current_text
			if prompt_label:
				prompt_label.visible = true
				# SoundManager.play_dealt()
		else:
			# Move to next line or finish cutscene
			print("[cutscene] advance_dialogue called from input; current_line_index=", current_line_index)
			advance_dialogue()

func advance_dialogue():
	# Debug
	print("[cutscene] advance_dialogue (before) current_line_index=", current_line_index)
	current_line_index += 1
	print("[cutscene] advance_dialogue (after) current_line_index=", current_line_index)

	if current_line_index < dialogue_lines.size():
		# Show next line
		# SoundManager.play_dealt()
		print("[cutscene] starting next line: index=", current_line_index)
		start_typing_line(dialogue_lines[current_line_index])
	else:
		# Cutscene finished
		print("[cutscene] dialogue finished, emitting cutscene_finished")
		finish_cutscene()

func finish_cutscene():
	# Signal that this cutscene finished showing its dialogue.
	# Do NOT free immediately — caller will free after any transitions to avoid a blank frame.
	emit_signal("cutscene_finished")
	# Hide and stop processing/input until the parent decides to free this node.
	visible = false
	set_process(false)
	set_process_unhandled_input(false)

func start_prompt_blink():
	if not prompt_label:
		return

	var blink_tween = create_tween()
	blink_tween.set_loops(-1)
	blink_tween.tween_property(prompt_label, "modulate:a", 0.3, 0.6)
	blink_tween.tween_property(prompt_label, "modulate:a", 1.0, 0.6)
