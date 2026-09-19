extends Node

var target_tiles: Array[Node] = []
var is_level_completed := false

func _ready() -> void:
	target_tiles = get_tree().get_nodes_in_group("target_tile")
	for target_tile in target_tiles:
		if target_tile.has_signal("block_entered_target"):
			target_tile.block_entered_target.connect(_on_target_tile_changed.unbind(1))
		if target_tile.has_signal("block_exited_target"):
			target_tile.block_exited_target.connect(_on_target_tile_changed.unbind(1))

	_check_level_completed()

func _on_target_tile_changed() -> void:
	_check_level_completed()

func _check_level_completed() -> void:
	if target_tiles.is_empty():
		is_level_completed = false
		return

	var all_targets_filled := true
	for target_tile in target_tiles:
		if not is_instance_valid(target_tile) or not target_tile.has_method("has_block_on_target") or not target_tile.has_block_on_target():
			all_targets_filled = false
			break

	if all_targets_filled and not is_level_completed:
		is_level_completed = true
		Log.print("level completed")
	elif not all_targets_filled:
		is_level_completed = false
