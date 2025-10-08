# protagonist.gd
extends Node2D

@onready var body_label = $Body
@onready var shield_label = $Shield
@onready var attack_anim = $AttackAnim
@onready var pulse_label = $AttackAnim/Pulse

var blink_timer: float = 0.0
var blink_interval: float = 0.5
var blink_visible: bool = true
var is_attacking = false
var has_shield = false

func _ready():
	position = Vector2(480, 270)  # Center of 960x540
	body_label.text = "~"

func _process(delta):
	# Blinking cursor animation
	blink_timer += delta
	if blink_timer >= blink_interval:
		blink_timer = 0.0
		blink_visible = !blink_visible
		body_label.visible = blink_visible

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
	
	# Flash attack symbol
	pulse_label.modulate.a = 1.0
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(pulse_label, "scale", Vector2(2.0, 2.0), 0.2)
	tween.tween_property(pulse_label, "modulate:a", 0.0, 0.2)
	
	await tween.finished
	pulse_label.scale = Vector2.ONE
	is_attacking = false

func face_direction(_target_pos: Vector2):
	# Brief flash when attacking
	body_label.modulate = Color.BLACK
	body_label.visible = true
	await get_tree().create_timer(0.05).timeout
	body_label.modulate = Color.WHITE

func take_damage():
	# Flash animation
	var tween = create_tween()
	tween.tween_property(body_label, "modulate:a", 0.3, 0.1)
	tween.tween_property(body_label, "modulate:a", 1.0, 0.1)
