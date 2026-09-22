extends Node3D

@export var keyboard_turn_speed: float = 2.5
@export_range(-90.0, 90.0, 0.1, "radians_as_degrees") var min_vertical_angle: float = -PI/2
@export_range(-90.0, 90.0, 0.1, "radians_as_degrees") var max_vertical_angle: float = PI/4

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	rotation.x = clamp(rotation.x, min_vertical_angle, max_vertical_angle)

func _process(delta: float) -> void:
	var turn_input := Input.get_axis(&"camera_left", &"camera_right")
	if not is_zero_approx(turn_input):
		rotation.y = wrapf(rotation.y - turn_input * keyboard_turn_speed * delta, 0.0, TAU)
