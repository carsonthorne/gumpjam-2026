extends CanvasLayer

@onready var console_box: Control = $ConsoleBox
@onready var output_text: RichTextLabel = $ConsoleBox/PanelContainer/MarginContainer/OutputText
@onready var resize_handle: Control = $ConsoleBox/ResizeHandle

var is_resizing := false
var resize_start_mouse := Vector2.ZERO
var resize_start_size := Vector2.ZERO

const MIN_SIZE := Vector2(220, 120)

func _ready() -> void:
	Log.message_printed.connect(_on_log_message_printed)

	resize_handle.mouse_default_cursor_shape = Control.CURSOR_FDIAGSIZE
	resize_handle.gui_input.connect(_on_resize_handle_gui_input)
	output_text.scroll_following = true

func _on_log_message_printed(message: String) -> void:
	output_text.append_text(message + "\n")

func _on_resize_handle_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		is_resizing = event.pressed
		resize_start_mouse = resize_handle.get_global_mouse_position()
		resize_start_size = console_box.size

	if event is InputEventMouseMotion and is_resizing:
		var mouse_delta := resize_handle.get_global_mouse_position() - resize_start_mouse
		var new_size := resize_start_size + mouse_delta

		new_size.x = max(new_size.x, MIN_SIZE.x)
		new_size.y = max(new_size.y, MIN_SIZE.y)

		console_box.size = new_size
