extends Camera3D

@export var target: Node3D
@export var lerp_power: float = 1.0

func _process(delta: float) -> void:
	if target == null:
		return

	position = lerp(position, target.position, delta * lerp_power)
