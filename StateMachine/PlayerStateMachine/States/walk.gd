extends Motion

func _enter() -> void:
	animation_state_changed.emit("walk")
	if owner.has_node("Pivot/CharacterModel"):
		owner.get_node("Pivot/CharacterModel").set_movement_time_scale(MOVEMENT_SPEED_SCALE)

func _state_input(event: InputEvent) -> void:
	if event.is_action_pressed("run"):
		finished.emit("Run")

func _update(delta: float) -> void:
	set_direction()
	calculate_velocity(SPEED * MOVEMENT_SPEED_SCALE, direction, delta)
	
	if direction == Vector3.ZERO:
		finished.emit("Idle")
	elif Input.is_action_pressed("run"):
		finished.emit("Run")
