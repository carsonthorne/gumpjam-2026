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

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if remove_pushing_root_motion:
		_remove_pushing_root_motion()


func on_state_machine_animation_state_changed(state: String) -> void:
	set_movement_time_scale(1.0)
	animation_tree["parameters/movement/transition_request"] = state

func set_movement_time_scale(value: float) -> void:
	animation_tree["parameters/movement_time_scale/scale"] = value

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

func set_pushing_trim_offset(value: float) -> void:
	set_pushing_playback(value, false)

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
