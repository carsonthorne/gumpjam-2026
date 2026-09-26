extends Node3D
class_name CharacterModel

@export var animation_tree: AnimationTree
@export var remove_pushing_root_motion := true
@export var make_pushing_upper_body_pose_uniform := true
@export var make_push_end_upper_body_pose_uniform := true
@export var pushing_pose_backstep_distance := 2.5

const PUSHING_UNIFORM_ROTATION_BONES := [
	"mixamorig_Spine",
	"mixamorig_Spine1",
	"mixamorig_Spine2",
	"mixamorig_Neck",
	"mixamorig_Head",
	"mixamorig_LeftShoulder",
	"mixamorig_LeftArm",
	"mixamorig_LeftForeArm",
	"mixamorig_LeftHand",
	"mixamorig_LeftHandIndex1",
	"mixamorig_LeftHandIndex2",
	"mixamorig_LeftHandIndex3",
	"mixamorig_LeftHandIndex4",
	"mixamorig_RightShoulder",
	"mixamorig_RightArm",
	"mixamorig_RightForeArm",
	"mixamorig_RightHand",
	"mixamorig_RightHandIndex1",
	"mixamorig_RightHandIndex2",
	"mixamorig_RightHandIndex3",
	"mixamorig_RightHandIndex4",
]

const PUSHING_UNIFORM_POSITION_BONES := [
	"mixamorig_Hips",
	"mixamorig_Spine",
	"mixamorig_Spine1",
	"mixamorig_Spine2",
	"mixamorig_Neck",
	"mixamorig_Head",
	"mixamorig_LeftShoulder",
	"mixamorig_LeftArm",
	"mixamorig_LeftForeArm",
	"mixamorig_LeftHand",
	"mixamorig_LeftHandIndex1",
	"mixamorig_LeftHandIndex2",
	"mixamorig_LeftHandIndex3",
	"mixamorig_LeftHandIndex4",
	"mixamorig_RightShoulder",
	"mixamorig_RightArm",
	"mixamorig_RightForeArm",
	"mixamorig_RightHand",
	"mixamorig_RightHandIndex1",
	"mixamorig_RightHandIndex2",
	"mixamorig_RightHandIndex3",
	"mixamorig_RightHandIndex4",
]

var pushing_uniform_pose_source_animation := &"pushing"
var pushing_uniform_pose_source_time := 0.0

const PUSH_END_SAFE_ANIMATION := &"push_end_safe"
const CHICKEN_DANCE_ANIMATION := &"chicken_dance"
const IDLE_ANIMATION := &"idle"
const DEFAULT_MOVEMENT_CROSSFADE := 0.12
const CELEBRATION_CROSSFADE := 0.8
const CHEESE_REACH_BONES := [
	"mixamorig_Neck",
	"mixamorig_Head",
	"mixamorig_LeftArm",
	"mixamorig_LeftForeArm",
	"mixamorig_RightArm",
	"mixamorig_RightForeArm",
]

var cheese_reach_base_rotations := {}
var cheese_reach_target_rotations := {}
var cheese_reach_weight := 0.0
var cheese_reach_tween: Tween = null

@onready var cheese_reach_modifier = get_node("rat-albert-animated/Armature/Skeleton3D/CheeseReachModifier")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if remove_pushing_root_motion:
		_remove_pushing_root_motion()


func on_state_machine_animation_state_changed(state: String) -> void:
	_set_movement_crossfade(DEFAULT_MOVEMENT_CROSSFADE)
	set_movement_time_scale(1.0)
	animation_tree["parameters/movement/transition_request"] = state

func set_movement_time_scale(value: float) -> void:
	animation_tree["parameters/movement_time_scale/scale"] = value

func play_idle() -> void:
	reset_cheese_reach_pose()
	_set_movement_crossfade(DEFAULT_MOVEMENT_CROSSFADE)
	set_movement_time_scale(1.0)
	animation_tree["parameters/movement/transition_request"] = IDLE_ANIMATION

