# script ref:
# https://www.youtube.com/watch?v=ZCb12AHKMfE


extends CharacterBody3D

@export var max_speed := 6.0
@export var acceleration := 12.0
@export var turn_speed := 12.0
@export var brace_align_speed := 3.0
@export var brace_align_smoothing := 5.0
@export var brace_camera_return_speed := 4.0
@export var brace_align_delay := 0.0
@export var brace_initial_align_distance := 5.0
@export var brace_initial_body_align_distance := 0.0
@export var brace_visual_align_speed := 10.0
@export var brace_visual_release_hold_time := 0.2
@export var brace_release_backstep_distance := 0.12
@export var brace_release_backstep_speed := 0.75

@export var camera: Camera3D

signal interact_pressed
signal push_ready_started
signal push_ready_ended
signal push_started

var is_push_ready := false
var push_ready_direction := Vector3.ZERO
var push_ready_position := Vector3.ZERO
var has_push_ready_position := false
var push_ready_align_delay_left := 0.0
var brace_visual_release_hold_left := 0.0
var brace_release_backstep_direction := Vector3.ZERO
var brace_release_backstep_distance_left := 0.0
var push_follow_direction := Vector3.ZERO
var push_follow_contact_time_left := 0.0
var push_follow_distance_left := 0.0
var push_follow_speed := 0.0
var push_follow_distance := 0.0

func is_push_ready_active() -> bool:
	return is_push_ready

func is_push_animation_active() -> bool:
	return push_follow_direction.length_squared() > 0.0

func set_push_ready(active: bool, direction := Vector3.ZERO, brace_position := Vector3.ZERO, has_brace_position := false) -> void:
	direction.y = 0.0
	if active and direction.length_squared() > 0.0:
		push_ready_direction = direction.normalized()

	if active and has_brace_position:
		push_ready_position = brace_position
		push_ready_position.y = global_position.y
		has_push_ready_position = true

	if is_push_ready == active:
		return

	is_push_ready = active
	if is_push_ready:
		push_ready_align_delay_left = brace_align_delay
		brace_visual_release_hold_left = 0.0
		brace_release_backstep_direction = Vector3.ZERO
		brace_release_backstep_distance_left = 0.0
		if has_push_ready_position:
			if brace_initial_body_align_distance > 0.0:
				_move_toward_push_ready_position(brace_initial_body_align_distance)
		push_ready_started.emit()
	else:
		_start_brace_release_backstep()
		push_ready_direction = Vector3.ZERO
		has_push_ready_position = false
		push_ready_align_delay_left = 0.0
		brace_visual_release_hold_left = brace_visual_release_hold_time
		push_ready_ended.emit()

func is_moving_toward_direction(direction: Vector3) -> bool:
	direction.y = 0.0
	if direction.length_squared() == 0.0:
		return false

	var input_dir := Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
	if input_dir.length_squared() == 0.0:
		return false

	var move_direction := Vector3(input_dir.x, 0.0, input_dir.y).normalized()
	move_direction = move_direction.rotated(Vector3.UP, camera.global_rotation.y)
	return move_direction.dot(direction.normalized()) > 0.65

func is_colliding_with_body(body: Node) -> bool:
	for index in get_slide_collision_count():
		var collision: KinematicCollision3D = get_slide_collision(index)
		if collision.get_collider() == body:
			return true

	return false

func play_push_animation(direction := Vector3.ZERO, contact_delay := 0.0, push_speed := 0.0, push_distance := 0.0) -> void:
	_apply_brace_visual_offset_to_root()
	is_push_ready = false
	push_ready_direction = Vector3.ZERO
	has_push_ready_position = false
	push_ready_align_delay_left = 0.0
	brace_visual_release_hold_left = 0.0
	brace_release_backstep_direction = Vector3.ZERO
	brace_release_backstep_distance_left = 0.0
	push_started.emit()
	start_push_follow(direction, contact_delay, push_speed, push_distance)

