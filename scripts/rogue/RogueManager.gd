extends Node

# RogueManager: lightweight roguelike run manager inspired by Hacky.
# Responsibilities:
# - Generate a run (seeded) of encounters
# - Track player progress, levels, and resources
# - Emit signals to start/finish encounters so the main game can show minigames

signal run_started(seed)
signal encounter_started(encounter_index, encounter_data)
signal encounter_finished(encounter_index, result)
signal run_finished(result)

# Config
var seed: int = 0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var encounter_count: int = 8

# Simple encounter templates. Each encounter has a type and difficulty.
var ENCOUNTER_TEMPLATES := [
	{"type":"typing", "difficulty":1},
	{"type":"typing", "difficulty":2},
	{"type":"typing", "difficulty":3},
	{"type":"typing", "difficulty":1},
	{"type":"typing", "difficulty":2}
]

# Current run state
var run_encounters: Array = []
var current_index: int = -1
var run_active: bool = false
var player_hp: int = 10
var player_max_hp: int = 10
var score: int = 0

func start_run(optional_seed: int = -1, encounters = null):
	# Initialize RNG
	if optional_seed == -1:
		# Use Time helper - consistent with other scripts in the project
		seed = int(Time.get_unix_time_from_system()) ^ randi()
	else:
		seed = optional_seed
	rng.seed = seed
	run_encounters.clear()

	# Build encounter sequence
	if encounters != null:
		run_encounters = encounters.duplicate(true)
	else:
		for i in range(encounter_count):
			var t = ENCOUNTER_TEMPLATES[rng.randi_range(0, ENCOUNTER_TEMPLATES.size() - 1)]
			var e = {"type": t["type"], "difficulty": t["difficulty"]}
			run_encounters.append(e)

	current_index = -1
	run_active = true
	player_hp = player_max_hp
	score = 0
	emit_signal("run_started", seed)
	# Immediately start first encounter
	start_next_encounter()

func start_next_encounter():
	if not run_active:
		return
	current_index += 1
	if current_index >= run_encounters.size():
		run_active = false
		emit_signal("run_finished", {"score": score, "player_hp": player_hp})
		return
	var enc = run_encounters[current_index]
	emit_signal("encounter_started", current_index, enc)

func finish_encounter(result: Dictionary):
	# result: {"success": bool, "reward": int, "damage": int}
	if not run_active:
		return
	player_hp -= result.get("damage", 0)
	if result.get("success", false):
		score += result.get("reward", 0)
	# Limit hp
	player_hp = clamp(player_hp, 0, player_max_hp)
	emit_signal("encounter_finished", current_index, result)

	# If player dead, end run
	if player_hp <= 0:
		run_active = false
		emit_signal("run_finished", {"score": score, "player_hp": player_hp})
		return

	# otherwise continue
	start_next_encounter()
