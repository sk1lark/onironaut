# sound_manager.gd
extends Node

@onready var keypress_player = $KeypressPlayer
@onready var resolve_player = $ResolvePlayer
@onready var glitch_player = $GlitchPlayer
@onready var background_music = $BackgroundMusic
@onready var type_player = $TypePlayer
@onready var dealt_player = $DealtPlayer
@onready var hurt_player = $HurtPlayer

func _ready():
	load_sound_effects()
	# Don't auto-start background music - let scenes control it

func load_sound_effects():
	# Load the sound files
	if type_player:
		var type_sound = load("res://sounds/type.wav")
		if type_sound:
			type_player.stream = type_sound
	
	if dealt_player:
		var dealt_sound = load("res://sounds/dealt.wav")
		if dealt_sound:
			dealt_player.stream = dealt_sound
	
	if hurt_player:
		var hurt_sound = load("res://sounds/hurt.wav")
		if hurt_sound:
			hurt_player.stream = hurt_sound

func start_background_music():
	if background_music and not background_music.playing:
		background_music.play()

func stop_background_music():
	if background_music and background_music.playing:
		background_music.stop()

func fade_out_background_music(duration: float = 1.0):
	if background_music and background_music.playing:
		var tween = create_tween()
		tween.tween_property(background_music, "volume_db", -80.0, duration)
		tween.tween_callback(stop_background_music)

func play_type():
	# Play type.wav on each keystroke
	if type_player:
		type_player.pitch_scale = randf_range(0.95, 1.05)
		type_player.play()

func play_dealt():
	# Play dealt.wav when word is completed
	if dealt_player:
		dealt_player.pitch_scale = 1.0
		dealt_player.volume_db = 0.0
		dealt_player.play()

func play_hurt():
	# Play hurt.wav when taking damage
	if hurt_player:
		hurt_player.pitch_scale = randf_range(0.9, 1.1)
		hurt_player.volume_db = 0.0
		hurt_player.play()

func play_keypress(combo: int = 0, flow: float = 0.0):
	# Play a random keypress sound for variety
	if keypress_player:
		# pitch increases with combo and flow
		var base_pitch = 0.95 + (combo * 0.02) + (flow * 0.1)
		keypress_player.pitch_scale = randf_range(base_pitch, base_pitch + 0.05)
		# volume increases slightly with combo
		keypress_player.volume_db = -10.0 + (combo * 0.5)
		keypress_player.play()

func play_resolve(combo: int = 0):
	if resolve_player:
		# bigger combo = more dramatic resolve
		resolve_player.pitch_scale = 1.0 + (combo * 0.05)
		resolve_player.volume_db = -5.0 + min(combo * 0.3, 5.0)
		resolve_player.play()

func play_glitch():
	if glitch_player:
		# glitch is always harsh
		glitch_player.pitch_scale = randf_range(0.8, 0.9)
		glitch_player.volume_db = 0.0
		glitch_player.play()

# Called when entering synchronicity state
func enter_synchronicity():
	# Make keypress sounds more melodic
	pass

# Called when leaving synchronicity state  
func exit_synchronicity():
	# Return keypress sounds to normal
	pass
