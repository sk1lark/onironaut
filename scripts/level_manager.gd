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
	},
	6: {
		"name": "the glass labyrinth",
		"description": "precision under pressure",
		"spawn_rate": 1.3,
		"phantom_speed_multiplier": 2.2,
		"background_hum": "tense"
	},
	7: {
		"name": "the signal sea",
		"description": "signals within noise",
		"spawn_rate": 1.15,
		"phantom_speed_multiplier": 2.4,
		"background_hum": "static"
	},
	8: {
		"name": "the recursion spiral",
		"description": "depths loop back",
		"spawn_rate": 1.0,
		"phantom_speed_multiplier": 2.6,
		"background_hum": "spiral"
	},
	9: {
		"name": "the boundary",
		"description": "edge of lucidity",
		"spawn_rate": 0.9,
		"phantom_speed_multiplier": 2.8,
		"background_hum": "hiss"
	},
	10: {
		"name": "the singular room",
		"description": "one last breath",
		"spawn_rate": 0.8,
		"phantom_speed_multiplier": 3.0,
		"background_hum": "void"
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
		5: 35,
		6: 40,
		7: 45,
		8: 50,
		9: 60,
		10: 9999
	}

	return phantoms_resolved >= required_phantoms.get(current_level, 999)
