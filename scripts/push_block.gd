extends AnimatableBody3D

@export var push_speed := 1.5
@export var push_contact_delay := 0.0
@export var push_distance := 1.0
@export var brace_distance_from_block_center := 1.0
@export var brace_face_alignment_half_width := 0.35
@export var player_push_movement_delay := 0.12

@onready var front_zone: Area3D = $PushZones/FrontZone
@onready var back_zone: Area3D = $PushZones/BackZone
@onready var left_zone: Area3D = $PushZones/LeftZone
@onready var right_zone: Area3D = $PushZones/RightZone

var player: Node = null
var push_direction := Vector3.ZERO
var active_player_zones := {}
var active_push_direction := Vector3.ZERO
var push_contact_time_left := 0.0
var push_distance_left := 0.0
var push_start_position := Vector3.ZERO
var push_target_position := Vector3.ZERO
var push_brace_distance_from_block_center := 0.0
var player_push_delay_left := 0.0
var player_push_distance_left := 0.0
var player_push_moved_distance := 0.0
var is_push_in_progress := false

func _ready() -> void:
	front_zone.body_entered.connect(_on_front_zone_body_entered)
	front_zone.body_exited.connect(_on_zone_body_exited.bind(front_zone))

	back_zone.body_entered.connect(_on_back_zone_body_entered)
	back_zone.body_exited.connect(_on_zone_body_exited.bind(back_zone))

	left_zone.body_entered.connect(_on_left_zone_body_entered)
	left_zone.body_exited.connect(_on_zone_body_exited.bind(left_zone))

	right_zone.body_entered.connect(_on_right_zone_body_entered)
	right_zone.body_exited.connect(_on_zone_body_exited.bind(right_zone))

func _physics_process(delta: float) -> void:
	_update_player_push_ready()

	if push_contact_time_left > 0.0:
		push_contact_time_left = maxf(push_contact_time_left - delta, 0.0)
		if push_contact_time_left == 0.0:
			push_distance_left = push_distance
		return

	if push_distance_left <= 0.0 and player_push_distance_left <= 0.0:
		return

	if push_distance_left > 0.0:
		var step_distance := minf(push_speed * delta, push_distance_left)
		push_distance_left -= step_distance
		var moved_distance := push_distance - push_distance_left
		global_position = push_start_position + active_push_direction * moved_distance

		if push_distance_left == 0.0:
			global_position = push_target_position

	_update_player_push_position(delta)

	if push_distance_left == 0.0 and player_push_distance_left == 0.0:
		active_push_direction = Vector3.ZERO
		is_push_in_progress = false

func _on_front_zone_body_entered(body: Node3D) -> void:
	_register_player(body, front_zone, -global_transform.basis.z)

func _on_back_zone_body_entered(body: Node3D) -> void:
	_register_player(body, back_zone, global_transform.basis.z)

func _on_left_zone_body_entered(body: Node3D) -> void:
	_register_player(body, left_zone, global_transform.basis.x)

func _on_right_zone_body_entered(body: Node3D) -> void:
	_register_player(body, right_zone, -global_transform.basis.x)

func _on_zone_body_exited(body: Node3D, zone: Area3D) -> void:
	if body == player:
		active_player_zones.erase(zone)
		#Log.print("player exited %s, active zones: %d" % [zone.name, active_player_zones.size()])

		if not active_player_zones.is_empty():
			_refresh_push_direction_from_active_zones()
			return

		if player.interact_pressed.is_connected(_on_player_interact_pressed):
			player.interact_pressed.disconnect(_on_player_interact_pressed)

		if player.has_method("set_push_ready"):
			player.set_push_ready(false, Vector3.ZERO, Vector3.ZERO, false, self)

		player = null
		push_direction = Vector3.ZERO

func _register_player(body: Node3D, zone: Area3D, direction: Vector3) -> void:
	if not body.is_in_group("player"):
		return

	if player != null and body != player:
		return

	player = body
	active_player_zones[zone] = direction.normalized()
	_refresh_push_direction_from_active_zones()
	#Log.print("player entered %s, active zones: %d" % [zone.name, active_player_zones.size()])

	if not player.interact_pressed.is_connected(_on_player_interact_pressed):
		player.interact_pressed.connect(_on_player_interact_pressed)

func _refresh_push_direction_from_active_zones() -> void:
	if player == null or active_player_zones.is_empty():
		push_direction = Vector3.ZERO
		return

	var player_offset: Vector3 = player.global_position - global_position
	player_offset.y = 0.0
	if player_offset.length_squared() == 0.0:
		return

	var direction_to_player: Vector3 = player_offset.normalized()
	var best_score := -INF
	var best_direction := Vector3.ZERO
	for zone in active_player_zones:
		var candidate_direction: Vector3 = active_player_zones[zone]
		var score: float = direction_to_player.dot(-candidate_direction.normalized())
		if score > best_score:
			best_score = score
			best_direction = candidate_direction

	push_direction = best_direction

func _on_player_interact_pressed() -> void:
	if _can_player_push_block():
		push(push_direction)

func _update_player_push_ready() -> void:
	if player == null or is_push_in_progress:
		return

	var can_brace := _can_player_brace_block()
	if player.has_method("set_push_ready"):
		player.set_push_ready(can_brace, push_direction, _get_player_brace_position(), true, self)

func _can_player_brace_block() -> bool:
	return _is_player_ready_for_new_push() and _is_player_pushing_toward_block() and _is_player_aligned_with_push_face() and (_is_player_colliding_with_block() or _is_player_already_bracing_block())

