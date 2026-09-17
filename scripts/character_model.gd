extends Node3D
class_name CharacterModel

@export var animation_tree: AnimationTree
@export var remove_pushing_forward_root_motion := true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if remove_pushing_forward_root_motion:
		_remove_pushing_forward_root_motion()


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

func set_pushing_playback(trim_offset: float, should_loop: bool) -> void:
	var pushing_node: AnimationNodeAnimation = animation_tree.tree_root.get_node("pushing") as AnimationNodeAnimation
	if pushing_node == null:
		return

	pushing_node.use_custom_timeline = true
	pushing_node.start_offset = maxf(trim_offset, 0.0)
	pushing_node.loop_mode = 1 if should_loop else 0

func set_pushing_trim_offset(value: float) -> void:
	set_pushing_playback(value, false)

func set_push_end_trim_offset(value: float) -> void:
	var push_end_node: AnimationNodeAnimation = animation_tree.tree_root.get_node("push_end") as AnimationNodeAnimation
	if push_end_node == null:
		return

	push_end_node.use_custom_timeline = true
	push_end_node.start_offset = maxf(value, 0.0)

func _remove_pushing_forward_root_motion() -> void:
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
			var position: Vector3 = pushing_animation.track_get_key_value(track_index, key_index)
			position.y = root_position.y
			pushing_animation.track_set_key_value(track_index, key_index, position)
		return

func _get_animation_player() -> AnimationPlayer:
	if animation_tree == null:
		return null

	return animation_tree.get_node_or_null(animation_tree.anim_player) as AnimationPlayer
