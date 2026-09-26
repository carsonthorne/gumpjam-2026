extends Node

const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"
const MIN_VOLUME_DB := -40.0

func _ready() -> void:
	ensure_audio_buses()

func ensure_audio_buses() -> void:
	_ensure_bus(MUSIC_BUS)
	_ensure_bus(SFX_BUS)

func set_music_volume(value: float) -> void:
	set_bus_volume(MUSIC_BUS, value)

func set_sfx_volume(value: float) -> void:
	set_bus_volume(SFX_BUS, value)

func get_music_volume() -> float:
	return get_bus_volume(MUSIC_BUS)

func get_sfx_volume() -> float:
	return get_bus_volume(SFX_BUS)

func set_bus_volume(bus_name: String, value: float) -> void:
	ensure_audio_buses()
	var bus_index := AudioServer.get_bus_index(bus_name)
	var clamped := clampf(value, 0.0, 1.0)
	AudioServer.set_bus_mute(bus_index, clamped <= 0.0)
	if clamped > 0.0:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(clamped))

func get_bus_volume(bus_name: String) -> float:
	ensure_audio_buses()
	var bus_index := AudioServer.get_bus_index(bus_name)
	if AudioServer.is_bus_mute(bus_index):
		return 0.0
	return clampf(db_to_linear(AudioServer.get_bus_volume_db(bus_index)), 0.0, 1.0)

func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return

	AudioServer.add_bus()
	var bus_index := AudioServer.get_bus_count() - 1
	AudioServer.set_bus_name(bus_index, bus_name)
	AudioServer.set_bus_send(bus_index, "Master")
