# phantom.gd
extends Node2D
class_name Phantom

@onready var art_label = $ArtLabel
@onready var text_label = $TextLabel
@onready var animation_player = $AnimationPlayer

var phantom_data: PhantomData
var move_speed: float = 50.0
var is_focused: bool = false
var typed_progress: int = 0
var original_modulate: Color

var target_position: Vector2 = Vector2.ZERO  # Center-origin default target

# attack system - only when player is idle
var attack_timer: float = 0.0
var attack_interval: float = 0.0  # Set when spawned
var can_attack: bool = false  # Controlled by main script based on idle time

signal phantom_completed(phantom: Phantom)
signal phantom_attacks(phantom: Phantom)

func _ready():
	original_modulate = modulate
	setup_fade_in_animation()
	
	# Apply phantom data if it was set before _ready
	if phantom_data:
		apply_phantom_data()

func setup_phantom(data: PhantomData):
	phantom_data = data
	# Enforce a reasonable minimum speed so phantoms don't appear frozen if resource speed is low
	move_speed = max(data.base_speed, 40.0) * 2.2
	
	# If we're already in the tree, apply data immediately
	if is_node_ready():
		apply_phantom_data()

func apply_phantom_data():
	if not phantom_data:
		return
		
	art_label.text = phantom_data.art
	text_label.text = phantom_data.text_to_type

	# Start faded out
	modulate = Color.TRANSPARENT
	animation_player.play("fade_in")

	# Ensure initial layout is correct (ASCII directly above text)
	layout_labels(0.0)

func _process(delta):
	var time = Time.get_ticks_msec() * 0.001

	# Move towards target position (don't skip when target is Vector2.ZERO)
	var to_target: Vector2 = target_position - position
	var dist = to_target.length()
	if dist > 0.5:
		position += to_target.normalized() * move_speed * delta
	
	# Attack system - phantoms occasionally shoot static at player
	if can_attack and attack_interval > 0.0:
		attack_timer += delta
		if attack_timer >= attack_interval:
			attack_timer = 0.0
			attack_interval = randf_range(3.0, 6.0)  # Next attack in 3-6 seconds
			shoot_static_at_player()
	
	# subtle floating on labels; keep ASCII directly above text at all times
	var float_offset = sin(time + position.x * 0.01) * 2.0
	layout_labels(float_offset)
	
	# add subtle rotation when focused
	if is_focused:
		rotation = sin(time * 3.0) * 0.05
		# pulse scale slightly
		var pulse = 1.1 + sin(time * 4.0) * 0.02
		scale = Vector2(pulse, pulse)
	else:
		# slight tilt based on position for more organic feel
		rotation = sin(position.x * 0.01) * 0.02

func set_focused(focused: bool):
	is_focused = focused

	if focused:
		# stark white for focused phantom
		modulate = Color(1.0, 1.0, 1.0, 1.0)
		# Keep ASCII readable but secondary; give text a stronger glow (outline)
		art_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1.0))
		art_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
		art_label.add_theme_constant_override("outline_size", 1)
		text_label.add_theme_color_override("default_color", Color(1.0, 1.0, 1.0, 1.0))
		text_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
		text_label.add_theme_constant_override("outline_size", 2)
		# make it larger
		scale = Vector2(1.1, 1.1)
	else:
		# dim unfocused phantoms but keep legible
		modulate = Color(1.0, 1.0, 1.0, 0.85)
		art_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1.0))
		art_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
		art_label.add_theme_constant_override("outline_size", 1)
		text_label.add_theme_color_override("default_color", Color(1.0, 1.0, 1.0, 1.0))
		text_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
		text_label.add_theme_constant_override("outline_size", 2)
		scale = Vector2(1.0, 1.0)

		# IMPORTANT: Reset text highlighting when unfocused
		typed_progress = 0
		text_label.text = phantom_data.text_to_type
		layout_labels(0.0)

