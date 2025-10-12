# protagonist.gd
extends Node2D

@onready var body_sprite = $Body
@onready var shield_label = $Shield
@onready var attack_anim = $AttackAnim
@onready var pulse_label = $AttackAnim/Pulse

var is_attacking = false
var has_shield = false
var shield_rotation_speed: float = 2.0

# Animation variables
var idle_time: float = 0.0
var bob_amplitude: float = 8.0
var bob_speed: float = 2.0
var pulse_amplitude: float = 0.15
var pulse_speed: float = 1.5
var base_position: Vector2 = Vector2.ZERO

func _ready():
	# Center-origin world: (0,0) is screen center
	position = Vector2.ZERO
	base_position = position
	# Scale is set via scene; leave as-is to respect scene scaling
	body_sprite.visible = true
	body_sprite.modulate = Color.WHITE

	# Start idle animations
	start_idle_animations()

func _process(delta):
	# Update idle animation
	idle_time += delta

	# Floating bob motion (up and down)
	var bob_offset = sin(idle_time * bob_speed) * bob_amplitude
	position.y = base_position.y + bob_offset

	# Subtle scale pulse (breathing effect)
	var pulse_scale = 1.0 + sin(idle_time * pulse_speed) * pulse_amplitude
	body_sprite.scale = Vector2(pulse_scale, pulse_scale)

	# Rotate shield if active
	if has_shield:
		shield_label.rotation += shield_rotation_speed * delta

func start_idle_animations():
	# Add a subtle rotation wobble using a tween
	var wobble_tween = create_tween()
	wobble_tween.set_loops()
	wobble_tween.tween_property(body_sprite, "rotation", -0.1, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	wobble_tween.tween_property(body_sprite, "rotation", 0.1, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func set_combo_level(_level: int):
	# Protagonist stays as ~ regardless of combo
	pass

func activate_shield(duration: float = 5.0):
	has_shield = true
	shield_label.visible = true
	await get_tree().create_timer(duration).timeout
	has_shield = false
	shield_label.visible = false

func attack_pulse():
	if is_attacking:
		return

	is_attacking = true

	# Flash attack symbol with bright glow
	pulse_label.modulate = Color(1.5, 1.5, 2.0, 1.0)  # Bright blue-white glow
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(pulse_label, "scale", Vector2(2.5, 2.5), 0.2)
	tween.tween_property(pulse_label, "modulate:a", 0.0, 0.2)

	# Add a brief scale boost to the player sprite
	var body_tween = create_tween()
	body_tween.set_parallel(true)
	body_tween.tween_property(body_sprite, "modulate", Color(1.3, 1.3, 1.5, 1.0), 0.05)
	body_tween.tween_property(body_sprite, "modulate", Color.WHITE, 0.15).set_delay(0.05)

	await tween.finished
	pulse_label.scale = Vector2.ONE
	is_attacking = false

func face_direction(_target_pos: Vector2):
	# Brief flash when attacking
	body_sprite.modulate = Color.BLACK
	body_sprite.visible = true
	await get_tree().create_timer(0.05).timeout
	body_sprite.modulate = Color.WHITE

func take_damage():
	# Flash animation
	var tween = create_tween()
	tween.tween_property(body_sprite, "modulate:a", 0.3, 0.1)
	tween.tween_property(body_sprite, "modulate:a", 1.0, 0.1)
