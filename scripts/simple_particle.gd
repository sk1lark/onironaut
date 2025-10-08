# simple_particle.gd
extends Node2D

var particles: Array = []
var max_life: float = 1.0

func _ready():
	if has_meta("particles"):
		particles = get_meta("particles")

func _process(delta):
	var all_dead = true
	
	for particle in particles:
		if particle["life"] > 0:
			all_dead = false
			particle["pos"] += particle["vel"] * delta
			particle["vel"] *= 0.95  # friction
			particle["life"] -= delta
	
	queue_redraw()
	
	if all_dead:
		queue_free()

func _draw():
	for particle in particles:
		if particle["life"] > 0:
			var alpha = particle["life"] / max_life
			var color = Color(1, 1, 1, alpha)
			var size = 2.0 + (alpha * 2.0)
			draw_circle(particle["pos"], size, color)
