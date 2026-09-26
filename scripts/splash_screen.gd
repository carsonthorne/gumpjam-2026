extends Control

const START_MENU_SCENE := "res://scenes/start_menu.tscn"

@export_range(0.5, 8.0, 0.05) var animation_duration := 4.0
@export_range(0.0, 1.0, 0.005) var start_scale := 0.01
@export_range(0.25, 8.0, 0.25) var clockwise_turns := 5.0
@export_range(1.0, 1.25, 0.01) var bounce_overshoot_scale := 1.08
@export_range(0.5, 1.0, 0.01) var bounce_compression_scale := 0.92
@export_range(0.05, 1.0, 0.01) var bounce_compression_duration := 0.4
@export_range(0.05, 1.5, 0.01) var bounce_settle_duration := 0.9
@export_range(0.0, 5.0, 0.01) var audio_start_delay := 2.32

@onready var logo: TextureRect = $Logo
@onready var intro_audio: AudioStreamPlayer = $IntroAudio
@onready var start_prompt: Label = $StartPrompt

var splash_tween: Tween = null
var is_continuing := false

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_update_logo_pivot()
	resized.connect(_update_logo_pivot)
	get_viewport().size_changed.connect(_update_logo_pivot)
	logo.scale = Vector2.ONE * start_scale
	logo.rotation = 0.0
	start_prompt.visible = false
	start_prompt.modulate.a = 0.0
	await get_tree().process_frame
	_update_logo_pivot()
	_play_intro_audio_after_delay()
	_play_splash()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_SPACE or event.physical_keycode == KEY_SPACE):
		get_viewport().set_input_as_handled()
		_continue_to_start_menu()

func _update_logo_pivot() -> void:
	logo.pivot_offset = logo.size * 0.5

func _play_intro_audio_after_delay() -> void:
	if audio_start_delay > 0.0:
		await get_tree().create_timer(audio_start_delay).timeout
	if not is_continuing:
		intro_audio.play()

func _play_splash() -> void:
	if splash_tween != null and splash_tween.is_valid():
		splash_tween.kill()
	splash_tween = create_tween().set_parallel(true)
	var scale_tweener := splash_tween.tween_property(logo, "scale", Vector2.ONE * bounce_overshoot_scale, animation_duration)
	scale_tweener.set_trans(Tween.TRANS_QUART)
	scale_tweener.set_ease(Tween.EASE_IN)
	var rotation_tweener := splash_tween.tween_property(logo, "rotation", TAU * clockwise_turns, animation_duration)
	rotation_tweener.set_trans(Tween.TRANS_QUAD)
	rotation_tweener.set_ease(Tween.EASE_IN)
	await splash_tween.finished
	splash_tween = create_tween()
	splash_tween.tween_property(logo, "scale", Vector2.ONE * bounce_compression_scale, bounce_compression_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	splash_tween.tween_property(logo, "scale", Vector2.ONE, bounce_settle_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await splash_tween.finished
	logo.scale = Vector2.ONE
	logo.rotation = 0.0
	if intro_audio.playing:
		await intro_audio.finished
	if is_continuing:
		return
	start_prompt.visible = true
	var prompt_tween := create_tween()
	prompt_tween.tween_property(start_prompt, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _continue_to_start_menu() -> void:
	if is_continuing:
		return
	is_continuing = true
	if splash_tween != null and splash_tween.is_valid():
		splash_tween.kill()
	intro_audio.stop()
	get_tree().change_scene_to_file(START_MENU_SCENE)
