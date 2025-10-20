# upgrade_manager.gd
extends Node

## manages persistent upgrades and progression

# currency
var dream_fragments: int = 0

# upgrade levels (0 = not purchased)
var upgrades: Dictionary = {
	"max_health": 0,
	"starting_combo": 0,
	"rhythm_window": 0,
	"phantom_slowdown": 0,
	"fragment_multiplier": 0,
	"combo_duration": 0,
}

# upgrade costs (index = level, value = cost)
const UPGRADE_COSTS: Dictionary = {
	"max_health": [10, 25, 50, 100, 200],
	"starting_combo": [0, 15, 35],
	"rhythm_window": [20, 50, 100],
	"phantom_slowdown": [15, 40, 80, 150],
	"fragment_multiplier": [25, 60, 120],
	"combo_duration": [12, 30, 60],
}

# upgrade display info
const UPGRADE_INFO: Dictionary = {
	"max_health": {
		"name": "fortified mind",
		"desc": "+20 max health",
	},
	"starting_combo": {
		"name": "flow state",
		"desc": "start with +1 combo",
	},
	"rhythm_window": {
		"name": "rhythm sense",
		"desc": "wider on-beat window",
	},
	"phantom_slowdown": {
		"name": "time dilation",
		"desc": "phantoms -10% speed",
	},
	"fragment_multiplier": {
		"name": "lucid harvest",
		"desc": "+25% fragments earned",
	},
	"combo_duration": {
		"name": "sustained focus",
		"desc": "+1s combo timeout",
	},
}

# stats tracking
var total_runs: int = 0
var total_phantoms_defeated: int = 0
var highest_wave: int = 1
var highest_combo: int = 0
var total_fragments_earned: int = 0

func _ready():
	load_data()

func get_upgrade_value(upgrade_name: String) -> float:
	var level = upgrades.get(upgrade_name, 0)

	match upgrade_name:
		"max_health":
			return level * 20.0
		"starting_combo":
			return level * 1.0
		"rhythm_window":
			return level * 0.05
		"phantom_slowdown":
			return level * 0.10
		"fragment_multiplier":
			return level * 0.25
		"combo_duration":
			return level * 1.0

	return 0.0

func can_afford_upgrade(upgrade_name: String) -> bool:
	var level = upgrades.get(upgrade_name, 0)
	var costs = UPGRADE_COSTS.get(upgrade_name, [])

	if level >= costs.size():
		return false

	return dream_fragments >= costs[level]

func get_upgrade_cost(upgrade_name: String) -> int:
	var level = upgrades.get(upgrade_name, 0)
	var costs = UPGRADE_COSTS.get(upgrade_name, [])

	if level >= costs.size():
		return -1

	return costs[level]

func is_upgrade_maxed(upgrade_name: String) -> bool:
	var level = upgrades.get(upgrade_name, 0)
	var costs = UPGRADE_COSTS.get(upgrade_name, [])
	return level >= costs.size()

func purchase_upgrade(upgrade_name: String) -> bool:
	if not can_afford_upgrade(upgrade_name):
		return false

	var cost = get_upgrade_cost(upgrade_name)
	dream_fragments -= cost
	upgrades[upgrade_name] += 1

	save_data()
	return true

func add_fragments(amount: int):
	var multiplier = 1.0 + get_upgrade_value("fragment_multiplier")
	var actual_amount = int(amount * multiplier)
	dream_fragments += actual_amount
	total_fragments_earned += actual_amount
	save_data()

func record_run_end(wave: int, combo: int, phantoms_defeated: int):
	total_runs += 1
	total_phantoms_defeated += phantoms_defeated

	if wave > highest_wave:
		highest_wave = wave

	if combo > highest_combo:
		highest_combo = combo

	save_data()

func save_data():
	var save_dict = {
		"dream_fragments": dream_fragments,
		"upgrades": upgrades,
		"total_runs": total_runs,
		"total_phantoms_defeated": total_phantoms_defeated,
		"highest_wave": highest_wave,
		"highest_combo": highest_combo,
		"total_fragments_earned": total_fragments_earned,
	}

	var file = FileAccess.open("user://progression.dat", FileAccess.WRITE)
	if file:
		file.store_var(save_dict)
		file.close()

func load_data():
	if not FileAccess.file_exists("user://progression.dat"):
		return

	var file = FileAccess.open("user://progression.dat", FileAccess.READ)
	if file:
		var save_dict = file.get_var()
		file.close()

		if save_dict:
			dream_fragments = save_dict.get("dream_fragments", 0)
			upgrades = save_dict.get("upgrades", upgrades)
			total_runs = save_dict.get("total_runs", 0)
			total_phantoms_defeated = save_dict.get("total_phantoms_defeated", 0)
			highest_wave = save_dict.get("highest_wave", 1)
			highest_combo = save_dict.get("highest_combo", 0)
			total_fragments_earned = save_dict.get("total_fragments_earned", 0)