func start_push_follow(direction: Vector3, contact_delay: float, push_speed: float, push_distance: float) -> void:
	direction.y = 0.0

	if direction.length_squared() == 0.0 or push_speed <= 0.0 or push_distance <= 0.0:
		push_follow_direction = Vector3.ZERO
		push_follow_contact_time_left = 0.0
		push_follow_distance_left = 0.0
		return

	push_follow_direction = direction.normalized()
	push_follow_contact_time_left = contact_delay
	push_follow_distance_left = 0.0
	push_follow_speed = push_speed
	push_follow_distance = push_distance

	if push_follow_contact_time_left == 0.0:
		push_follow_distance_left = push_follow_distance

func sync_push_follow_position(brace_position: Vector3) -> void:
	brace_position.y = global_position.y
	var previous_position := global_position
	global_position.x = brace_position.x
	global_position.z = brace_position.z
	_counter_brace_camera_motion(global_position - previous_position)

func get_horizontal_distance_to_position(position: Vector3) -> float:
	var offset := global_position - position
	offset.y = 0.0
	return offset.length()

func set_velocity_from_motion(vel: Vector3) -> void:
	velocity = vel

func _physics_process(delta: float) -> void:
	if is_push_ready:
		velocity = Vector3.ZERO

	if is_push_ready and push_ready_direction.length_squared() > 0.0:
		_rotate_pivot_toward_direction(push_ready_direction, delta)
	elif push_follow_direction.length_squared() > 0.0:
		_rotate_pivot_toward_direction(push_follow_direction, delta)
	elif velocity.length_squared() >= 0.1:
		_rotate_pivot_toward_direction(Vector3(velocity.x, 0.0, velocity.z), delta)
		
	move_and_slide()

	if is_push_ready and push_ready_align_delay_left > 0.0:
		push_ready_align_delay_left = maxf(push_ready_align_delay_left - delta, 0.0)
	elif is_push_ready and has_push_ready_position:
		var brace_position_before := global_position
		_smooth_move_to_push_ready_position(delta)
		_counter_brace_camera_motion(global_position - brace_position_before)

	_update_brace_release_backstep(delta)
	_update_brace_camera_offset(delta)
	_update_brace_visual_offset(delta)
	_update_push_follow(delta)

	if Input.is_action_just_pressed("interact"):
		interact_pressed.emit()

func _smooth_move_to_push_ready_position(delta: float) -> void:
	var current_position := Vector3(global_position.x, 0.0, global_position.z)
	var target_position := Vector3(push_ready_position.x, 0.0, push_ready_position.z)
	var offset := target_position - current_position
	if offset.length_squared() == 0.0:
		return

	var smoothing_factor := 1.0 - exp(-maxf(brace_align_smoothing, 0.0) * delta)
	var step_distance := offset.length() * smoothing_factor
	if brace_align_speed > 0.0:
		step_distance = minf(step_distance, brace_align_speed * delta)

	var next_position := current_position.move_toward(target_position, step_distance)
	global_position.x = next_position.x
	global_position.z = next_position.z

func _move_toward_push_ready_position(distance: float) -> void:
	var current_position := Vector3(global_position.x, 0.0, global_position.z)
	var target_position := Vector3(push_ready_position.x, 0.0, push_ready_position.z)
	var next_position := current_position.move_toward(target_position, distance)
	global_position.x = next_position.x
	global_position.z = next_position.z

func _start_brace_release_backstep() -> void:
	_start_release_backstep(push_ready_direction)

func _start_release_backstep(direction: Vector3) -> void:
	direction.y = 0.0
	if direction.length_squared() == 0.0 or brace_release_backstep_distance <= 0.0:
		brace_release_backstep_direction = Vector3.ZERO
		brace_release_backstep_distance_left = 0.0
		return

	brace_release_backstep_direction = -direction.normalized()
	brace_release_backstep_distance_left = brace_release_backstep_distance

