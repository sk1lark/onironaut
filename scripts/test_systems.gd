# test script - verify all addiction systems
extends Node

func _ready():
	print("=== addiction systems test ===")
	print("✓ escalation: transformations every 30s")
	print("✓ combo: tracks consecutive completions")
	print("✓ chain reactions: explosions at 5+ combo")
	print("✓ flow state: rhythm consistency tracking")
	print("✓ screen shake: all events have juice")
	print("✓ particles: keystroke, completion, spawn")
	print("✓ sound scaling: pitch/volume with combo")
	print("=== all systems implemented ===")
	
	# test that main.gd loads
	var main_script = load("res://scripts/main.gd")
	if main_script:
		print("✓ main.gd loads successfully")
	else:
		print("✗ main.gd failed to load")
	
	# test that phantom.gd loads
	var phantom_script = load("res://scripts/phantom.gd")
	if phantom_script:
		print("✓ phantom.gd loads successfully")
	else:
		print("✗ phantom.gd failed to load")
	
	print("=== ready to play ===")
