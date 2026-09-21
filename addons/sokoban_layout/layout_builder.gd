@tool
extends RefCounted

const WALL = preload("res://scenes/immovable_block.tscn")
const CRATE = preload("res://scenes/push_block.tscn")
const TARGET = preload("res://scenes/target_tile.tscn")
const FENCE = preload("res://scenes/chain_link_fence.tscn")

static func cell_position(cell: Vector2i, map: Dictionary) -> Vector3:
	return Vector3(cell.x - floori(map.width / 2.0), 0, cell.y - floori(map.height / 2.0))

static func build(map: Dictionary) -> Node3D:
	var root := Node3D.new()
	root.name = "Generated"
	var walls := _folder(root, "Walls")
	var crates := _folder(root, "Crates")
	var targets := _folder(root, "Targets")
	var cage := _folder(root, "RatCage")
	for y in map.rows.size():
		for x in map.rows[y].length():
			var tile: String = map.rows[y][x]
			var position := cell_position(Vector2i(x, y), map)
			var suffix := "%d_%d" % [x, y]
			if tile == "#":
				_instance(WALL, walls, "Wall_" + suffix, position)
			if tile in ".*+":
				_instance(TARGET, targets, "Target_" + suffix, position)
			if tile in "$*":
				var crate := _instance(CRATE, crates, "Crate_" + suffix, position)
				var index := crates.get_child_count() - 1
				crate.set("block_letter", String.chr(65 + index % 26))
				crate.set("block_color", Color.from_hsv(fmod(index * 0.16, 1.0), 0.8, 0.8))
	var center := cell_position(Vector2i.ZERO, map) + Vector3((map.width - 1) / 2.0, 0, (map.height - 1) / 2.0)
	var half_x := ceilf((map.width + 2) / 4.0) * 2.0
	var half_z := ceilf((map.height + 2) / 4.0) * 2.0
	for height in [0.0, 3.0]:
		for side in [-1, 1]:
			for segment in int(half_x / 2):
				_instance(FENCE, cage, "Fence", center + Vector3(-half_x + 2 + segment * 4, height, side * half_z))
			for segment in int(half_z / 2):
				var fence := _instance(FENCE, cage, "Fence", center + Vector3(side * half_x, height, -half_z + 2 + segment * 4))
				fence.rotation.y = PI / 2
	return root

static func _folder(parent: Node, label: String) -> Node3D:
	var node := Node3D.new()
	node.name = label
	parent.add_child(node)
	return node

static func _instance(scene: PackedScene, parent: Node, label: String, position: Vector3) -> Node3D:
	var edit_state := PackedScene.GEN_EDIT_STATE_INSTANCE if Engine.is_editor_hint() else PackedScene.GEN_EDIT_STATE_DISABLED
	var node := scene.instantiate(edit_state) as Node3D
	node.name = label
	parent.add_child(node, true)
	node.position = position
	return node

static func set_owners(node: Node, scene: Node) -> void:
	node.owner = scene
	# PackedScene internals retain their original ownership and instance link.
	if not node.scene_file_path.is_empty():
		return
	for child in node.get_children():
		set_owners(child, scene)
