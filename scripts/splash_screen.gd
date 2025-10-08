# splash_screen.gd
extends Control

@onready var play_button = $Content/PlayButton
@onready var quit_button = $Content/QuitButton
@onready var title = $Content/Title
@onready var subtitle = $Content/Subtitle
@onready var dither_shader = $DitherLayer/DitherShader
@onready var splash_music = $SplashMusic

var dealt_sound: AudioStream
var button_hover_tween: Tween

func _ready():
	# Load dealt.wav for button sounds
	dealt_sound = load("res://sounds/dealt.wav")
	
	# Setup button styles
	setup_button_style(play_button)
	setup_button_style(quit_button)
	
	# Animate title entrance
	animate_title_entrance()
	
	# Start splash music
	if splash_music:
		splash_music.play()

func setup_button_style(button: Button):
	# Create custom StyleBox for buttons
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color.BLACK
	normal_style.border_width_left = 4
	normal_style.border_width_right = 4
	normal_style.border_width_top = 4
	normal_style.border_width_bottom = 4
	normal_style.border_color = Color.WHITE
	
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color.WHITE
	hover_style.border_width_left = 4
	hover_style.border_width_right = 4
	hover_style.border_width_top = 4
	hover_style.border_width_bottom = 4
	hover_style.border_color = Color.WHITE
	
	var pressed_style = StyleBoxFlat.new()
	pressed_style.bg_color = Color.WHITE
	pressed_style.border_width_left = 6
	pressed_style.border_width_right = 6
	pressed_style.border_width_top = 6
	pressed_style.border_width_bottom = 6
	pressed_style.border_color = Color.BLACK
	
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)

func animate_title_entrance():
	# Title fades in with scale
	title.modulate.a = 0.0
	title.scale = Vector2(0.5, 0.5)
	subtitle.modulate.a = 0.0
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(title, "modulate:a", 1.0, 0.8)
	tween.tween_property(title, "scale", Vector2.ONE, 0.8).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	
	await tween.finished
	
	# Subtitle fades in
	var sub_tween = create_tween()
	sub_tween.tween_property(subtitle, "modulate:a", 1.0, 0.5)
	
	# Start title pulse animation
	pulse_title()

func pulse_title():
	# Continuous subtle pulse on title
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(title, "scale", Vector2(1.02, 1.02), 1.5)
	tween.tween_property(title, "scale", Vector2.ONE, 1.5)

func _on_play_button_mouse_entered():
	play_hover_sound()
	button_hover_effect(play_button)

func _on_quit_button_mouse_entered():
	play_hover_sound()
	button_hover_effect(quit_button)

func button_hover_effect(button: Button):
	# Quick scale bounce on hover
	if button_hover_tween:
		button_hover_tween.kill()
	
	button_hover_tween = create_tween()
	button_hover_tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.1)

func play_hover_sound():
	# Subtle sound on hover (quiet dealt sound)
	if dealt_sound:
		var player = AudioStreamPlayer.new()
		add_child(player)
		player.stream = dealt_sound
		player.volume_db = -15.0
		player.pitch_scale = 1.2
		player.play()
		player.finished.connect(func(): player.queue_free())

func play_select_sound():
	# Full volume dealt sound on selection
	if dealt_sound:
		var player = AudioStreamPlayer.new()
		add_child(player)
		player.stream = dealt_sound
		player.volume_db = 0.0
		player.pitch_scale = 1.0
		player.play()
		player.finished.connect(func(): player.queue_free())

func _on_play_button_pressed():
	play_select_sound()
	
	# Fade out splash music
	var music_tween = create_tween()
	music_tween.tween_property(splash_music, "volume_db", -80.0, 0.5)
	
	# Button press animation
	var tween = create_tween()
	tween.tween_property(play_button, "scale", Vector2(0.95, 0.95), 0.1)
	tween.tween_property(play_button, "scale", Vector2.ONE, 0.1)
	
	# Static flash transition
	spawn_static_flash()
	
	await get_tree().create_timer(0.5).timeout
	
	# Load main game scene
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_quit_button_pressed():
	play_select_sound()
	
	# Button press animation
	var tween = create_tween()
	tween.tween_property(quit_button, "scale", Vector2(0.95, 0.95), 0.1)
	tween.tween_property(quit_button, "scale", Vector2.ONE, 0.1)
	
	# Static flash
	spawn_static_flash()
	
	await get_tree().create_timer(0.3).timeout
	
	# Quit game
	get_tree().quit()

func spawn_static_flash():
	# Full screen static flash effect
	var static_rect = ColorRect.new()
	static_rect.size = Vector2(960, 540)
	static_rect.position = Vector2.ZERO
	static_rect.color = Color.WHITE
	static_rect.z_index = 99
	
	# Add static shader
	var shader_mat = ShaderMaterial.new()
	var static_shader = load("res://shaders/static_shader.gdshader")
	shader_mat.shader = static_shader
	shader_mat.set_shader_parameter("noise_speed", 100.0)
	static_rect.material = shader_mat
	
	add_child(static_rect)
	
	# Quick flash
	var tween = create_tween()
	tween.tween_property(static_rect, "modulate:a", 0.0, 0.2)
	tween.finished.connect(func(): static_rect.queue_free())

func _input(event):
	# Allow ESC to quit
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_on_quit_button_pressed()