func play_chicken_dance() -> float:
	var animation_player := _get_animation_player()
	if animation_player == null or not animation_player.has_animation(CHICKEN_DANCE_ANIMATION):
		return 0.0

	_set_movement_crossfade(CELEBRATION_CROSSFADE)
	set_movement_time_scale(1.0)
	animation_tree["parameters/movement/transition_request"] = CHICKEN_DANCE_ANIMATION
	return animation_player.get_animation(CHICKEN_DANCE_ANIMATION).length

func begin_cheese_reach_pose(cheese_world_position: Vector3, blend_duration: float = 0.4) -> void:
	reset_cheese_reach_pose()
	var skeleton := _get_skeleton()
	if skeleton == null:
		return

	skeleton.force_update_all_bone_transforms()
	for bone_name in CHEESE_REACH_BONES:
		var bone_index := skeleton.find_bone(bone_name)
		if bone_index >= 0:
			cheese_reach_base_rotations[bone_index] = skeleton.get_bone_pose_rotation(bone_index)

	var left_arm_target := _arm_target_for_side(skeleton, "mixamorig_LeftArm", cheese_world_position)
	var right_arm_target := _arm_target_for_side(skeleton, "mixamorig_RightArm", cheese_world_position)
	_point_bone_toward(skeleton, "mixamorig_LeftArm", "mixamorig_LeftForeArm", left_arm_target)
	_point_bone_toward(skeleton, "mixamorig_LeftForeArm", "mixamorig_LeftHand", left_arm_target)
	_point_bone_toward(skeleton, "mixamorig_RightArm", "mixamorig_RightForeArm", right_arm_target)
	_point_bone_toward(skeleton, "mixamorig_RightForeArm", "mixamorig_RightHand", right_arm_target)
	_tilt_bone_in_world(skeleton, "mixamorig_Neck", -12.0)
	_tilt_bone_in_world(skeleton, "mixamorig_Head", -24.0)

	for bone_index in cheese_reach_base_rotations:
		cheese_reach_target_rotations[bone_index] = skeleton.get_bone_pose_rotation(bone_index)
		skeleton.set_bone_pose_rotation(bone_index, cheese_reach_base_rotations[bone_index])
	skeleton.force_update_all_bone_transforms()
	cheese_reach_modifier.set_target_rotations(cheese_reach_target_rotations)

	if blend_duration <= 0.0:
		_apply_cheese_reach_weight(1.0)
		return
	cheese_reach_tween = create_tween()
	cheese_reach_tween.set_trans(Tween.TRANS_SINE)
	cheese_reach_tween.set_ease(Tween.EASE_IN_OUT)
	cheese_reach_tween.tween_method(_apply_cheese_reach_weight, 0.0, 1.0, blend_duration)

func end_cheese_reach_pose(blend_duration: float = 0.15) -> void:
	if cheese_reach_base_rotations.is_empty():
		return
	if cheese_reach_tween != null and cheese_reach_tween.is_valid():
		cheese_reach_tween.kill()
	if blend_duration > 0.0:
		cheese_reach_tween = create_tween()
		cheese_reach_tween.set_trans(Tween.TRANS_SINE)
		cheese_reach_tween.set_ease(Tween.EASE_IN_OUT)
		cheese_reach_tween.tween_method(_apply_cheese_reach_weight, cheese_reach_weight, 0.0, blend_duration)
		await cheese_reach_tween.finished
	reset_cheese_reach_pose()

func reset_cheese_reach_pose() -> void:
	if cheese_reach_tween != null and cheese_reach_tween.is_valid():
		cheese_reach_tween.kill()
	cheese_reach_tween = null
	if cheese_reach_modifier != null:
		cheese_reach_modifier.clear_target_rotations()
	cheese_reach_base_rotations.clear()
	cheese_reach_target_rotations.clear()
	cheese_reach_weight = 0.0

func _apply_cheese_reach_weight(weight: float) -> void:
	var skeleton := _get_skeleton()
	if skeleton == null:
		return
	cheese_reach_weight = clampf(weight, 0.0, 1.0)
	cheese_reach_modifier.influence = cheese_reach_weight

