# particle_burst.gd
extends Node2D

var particles: Array[Vector2] = []
var velocities: Array[Vector2] = []
var lifetimes: Array[float] = []
var max_lifetime: float = 0.8

func _ready():
	# Create particle burst
	for i in range(12):
		var angle = (TAU / 12.0) * i + randf() * 0.3
		var speed = randf_range(80.0, 150.0)
		
		particles.append(Vector2.ZERO)
		velocities.append(Vector2(cos(angle), sin(angle)) * speed)
		lifetimes.append(max_lifetime)
	
	# Auto-delete after animation
	await get_tree().create_timer(max_lifetime).timeout
	queue_free()

func _process(delta):
	queue_redraw()
	
	# Update particles
	for i in range(particles.size()):
		if lifetimes[i] > 0:
			particles[i] += velocities[i] * delta
			velocities[i] *= 0.95  # Drag
			lifetimes[i] -= delta

func _draw():
	# Draw particles as simple pixels
	for i in range(particles.size()):
		if lifetimes[i] > 0:
			var alpha = lifetimes[i] / max_lifetime
			var size = 2.0 + (1.0 - alpha) * 3.0
			draw_circle(particles[i], size, Color(1, 1, 1, alpha))
