extends Control

# Cutscene data: each entry is [image_path, dialogue_lines_array]
const CUTSCENE_FRAMES = [
	["res://cutscenes/images/1.png", [
		"well, i'm here now. back again, dammit.",
		"looks the same as before. damn beautiful skies.",
		"after all these times, y'know, i still get thrown off by how pretty these clouds are.",
		"all this thunder.",
		"...so beautiful."
	]],
	["res://cutscenes/images/2.png", [
		"here they come.",
		"of course. peace couldn't even last a damn second."
	]],
	["res://cutscenes/images/3.png", [
		"crap! what the f*** is that?!",
		"well, damn. come and get me!"
	]]

]

const CutsceneScene = preload("res://scenes/cutscene.tscn")

@onready var prompt_label = $PromptLabel

var blink_timer: float = 0.0
var blink_interval: float = 0.5
var cutscene_playing: bool = false

func _ready():
	# Start menu music
	# Don't auto-start menu music here; cutscenes should only play splash music
	# SoundManager.start_menu_music()

	# Debug: confirm script loaded (temporary)
	print("[intro_screen.gd] _ready() loaded — marker: 20251013_01")

func _process(delta):
	# Blink the prompt text
	blink_timer += delta
	if blink_timer >= blink_interval:
		blink_timer = 0.0
		if prompt_label:
			prompt_label.visible = !prompt_label.visible

func _input(event):
	if event is InputEventKey and event.pressed:
		# Prevent restarting while a cutscene sequence is running
		if not cutscene_playing:
			# Show cutscene sequence before main game
			show_cutscene_sequence()
	elif event is InputEventMouseButton and event.pressed:
		# Also accept mouse clicks
		if not cutscene_playing:
			show_cutscene_sequence()

func show_cutscene_sequence():
	# Play through all cutscene frames
	cutscene_playing = true
	var i = 0
	while i < CUTSCENE_FRAMES.size():
		var frame_data = CUTSCENE_FRAMES[i]
		var image_path = frame_data[0]
		var dialogue_lines = frame_data[1]

		# Load image
		var image = load(image_path) as Texture2D

		if not image:
			print("[intro_screen] Warning: ", image_path, " not found, skipping frame")
			i += 1
			continue

		# Create cutscene with dialogue lines
		var cutscene = CutsceneScene.instantiate()
		print("[intro_screen] queueing frame:", image_path, " lines=", dialogue_lines.size())
		cutscene.setup(image, dialogue_lines)
		get_tree().root.add_child(cutscene)

		# Wait for this frame to finish (the cutscene will hide itself on finish)
		await cutscene.cutscene_finished

		# Normal case: free the hidden cutscene and move on
		cutscene.queue_free()
		i += 1

	# Clean up any remaining cutscene nodes before changing scene
	for child in get_tree().root.get_children():
		if child is Control and child.has_method("finish_cutscene"):
			child.queue_free()

	# After all cutscenes, go to main game
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	cutscene_playing = false

func play_explosion_transition():
	"""Explosion particle effect + black screen fade after frame 3 into gameplay"""
	# Create fullscreen overlay for the effect
	var effect_layer = Control.new()
	effect_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	effect_layer.z_index = 200  # Above everything
	get_tree().root.add_child(effect_layer)

	# Create white flash explosion
	var flash = ColorRect.new()
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.color = Color.WHITE
	flash.modulate.a = 0.0
	effect_layer.add_child(flash)

	# Create particle burst effect (simulate with multiple small rects)
	for i in range(50):
		var particle = ColorRect.new()
		particle.size = Vector2(randf_range(2, 8), randf_range(2, 8))
		particle.position = Vector2(540, 540)  # Center of screen
		particle.color = Color.WHITE
		effect_layer.add_child(particle)

		# Animate particle outward
		var angle = randf() * TAU
		var speed = randf_range(300, 800)
		var target = particle.position + Vector2(cos(angle), sin(angle)) * speed

		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(particle, "position", target, 0.6)
		tween.tween_property(particle, "modulate:a", 0.0, 0.6)

	# Flash white then fade to black
	var flash_tween = create_tween()
	flash_tween.tween_property(flash, "modulate:a", 1.0, 0.1)  # Quick white flash
	flash_tween.tween_property(flash, "color", Color.BLACK, 0.3)  # Fade to black
	flash_tween.tween_interval(0.3)  # Hold black

	await flash_tween.finished

	# Clean up
	effect_layer.queue_free()

	# Small pause before next frame
	await get_tree().create_timer(0.2).timeout


func play_explosion_transition_into_next(next_image_path: String):
	"""Nuclear-style white blast: go instantly to white (blind), hold, then fade to next image."""
	# Load the next image texture
	var next_tex = load(next_image_path) as Texture2D
	if not next_tex:
		print("[intro_screen] Warning: next image not found:", next_image_path)
		# fallback to normal explosion
		await play_explosion_transition()
		return

	# Use a CanvasLayer so the effect is topmost and doesn't flicker with Controls
	var layer = CanvasLayer.new()
	layer.layer = 200
	get_tree().root.add_child(layer)

	# Add the next image full-screen (visible underneath the flash)
	var next_image_rect = TextureRect.new()
	next_image_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	next_image_rect.texture = next_tex
	next_image_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	next_image_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	next_image_rect.modulate.a = 1.0
	layer.add_child(next_image_rect)

	# Create white flash overlay on top and start fully opaque to avoid any underlying flicker
	var flash = ColorRect.new()
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.color = Color.WHITE
	flash.modulate.a = 1.0
	layer.add_child(flash)

	# Particle burst centered on viewport for a 'nuclear' feel (particles go fully off-screen)
	var center = get_viewport().size * 0.5
	var vp_size = get_viewport().size
	var max_dim = max(vp_size.x, vp_size.y)
	for j in range(28):
		var p = ColorRect.new()
		p.size = Vector2(randf_range(8, 28), randf_range(8, 28))
		# Place the particle centered on screen (offset by half its size)
		p.position = center - p.size * 0.5
		p.color = Color(1,1,1)
		layer.add_child(p)
		var angle = randf() * TAU
		var dir = Vector2(cos(angle), sin(angle)).normalized()
		var speed = randf_range(400, 1400)
		# Make the target far outside the viewport so particles don't stop near edges
		var target = p.position + dir * (max_dim * 1.8 + speed)
		var pt = create_tween()
		pt.tween_property(p, "position", target, 0.9)
		pt.tween_property(p, "modulate:a", 0.0, 0.9)

	# Hold the white (blind) for dramatic effect
	await get_tree().create_timer(0.6).timeout

	# Fade the white out quickly to reveal the next image
	var fade = create_tween()
	fade.tween_property(flash, "modulate:a", 0.0, 0.18)
	await fade.finished

	# Clean up
	layer.queue_free()

	# Small pause before next frame
	await get_tree().create_timer(0.12).timeout
