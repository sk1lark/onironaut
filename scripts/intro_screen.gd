extends Control

@onready var prompt_label = $PromptLabel

var blink_timer: float = 0.0
var blink_interval: float = 0.5

func _ready():
	pass

func _process(delta):
	# Blink the prompt text
	blink_timer += delta
	if blink_timer >= blink_interval:
		blink_timer = 0.0
		if prompt_label:
			prompt_label.visible = !prompt_label.visible

func _input(event):
	if event is InputEventKey and event.pressed:
		# Go to upgrade shop
		get_tree().change_scene_to_file("res://scenes/upgrade_shop.tscn")
	elif event is InputEventMouseButton and event.pressed:
		# Also accept mouse clicks
		get_tree().change_scene_to_file("res://scenes/upgrade_shop.tscn")
