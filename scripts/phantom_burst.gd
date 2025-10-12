# phantom_burst.gd - creates a burst effect when phantom is destroyed
extends Node2D

var particles: Array = []
var lifetime: float = 0.6
var elapsed: float = 0.0

func _ready():
	# create particle burst
	for i in range(12):
		var angle = (PI * 2.0 / 12) * i
		var particle = {
			"pos": Vector2.ZERO,
			"vel": Vector2(cos(angle), sin(angle)) * randf_range(100, 200),
			"size": randf_range(2, 6),
			"rotation": randf() * PI * 2,
			"rot_speed": randf_range(-8, 8),
		}
		particles.append(particle)

func _process(delta):
	elapsed += delta

	if elapsed >= lifetime:
		queue_free()
		return

	# update particles
	for particle in particles:
		particle["pos"] += particle["vel"] * delta
		particle["vel"] *= 0.95  # friction
		particle["rotation"] += particle["rot_speed"] * delta

	queue_redraw()

func _draw():
	var alpha = 1.0 - (elapsed / lifetime)

	for particle in particles:
		var color = Color(1.0, 1.0, 1.0, alpha)
		var size = particle["size"] * (1.0 - elapsed / lifetime)

		# draw particle as small square
		draw_rect(
			Rect2(particle["pos"] - Vector2(size, size) * 0.5, Vector2(size, size)),
			color
		)