func _can_player_push_block() -> bool:
	return _is_player_ready_for_new_push() and _is_player_already_bracing_block() and _is_player_pushing_toward_block() and _is_player_aligned_with_push_face() and not _is_push_path_blocked(push_direction)

func _is_player_ready_for_new_push() -> bool:
	return player != null and _can_player_use_this_block() and (not player.has_method("is_push_animation_active") or not player.is_push_animation_active())

func _can_player_use_this_block() -> bool:
	return player == null or not player.has_method("can_accept_push_ready_source") or player.can_accept_push_ready_source(self)

func _is_player_pushing_toward_block() -> bool:
	return player != null and player.has_method("is_moving_toward_direction") and player.is_moving_toward_direction(push_direction)

func _is_player_colliding_with_block() -> bool:
	return player != null and player.has_method("is_colliding_with_body") and player.is_colliding_with_body(self)

func _is_player_already_bracing_block() -> bool:
	return player != null and player.has_method("is_push_ready_active") and player.is_push_ready_active(self)

func _is_player_aligned_with_push_face() -> bool:
	if player == null or push_direction.length_squared() == 0.0:
		return false

	var player_offset: Vector3 = player.global_position - global_position
	player_offset.y = 0.0

	var local_x := player_offset.dot(global_transform.basis.x.normalized())
	var local_z := player_offset.dot(global_transform.basis.z.normalized())
	var local_push_x := push_direction.dot(global_transform.basis.x.normalized())
	var local_push_z := push_direction.dot(global_transform.basis.z.normalized())

	if absf(local_push_x) > absf(local_push_z):
		return absf(local_z) <= brace_face_alignment_half_width

	return absf(local_x) <= brace_face_alignment_half_width

func _get_player_brace_position() -> Vector3:
	return _get_player_brace_position_for_direction(push_direction)

func _get_player_brace_position_for_direction(direction: Vector3, distance_from_block_center := brace_distance_from_block_center) -> Vector3:
	var brace_position: Vector3 = global_position - direction.normalized() * distance_from_block_center
	if player != null:
		brace_position.y = player.global_position.y
	return brace_position

func _get_player_distance_from_block_center() -> float:
	if player == null:
		return brace_distance_from_block_center

	if player.has_method("get_horizontal_distance_to_position"):
		return float(player.get_horizontal_distance_to_position(global_position))

	var offset: Vector3 = player.global_position - global_position
	offset.y = 0.0
	return offset.length()

func _update_player_push_position(delta: float) -> void:
	if player == null or active_push_direction.length_squared() == 0.0:
		return

	if player_push_delay_left > 0.0:
		player_push_delay_left = maxf(player_push_delay_left - delta, 0.0)
		return

	if player_push_distance_left <= 0.0:
		return

	var step_distance := minf(push_speed * delta, player_push_distance_left)
	player_push_distance_left -= step_distance
	player_push_moved_distance += step_distance
	_sync_player_push_position_for_moved_distance(player_push_moved_distance)

func _sync_player_push_position_for_moved_distance(moved_distance: float) -> void:
	if player == null or active_push_direction.length_squared() == 0.0:
		return

	if player.has_method("sync_push_follow_position"):
		var delayed_block_position := push_start_position + active_push_direction * moved_distance
		player.sync_push_follow_position(_get_player_brace_position_at_block_position(delayed_block_position, active_push_direction, push_brace_distance_from_block_center))

func _get_player_brace_position_at_block_position(block_position: Vector3, direction: Vector3, distance_from_block_center: float) -> Vector3:
	var brace_position: Vector3 = block_position - direction.normalized() * distance_from_block_center
	if player != null:
		brace_position.y = player.global_position.y
	return brace_position

func _snap_to_push_axis(direction: Vector3) -> Vector3:
	direction.y = 0.0
	if absf(direction.x) > absf(direction.z):
		return Vector3(signf(direction.x), 0.0, 0.0)
	return Vector3(0.0, 0.0, signf(direction.z))

func _is_push_path_blocked(direction: Vector3) -> bool:
	direction = _snap_to_push_axis(direction)
	if direction.length_squared() == 0.0:
		return true

	var parameters := PhysicsTestMotionParameters3D.new()
	parameters.from = global_transform
	parameters.motion = direction * push_distance
	parameters.margin = 0.001
	if player is CollisionObject3D:
		parameters.exclude_bodies = [player.get_rid()]
	return PhysicsServer3D.body_test_motion(get_rid(), parameters)

func push(direction: Vector3) -> void:
	direction.y = 0

	if is_push_in_progress or direction.length_squared() == 0 or not _can_player_push_block():
		return

	is_push_in_progress = true
	active_push_direction = _snap_to_push_axis(direction)
	push_contact_time_left = push_contact_delay
	push_distance_left = 0.0
	push_start_position = global_position
	push_target_position = push_start_position + active_push_direction * push_distance
	player_push_delay_left = player_push_movement_delay
	player_push_distance_left = push_distance
	player_push_moved_distance = 0.0

	if player != null and player.has_method("play_push_animation"):
		player.play_push_animation(active_push_direction, push_contact_delay, push_speed, push_distance, player_push_movement_delay, self)
		push_brace_distance_from_block_center = _get_player_distance_from_block_center()
		_sync_player_push_position_for_moved_distance(player_push_moved_distance)

	if push_contact_time_left == 0.0:
		push_distance_left = push_distance
