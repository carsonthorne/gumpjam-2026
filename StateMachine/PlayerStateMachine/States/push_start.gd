extends Motion

@export var hands_on_block_time := 1.0
@export var push_start_trim_offset := 0.9

var elapsed := 0.0
var is_holding_pose := false

func _enter() -> void:
	if owner.has_node("Pivot/CharacterModel"):
		owner.get_node("Pivot/CharacterModel").set_push_start_trim_offset(push_start_trim_offset)

	elapsed = 0.0
	is_holding_pose = false
	velocity = Vector3.ZERO
	velocity_updated.emit(velocity)
	animation_state_changed.emit("push_start")

func _update(delta: float) -> void:
	velocity = Vector3.ZERO
	velocity_updated.emit(velocity)

	if owner.has_method("is_push_animation_active") and owner.is_push_animation_active():
		return

	if owner.has_method("is_push_ready_active") and not owner.is_push_ready_active():
		finished.emit("Push_end")
		return

	if is_holding_pose:
		return

	elapsed += delta
	if elapsed >= hands_on_block_time:
		is_holding_pose = true
		if owner.has_node("Pivot/CharacterModel"):
			owner.get_node("Pivot/CharacterModel").set_movement_time_scale(0.0)
