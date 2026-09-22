extends Motion

func _enter() -> void:
	if owner.has_node("Pivot/CharacterModel"):
		owner.get_node("Pivot/CharacterModel").set_movement_time_scale(1.0)
	animation_state_changed.emit("idle")
	
func _state_input(event: InputEvent) -> void:
	
	# don't allow push while idle
	if event.is_action_pressed("interact"):
		return

func _update(delta: float) -> void:
	set_direction()
	calculate_velocity(SPEED, direction, delta)
	
	if direction != Vector3.ZERO:
		if owner.wants_to_run():
			finished.emit("Run")
		else:
			finished.emit("Walk")
