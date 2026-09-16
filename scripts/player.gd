# script ref:
# https://www.youtube.com/watch?v=ZCb12AHKMfE


extends CharacterBody3D

@export var max_speed := 6.0
@export var acceleration := 12.0
@export var turn_speed := 12.0

@export var camera: Camera3D

signal interact_pressed

func set_velocity_from_motion(vel: Vector3) -> void:
	velocity = vel

func _physics_process(delta: float) -> void:
	if velocity.length_squared() >= 0.1:
		var horizontal_velocity := Vector3(velocity.x, 0, velocity.z)
		var look_position := global_position + horizontal_velocity

		var target_transform := global_transform.looking_at(look_position, Vector3.UP, true)

		var target_yaw := target_transform.basis.get_euler().y

		$Pivot.rotation.y = rotate_toward($Pivot.rotation.y, target_yaw, turn_speed * delta)
		
	move_and_slide()

	if Input.is_action_just_pressed("interact"):
		interact_pressed.emit()