func _arm_target_for_side(skeleton: Skeleton3D, arm_name: String, cheese_world_position: Vector3) -> Vector3:
	var arm_index := skeleton.find_bone(arm_name)
	if arm_index < 0:
		return cheese_world_position
	var shoulder_world_position := skeleton.to_global(skeleton.get_bone_global_pose(arm_index).origin)
	var side_direction := shoulder_world_position - cheese_world_position
	side_direction.y = 0.0
	if side_direction.length_squared() > 0.0:
		side_direction = side_direction.normalized()
	return cheese_world_position + side_direction * 0.1

func _point_bone_toward(skeleton: Skeleton3D, bone_name: String, child_name: String, world_target: Vector3) -> void:
	var bone_index := skeleton.find_bone(bone_name)
	var child_index := skeleton.find_bone(child_name)
	if bone_index < 0 or child_index < 0:
		return
	var bone_global_pose := skeleton.get_bone_global_pose(bone_index)
	var current_direction := skeleton.get_bone_global_pose(child_index).origin - bone_global_pose.origin
	var desired_direction := skeleton.to_local(world_target) - bone_global_pose.origin
	if current_direction.length_squared() == 0.0 or desired_direction.length_squared() == 0.0:
		return
	var rotation_delta := Quaternion(current_direction.normalized(), desired_direction.normalized())
	var target_global_pose := Transform3D(Basis(rotation_delta) * bone_global_pose.basis, bone_global_pose.origin)
	var parent_index := skeleton.get_bone_parent(bone_index)
	var target_local_pose := target_global_pose
	if parent_index >= 0:
		target_local_pose = skeleton.get_bone_global_pose(parent_index).affine_inverse() * target_global_pose
	skeleton.set_bone_pose_rotation(bone_index, target_local_pose.basis.get_rotation_quaternion())
	skeleton.force_update_all_bone_transforms()

func _tilt_bone_in_world(skeleton: Skeleton3D, bone_name: String, angle_degrees: float) -> void:
	var bone_index := skeleton.find_bone(bone_name)
	if bone_index < 0:
		return
	var model_right_world := global_transform.basis.x.normalized()
	var tilt_axis := (skeleton.global_transform.basis.inverse() * model_right_world).normalized()
	var bone_global_pose := skeleton.get_bone_global_pose(bone_index)
	var tilt := Basis(Quaternion(tilt_axis, deg_to_rad(angle_degrees)))
	var target_global_pose := Transform3D(tilt * bone_global_pose.basis, bone_global_pose.origin)
	var parent_index := skeleton.get_bone_parent(bone_index)
	var target_local_pose := target_global_pose
	if parent_index >= 0:
		target_local_pose = skeleton.get_bone_global_pose(parent_index).affine_inverse() * target_global_pose
	skeleton.set_bone_pose_rotation(bone_index, target_local_pose.basis.get_rotation_quaternion())
	skeleton.force_update_all_bone_transforms()

func _set_movement_crossfade(duration: float) -> void:
	if animation_tree == null or animation_tree.tree_root == null:
		return
	var movement_transition := animation_tree.tree_root.get_node("movement") as AnimationNodeTransition
	if movement_transition != null:
		movement_transition.xfade_time = duration

func set_push_start_trim_offset(value: float) -> void:
	var push_start_node: AnimationNodeAnimation = animation_tree.tree_root.get_node("push_start") as AnimationNodeAnimation
	if push_start_node == null:
		return

	push_start_node.use_custom_timeline = true
	push_start_node.start_offset = maxf(value, 0.0)
	pushing_uniform_pose_source_animation = push_start_node.animation
	pushing_uniform_pose_source_time = _get_animation_node_end_time(push_start_node)

func set_pushing_playback(trim_offset: float, should_loop: bool) -> void:
	var pushing_node: AnimationNodeAnimation = animation_tree.tree_root.get_node("pushing") as AnimationNodeAnimation
	if pushing_node == null:
		return

	if make_pushing_upper_body_pose_uniform:
		_make_animation_upper_body_pose_uniform(&"pushing", true)

	pushing_node.use_custom_timeline = true
	pushing_node.start_offset = maxf(trim_offset, 0.0)
	pushing_node.loop_mode = 1 if should_loop else 0

