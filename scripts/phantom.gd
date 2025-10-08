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

# circular motion variables
var spawn_position: Vector2
var target_center: Vector2 = Vector2(640, 360)
var spiral_time: float = 0.0
var spiral_radius: float = 400.0
var spiral_speed: float = 0.3

# attack system - only when player is idle
var attack_timer: float = 0.0
var attack_interval: float = 0.0  # Set when spawned
var can_attack: bool = false  # Controlled by main script based on idle time

signal phantom_completed(phantom: Phantom)
signal phantom_attacks(phantom: Phantom)

func _ready():
	original_modulate = modulate
	setup_fade_in_animation()
	
	# store spawn position for spiral motion
	spawn_position = position
	
	# Apply phantom data if it was set before _ready
	if phantom_data:
		apply_phantom_data()

func setup_phantom(data: PhantomData):
	phantom_data = data
	move_speed = data.base_speed
	
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

func _process(delta):
	var time = Time.get_ticks_msec() * 0.001
	
	# circular closing-in motion - like impending thoughts
	spiral_time += delta * spiral_speed
	spiral_radius = max(50.0, spiral_radius - delta * 20.0)  # slowly close in
	
	# calculate spiral position
	var angle = spiral_time * 2.0  # rotate around center
	var offset = Vector2(
		cos(angle) * spiral_radius,
		sin(angle) * spiral_radius
	)
	
	# move toward center in spiral
	position = target_center + offset
	
	# Attack system - phantoms occasionally shoot static at player
	if can_attack and attack_interval > 0.0:
		attack_timer += delta
		if attack_timer >= attack_interval:
			attack_timer = 0.0
			attack_interval = randf_range(3.0, 6.0)  # Next attack in 3-6 seconds
			shoot_static_at_player()
	
	# subtle floating on labels
	var float_offset = sin(time + spawn_position.x * 0.01) * 3.0
	art_label.position.y = -60 + float_offset
	text_label.position.y = 30 + float_offset
	
	# add subtle rotation when focused
	if is_focused:
		rotation = sin(time * 3.0) * 0.05
		# pulse scale slightly
		var pulse = 1.1 + sin(time * 4.0) * 0.02
		scale = Vector2(pulse, pulse)
	else:
		# slight tilt based on angle for more organic feel
		rotation = sin(angle) * 0.02

func set_focused(focused: bool):
	is_focused = focused

	if focused:
		# stark white for focused phantom
		modulate = Color(1.0, 1.0, 1.0, 1.0)
		# inverse colors for high contrast
		art_label.add_theme_color_override("font_color", Color.BLACK)
		art_label.add_theme_color_override("font_outline_color", Color.WHITE)
		art_label.add_theme_constant_override("outline_size", 3)
		text_label.add_theme_color_override("font_color", Color.BLACK)
		text_label.add_theme_color_override("font_outline_color", Color.WHITE)
		text_label.add_theme_constant_override("outline_size", 3)
		# make it larger
		scale = Vector2(1.1, 1.1)
	else:
		# dim unfocused phantoms
		modulate = Color(1.0, 1.0, 1.0, 0.4)
		art_label.add_theme_color_override("font_color", Color.WHITE)
		art_label.add_theme_color_override("font_outline_color", Color.BLACK)
		art_label.add_theme_constant_override("outline_size", 0)
		text_label.add_theme_color_override("font_color", Color.WHITE)
		text_label.add_theme_color_override("font_outline_color", Color.BLACK)
		text_label.add_theme_constant_override("outline_size", 0)
		scale = Vector2(1.0, 1.0)

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
