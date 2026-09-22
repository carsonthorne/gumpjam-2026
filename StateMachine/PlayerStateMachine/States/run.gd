extends Motion

func _enter() -> void:
	animation_state_changed.emit("run")
	if owner.has_node("Pivot/CharacterModel"):
		owner.get_node("Pivot/CharacterModel").set_movement_time_scale(MOVEMENT_SPEED_SCALE)
	
func _state_input(event: InputEvent) -> void:
	if event.is_action_pressed("run") and not owner.wants_to_run():
		finished.emit("Walk")

func _update(delta: float) -> void:
	set_direction()
	calculate_velocity(RUN_SPEED * MOVEMENT_SPEED_SCALE, direction, delta)
	
	if direction == Vector3.ZERO:
		finished.emit("Idle")
	elif not owner.wants_to_run():
		finished.emit("Walk")
