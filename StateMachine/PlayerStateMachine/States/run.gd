extends Motion

func _enter() -> void:
	animation_state_changed.emit("run")
	
func _state_input(event: InputEvent) -> void:
	if event.is_action_released("run"):
		finished.emit("Walk")

func _update(delta: float) -> void:
	set_direction()
	calculate_velocity(RUN_SPEED, direction, delta)	
	
	if direction == Vector3.ZERO:
		finished.emit("Idle")
