# image_splash.gd
extends Control

@onready var splash_image = $SplashImage

var timer: float = 3.0
var can_skip: bool = false

func _ready():
	# load the splash image
	var texture = load("res://images/the onironaut.png")
	if texture:
		splash_image.texture = texture
		print("Splash image loaded successfully")
	else:
		print("ERROR: Could not load splash image")

	# allow skipping after a brief delay
	await get_tree().create_timer(0.3).timeout
	can_skip = true

func _process(delta):
	timer -= delta
	if timer <= 0:
		go_to_next_scene()

func _input(event):
	if can_skip and event is InputEventMouseButton and event.pressed:
		go_to_next_scene()

var transitioning: bool = false

func go_to_next_scene():
	if transitioning:
		return
	transitioning = true
	get_tree().change_scene_to_file("res://scenes/splash_screen.tscn")
