# gate_indicator.gd
extends Node2D

@onready var label = $Label

var gate_name: String = ""
var threat_level: int = 0

func _ready():
	update_display()

func set_gate_name(gname: String):
	gate_name = gname
	update_display()

func set_threat_level(level: int):
	threat_level = level
	update_display()

func update_display():
	if not label:
		return
	
	var symbols = {
		"north": "▲",
		"south": "▼",
		"east": "▶",
		"west": "◀"
	}
	
	var symbol = symbols.get(gate_name, "■")
	
	if threat_level == 0:
		label.text = symbol
		label.modulate = Color(0.5, 0.5, 0.5, 0.5)
	elif threat_level <= 2:
		label.text = symbol
		label.modulate = Color(1.0, 1.0, 0.0, 1.0)  # Yellow
	else:
		label.text = symbol
		label.modulate = Color(1.0, 0.0, 0.0, 1.0)  # Red
