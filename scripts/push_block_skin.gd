extends Node3D

@export var block_letter := "A":
	set(value):
		block_letter = value
		_apply_block_skin()

@export var block_color := Color(0.78, 0.06, 0.04, 1.0):
	set(value):
		block_color = value
		_apply_block_skin()

@export_range(0.0, 0.35, 0.005) var block_border_thickness := 0.09:
	set(value):
		block_border_thickness = value
		_apply_block_skin()

func _ready() -> void:
	_apply_block_skin()

func _apply_block_skin() -> void:
	if not is_inside_tree() or not has_node("RigidBody3D"):
		return

	var push_body := $RigidBody3D
	if push_body.has_method("set_block_skin"):
		push_body.set_block_skin(
			block_letter,
			block_color,
			block_border_thickness
		)
