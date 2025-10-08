# power_up.gd
extends Node2D

@onready var label = $Label
@onready var collect_timer = $CollectTimer

var power_data: Resource
var lifetime: float = 0.0
var move_speed: float = 30.0

func _ready():
	collect_timer.timeout.connect(_on_timeout)
	
func setup(data: Resource, spawn_pos: Vector2):
	power_data = data
	label.text = data.symbol
	position = spawn_pos
	
	# Pulse animation
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.5)
	tween.tween_property(self, "scale", Vector2.ONE, 0.5)

func _process(delta):
	lifetime += delta
	# Float toward center slowly
	var center = Vector2(480, 270)
	var direction = (center - position).normalized()
	position += direction * move_speed * delta
	
	# Check if close enough to collect
	if position.distance_to(center) < 40.0:
		collect()

func collect():
	queue_free()

func _on_timeout():
	# Fade out and disappear
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	await tween.finished
	queue_free()
