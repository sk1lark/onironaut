# power_up_data.gd
extends Resource
class_name PowerUpData

@export var power_type: String = "shield"  # shield, slow, rapid, clear
@export var symbol: String = "()"
@export var duration: float = 5.0
@export var spawn_chance: float = 0.2
