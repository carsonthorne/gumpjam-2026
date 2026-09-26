extends SkeletonModifier3D
class_name CheeseReachModifier

var target_rotations := {}

func set_target_rotations(rotations: Dictionary) -> void:
	target_rotations = rotations.duplicate()
	active = not target_rotations.is_empty()

func clear_target_rotations() -> void:
	active = false
	influence = 0.0
	target_rotations.clear()

func _process_modification_with_delta(_delta: float) -> void:
	var skeleton := get_skeleton()
	if skeleton == null:
		return
	for bone_index in target_rotations:
		skeleton.set_bone_pose_rotation(bone_index, target_rotations[bone_index])