func _update_brace_release_backstep(delta: float) -> void:
	if brace_release_backstep_distance_left <= 0.0 or brace_release_backstep_speed <= 0.0 or brace_release_backstep_direction.length_squared() == 0.0:
		return

	var step_distance := minf(brace_release_backstep_speed * delta, brace_release_backstep_distance_left)
	var motion := brace_release_backstep_direction * step_distance
	global_position += motion
	_counter_brace_camera_motion(motion)
	brace_release_backstep_distance_left -= step_distance

	if brace_release_backstep_distance_left == 0.0:
		brace_release_backstep_direction = Vector3.ZERO

func _counter_brace_camera_motion(motion: Vector3) -> void:
	motion.y = 0.0
	if motion.length_squared() == 0.0 or not has_node("SpringArmPivot"):
		return

	var spring_arm_pivot: Node3D = $SpringArmPivot
	spring_arm_pivot.position.x -= motion.x
	spring_arm_pivot.position.z -= motion.z

func _update_brace_camera_offset(delta: float) -> void:
	if not has_node("SpringArmPivot"):
		return

	var spring_arm_pivot: Node3D = $SpringArmPivot
	var current_offset := Vector3(spring_arm_pivot.position.x, 0.0, spring_arm_pivot.position.z)
	var next_offset := current_offset.move_toward(Vector3.ZERO, brace_camera_return_speed * delta)
	spring_arm_pivot.position.x = next_offset.x
	spring_arm_pivot.position.z = next_offset.z

func _update_brace_visual_offset(delta: float) -> void:
	var target_offset := Vector3.ZERO
	if is_push_ready and has_push_ready_position:
		target_offset = _get_brace_visual_target_offset()
	elif brace_visual_release_hold_left > 0.0:
		brace_visual_release_hold_left = maxf(brace_visual_release_hold_left - delta, 0.0)
		target_offset = Vector3($Pivot.position.x, 0.0, $Pivot.position.z)

	var current_offset := Vector3($Pivot.position.x, 0.0, $Pivot.position.z)
	var next_offset := current_offset.move_toward(target_offset, brace_visual_align_speed * delta)
	$Pivot.position.x = next_offset.x
	$Pivot.position.z = next_offset.z

func _get_brace_visual_target_offset() -> Vector3:
	var offset := push_ready_position - global_position
	offset.y = 0.0

	if brace_initial_align_distance > 0.0:
		offset = offset.limit_length(brace_initial_align_distance)

	return offset

func _apply_brace_visual_offset_to_root() -> void:
	var pivot_offset := Vector3($Pivot.position.x, 0.0, $Pivot.position.z)
	if pivot_offset.length_squared() == 0.0:
		return

	global_position += pivot_offset
	_counter_brace_camera_motion(pivot_offset)
	$Pivot.position.x = 0.0
	$Pivot.position.z = 0.0

func _rotate_pivot_toward_direction(direction: Vector3, delta: float) -> void:
	direction.y = 0.0
	if direction.length_squared() == 0.0:
		return

	var look_position := global_position + direction.normalized()
	var target_transform := global_transform.looking_at(look_position, Vector3.UP, true)
	var target_yaw := target_transform.basis.get_euler().y
	$Pivot.rotation.y = rotate_toward($Pivot.rotation.y, target_yaw, turn_speed * delta)

func _update_push_follow(delta: float) -> void:
	if push_follow_contact_time_left > 0.0:
		push_follow_contact_time_left = maxf(push_follow_contact_time_left - delta, 0.0)
		if push_follow_contact_time_left == 0.0:
			push_follow_distance_left = push_follow_distance
		return

	if push_follow_distance_left <= 0.0:
		return

	var step_distance := minf(push_follow_speed * delta, push_follow_distance_left)
	push_follow_distance_left -= step_distance

	if push_follow_distance_left == 0.0:
		var completed_push_direction := push_follow_direction
		push_follow_direction = Vector3.ZERO
		if is_moving_toward_direction(completed_push_direction):
			set_push_ready(true, completed_push_direction, global_position, true)
		else:
			_start_release_backstep(completed_push_direction)
			brace_visual_release_hold_left = brace_visual_release_hold_time
