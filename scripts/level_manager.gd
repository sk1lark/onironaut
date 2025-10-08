# level_manager.gd
extends Node
class_name LevelManager

var level_data = {
	1: {
		"name": "the surface dream",
		"description": "super slow and calm",
		"spawn_rate": 3.0,
		"phantom_speed_multiplier": 1.0,
		"background_hum": "calm"
	},
	2: {
		"name": "the archive of memory", 
		"description": "a little faster, a little sadder",
		"spawn_rate": 2.5,
		"phantom_speed_multiplier": 1.2,
		"background_hum": "nostalgic"
	},
	3: {
		"name": "the logic engine",
		"description": "fast, rhythmic, oppressive", 
		"spawn_rate": 2.0,
		"phantom_speed_multiplier": 1.5,
		"background_hum": "anxious"
	},
	4: {
		"name": "the abstract syntax",
		"description": "pure chaos, super fast",
		"spawn_rate": 1.5, 
		"phantom_speed_multiplier": 2.0,
		"background_hum": "chaotic"
	},
	5: {
		"name": "the ego",
		"description": "total silence",
		"spawn_rate": 999.0,
		"phantom_speed_multiplier": 0.0,
		"background_hum": "silence"
	}
}

func get_level_info(level: int) -> Dictionary:
	return level_data.get(level, {})

func should_advance_level(current_level: int, phantoms_resolved: int) -> bool:
	var required_phantoms = {
		1: 15,
		2: 20, 
		3: 25,
		4: 30,
		5: 1
	}

	return phantoms_resolved >= required_phantoms.get(current_level, 999)