func set_push_end_trim_offset(value: float) -> void:
	var push_end_node: AnimationNodeAnimation = animation_tree.tree_root.get_node("push_end") as AnimationNodeAnimation
	if push_end_node == null:
		return

	if make_push_end_upper_body_pose_uniform:
		push_end_node.animation = _get_uniform_push_end_animation(push_end_node.animation)

	push_end_node.use_custom_timeline = true
	push_end_node.start_offset = maxf(value, 0.0)

func _remove_pushing_root_motion() -> void:
	var animation_player := _get_animation_player()
	if animation_player == null or not animation_player.has_animation(&"pushing"):
		return

	var pushing_animation := animation_player.get_animation(&"pushing")
	if pushing_animation == null:
		return

	for track_index in pushing_animation.get_track_count():
		var track_path := str(pushing_animation.track_get_path(track_index))
		if pushing_animation.track_get_type(track_index) != Animation.TYPE_POSITION_3D:
			continue

		if not track_path.ends_with(":mixamorig_Hips"):
			continue

		var key_count := pushing_animation.track_get_key_count(track_index)
		if key_count == 0:
			return

		var root_position: Vector3 = pushing_animation.track_get_key_value(track_index, 0)
		for key_index in key_count:
			pushing_animation.track_set_key_value(track_index, key_index, root_position)
		return

func _make_animation_upper_body_pose_uniform(animation_name: StringName, should_apply_backstep: bool) -> void:
	var animation_player := _get_animation_player()
	if animation_player == null or not animation_player.has_animation(animation_name):
		return

	var target_animation := animation_player.get_animation(animation_name)
	if target_animation == null:
		return

	var source_animation := target_animation
	if animation_player.has_animation(pushing_uniform_pose_source_animation):
		source_animation = animation_player.get_animation(pushing_uniform_pose_source_animation)

	var sample_time := clampf(pushing_uniform_pose_source_time, 0.0, source_animation.length)
	for track_index in target_animation.get_track_count():
		var track_path := str(target_animation.track_get_path(track_index))
		var track_type := target_animation.track_get_type(track_index)

		var key_count := target_animation.track_get_key_count(track_index)
		if key_count == 0:
			continue

		if track_type == Animation.TYPE_ROTATION_3D and _is_uniform_rotation_track(track_path):
			var source_track_index := _find_matching_track(source_animation, target_animation.track_get_path(track_index), Animation.TYPE_ROTATION_3D)
			var pose_rotation := _sample_track_rotation(source_animation, source_track_index, sample_time)
			if source_track_index < 0:
				pose_rotation = _sample_track_rotation(target_animation, track_index, sample_time)

			for key_index in key_count:
				target_animation.track_set_key_value(track_index, key_index, pose_rotation)

		if track_type == Animation.TYPE_POSITION_3D and _is_uniform_position_track(track_path):
			var source_track_index := _find_matching_track(source_animation, target_animation.track_get_path(track_index), Animation.TYPE_POSITION_3D)
			var pose_position := _sample_track_position(source_animation, source_track_index, sample_time)
			if source_track_index < 0:
				pose_position = _sample_track_position(target_animation, track_index, sample_time)
			if should_apply_backstep and track_path.ends_with(":mixamorig_Hips"):
				pose_position.y -= pushing_pose_backstep_distance

			for key_index in key_count:
				target_animation.track_set_key_value(track_index, key_index, pose_position)

func _get_uniform_push_end_animation(source_animation_name: StringName) -> StringName:
	var animation_player := _get_animation_player()
	if animation_player == null or not animation_player.has_animation(source_animation_name):
		return source_animation_name

	if not animation_player.has_animation(PUSH_END_SAFE_ANIMATION):
		var source_animation := animation_player.get_animation(source_animation_name)
		if source_animation == null:
			return source_animation_name

		var animation_library := animation_player.get_animation_library(&"")
		if animation_library == null:
			return source_animation_name

		animation_library.add_animation(PUSH_END_SAFE_ANIMATION, source_animation.duplicate(true))

	_make_animation_upper_body_pose_uniform(PUSH_END_SAFE_ANIMATION, false)
	return PUSH_END_SAFE_ANIMATION

