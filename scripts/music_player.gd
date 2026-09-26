extends AudioStreamPlayer

const BACKGROUND_MUSIC_PATH := "res://assets/audio/funny_bgm.mp3"

@export var loop_end_seconds := 36.2

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	AudioSettings.ensure_audio_buses()
	bus = AudioSettings.MUSIC_BUS
	_load_background_music()
	finished.connect(_on_finished)

func _process(_delta: float) -> void:
	if playing and loop_end_seconds > 0.0 and get_playback_position() >= loop_end_seconds:
		play(0.0)

func play_background_music() -> void:
	_load_background_music()
	if playing:
		return
	play()

func _on_finished() -> void:
	play()

func _load_background_music() -> void:
	if stream != null:
		return

	stream = load(BACKGROUND_MUSIC_PATH)
	if stream is AudioStreamMP3:
		stream.loop = true
