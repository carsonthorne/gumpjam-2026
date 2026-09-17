extends Motion

@export var push_end_duration := 0.25
@export var push_end_trim_offset := 0.0

var elapsed := 0.0

func _enter() -> void:
	if owner.has_node("Pivot/CharacterModel"):
		var character_model: CharacterModel = owner.get_node("Pivot/CharacterModel") as CharacterModel
		if character_model != null:
			character_model.set_push_end_trim_offset(push_end_trim_offset)
			character_model.set_movement_time_scale(1.0)
	elapsed = 0.0
	velocity = Vector3.ZERO
	velocity_updated.emit(velocity)
	animation_state_changed.emit("push_end")

func _update(delta: float) -> void:
	elapsed += delta
	velocity = Vector3.ZERO
	velocity_updated.emit(velocity)

	if elapsed >= push_end_duration:
		if owner.has_method("is_push_ready_active") and owner.is_push_ready_active():
			finished.emit("Push_start")
		else:
			finished.emit("Idle")