func _is_uniform_rotation_track(track_path: String) -> bool:
	for bone_name in PUSHING_UNIFORM_ROTATION_BONES:
		if track_path.ends_with(":" + bone_name):
			return true

	return false

func _is_uniform_position_track(track_path: String) -> bool:
	for bone_name in PUSHING_UNIFORM_POSITION_BONES:
		if track_path.ends_with(":" + bone_name):
			return true

	return false

func _find_matching_track(animation: Animation, track_path: NodePath, track_type: Animation.TrackType) -> int:
	for track_index in animation.get_track_count():
		if animation.track_get_type(track_index) == track_type and animation.track_get_path(track_index) == track_path:
			return track_index

	return -1

func _get_animation_node_end_time(animation_node: AnimationNodeAnimation) -> float:
	if animation_node.play_mode == AnimationNodeAnimation.PLAY_MODE_BACKWARD:
		return animation_node.start_offset

	if animation_node.use_custom_timeline:
		return animation_node.start_offset + animation_node.timeline_length

	var animation_player := _get_animation_player()
	if animation_player == null or not animation_player.has_animation(animation_node.animation):
		return animation_node.start_offset

	var animation := animation_player.get_animation(animation_node.animation)
	return animation.length

func _sample_track_rotation(animation: Animation, track_index: int, sample_time: float) -> Quaternion:
	if track_index < 0:
		return Quaternion.IDENTITY

	var key_count := animation.track_get_key_count(track_index)
	if key_count == 0:
		return Quaternion.IDENTITY

	var previous_key_index := 0
	var next_key_index := key_count - 1
	for key_index in key_count:
		var key_time := animation.track_get_key_time(track_index, key_index)
		if key_time <= sample_time:
			previous_key_index = key_index
		if key_time >= sample_time:
			next_key_index = key_index
			break

	var previous_time := animation.track_get_key_time(track_index, previous_key_index)
	var next_time := animation.track_get_key_time(track_index, next_key_index)
	var previous_rotation: Quaternion = animation.track_get_key_value(track_index, previous_key_index)
	var next_rotation: Quaternion = animation.track_get_key_value(track_index, next_key_index)
	if is_equal_approx(previous_time, next_time):
		return previous_rotation

	var blend := inverse_lerp(previous_time, next_time, sample_time)
	return previous_rotation.slerp(next_rotation, blend)

func _sample_track_position(animation: Animation, track_index: int, sample_time: float) -> Vector3:
	if track_index < 0:
		return Vector3.ZERO

	var key_count := animation.track_get_key_count(track_index)
	if key_count == 0:
		return Vector3.ZERO

	var previous_key_index := 0
	var next_key_index := key_count - 1
	for key_index in key_count:
		var key_time := animation.track_get_key_time(track_index, key_index)
		if key_time <= sample_time:
			previous_key_index = key_index
		if key_time >= sample_time:
			next_key_index = key_index
			break

	var previous_time := animation.track_get_key_time(track_index, previous_key_index)
	var next_time := animation.track_get_key_time(track_index, next_key_index)
	var previous_position: Vector3 = animation.track_get_key_value(track_index, previous_key_index)
	var next_position: Vector3 = animation.track_get_key_value(track_index, next_key_index)
	if is_equal_approx(previous_time, next_time):
		return previous_position

	var blend := inverse_lerp(previous_time, next_time, sample_time)
	return previous_position.lerp(next_position, blend)

func _get_animation_player() -> AnimationPlayer:
	if animation_tree == null:
		return null

	return animation_tree.get_node_or_null(animation_tree.anim_player) as AnimationPlayer

func _get_skeleton() -> Skeleton3D:
	return get_node_or_null("rat-albert-animated/Armature/Skeleton3D") as Skeleton3D