func update_typing_progress(current_text: String):
	typed_progress = current_text.length()

	# Update text display to show progress - use inverse for typed chars
	if typed_progress > 0:
		var completed_part = phantom_data.text_to_type.substr(0, typed_progress)
		var remaining_part = phantom_data.text_to_type.substr(typed_progress)
		# Inverse colors for typed text (black background effect)
		text_label.text = "[bgcolor=white][color=black]" + completed_part + "[/color][/bgcolor]" + remaining_part
	else:
		text_label.text = phantom_data.text_to_type

	# Relayout after text width/height potentially changed
	layout_labels(0.0)

func complete_phantom():
	phantom_completed.emit(self)
	
	# explosive exit - scale up and fade
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(2.0, 2.0), 0.3)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_property(self, "rotation", randf_range(-PI, PI), 0.3)
	tween.finished.connect(queue_free)

func setup_fade_in_animation():
	# Create or get the default animation library
	var anim_library: AnimationLibrary
	if not animation_player.has_animation_library(""):
		anim_library = AnimationLibrary.new()
		animation_player.add_animation_library("", anim_library)
	else:
		anim_library = animation_player.get_animation_library("")
	
	# Create fade-in animation
	if not animation_player.has_animation("fade_in"):
		var animation = Animation.new()
		animation.length = 0.5

		# Add modulate track
		var track_index = animation.add_track(Animation.TYPE_VALUE)
		animation.track_set_path(track_index, ".:modulate")
		animation.track_insert_key(track_index, 0.0, Color.TRANSPARENT)
		animation.track_insert_key(track_index, 0.5, original_modulate)

		anim_library.add_animation("fade_in", animation)

	# Create resolve animation
	if not animation_player.has_animation("resolve_animation"):
		var animation = Animation.new()
		animation.length = 1.0

		# Add glow and fade effect
		var track_index = animation.add_track(Animation.TYPE_VALUE)
		animation.track_set_path(track_index, ".:modulate")
		animation.track_insert_key(track_index, 0.0, Color.WHITE)
		animation.track_insert_key(track_index, 0.5, Color(2.0, 2.0, 2.0, 1.0))
		animation.track_insert_key(track_index, 1.0, Color.TRANSPARENT)

		# Add scale effect
		var scale_track = animation.add_track(Animation.TYPE_VALUE)
		animation.track_set_path(scale_track, ".:scale")
		animation.track_insert_key(scale_track, 0.0, Vector2.ONE)
		animation.track_insert_key(scale_track, 0.5, Vector2(1.2, 1.2))
		animation.track_insert_key(scale_track, 1.0, Vector2(0.8, 0.8))

		anim_library.add_animation("resolve_animation", animation)
	
	# Connect animation finished signal
	if not animation_player.animation_finished.is_connected(_on_animation_finished):
		animation_player.animation_finished.connect(_on_animation_finished)

func _on_animation_finished(anim_name: StringName):
	if anim_name == "resolve_animation":
		queue_free()

func shoot_static_at_player():
	# Emit signal that this phantom is attacking
	phantom_attacks.emit(self)

func layout_labels(offset_y: float = 0.0):
	# Center both labels horizontally and place ASCII (art_label) directly above the typing text (text_label)
	# Use their computed content sizes to avoid overlap regardless of text length.
	var gap := 4.0

	# RichTextLabel provides content dimensions
	var text_w := 0.0
	var text_h := 0.0
	if text_label and is_instance_valid(text_label):
		if text_label.has_method("get_content_width"):
			text_w = float(text_label.get_content_width())
		else:
			text_w = float(text_label.size.x)
		if text_label.has_method("get_content_height"):
			text_h = float(text_label.get_content_height())
		else:
			text_h = float(text_label.size.y)
		text_w = max(text_w, 1.0)
		text_h = max(text_h, 1.0)
		text_label.size = Vector2(text_w, text_h)
		text_label.position = Vector2(-text_w * 0.5, 0.0 + offset_y)

	# Label minimum size for ASCII art (may be multiline)
	if art_label and is_instance_valid(art_label):
		var art_ms = art_label.get_minimum_size() as Vector2
		var art_w: float = max(art_ms.x, 1.0)
		var art_h: float = max(art_ms.y, 1.0)
		art_label.size = Vector2(art_w, art_h)
		# Place bottom of art exactly gap pixels above top of text
		art_label.position = Vector2(-art_w * 0.5, -(gap + art_h) + offset_y)
