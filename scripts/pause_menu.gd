extends CanvasLayer

signal pause_requested
signal resume_requested

@onready var overlay: Control = $Overlay

func _unhandled_input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	if key_event.keycode != KEY_ESCAPE:
		return

	get_viewport().set_input_as_handled()
	if overlay.visible:
		resume_requested.emit()
	else:
		pause_requested.emit()
