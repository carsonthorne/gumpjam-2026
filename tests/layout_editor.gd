extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	for i in 60:
		await process_frame
	EditorInterface.open_scene_from_path("res://scenes/main.tscn")
	for i in 30:
		await process_frame
	var scene := EditorInterface.get_edited_scene_root()
	assert(scene != null)
	var plugin := _find_plugin(root)
	assert(plugin != null)
	var layout := scene.get_node("LevelLayout")
	var previous := layout.get_node("Generated")
	var original_position: Vector3 = scene.get_node("Player").global_position
	var summary := Label.new()
	layout.collection = "res://levels/tutorials.txt"
	layout.level_number = 2
	plugin._build_level(layout, summary)
	print(summary.text)
	var generated := layout.get_node("Generated")
	assert(generated != previous)
	assert(generated.get_node("Crates").get_child_count() == 2)
	assert(generated.owner == scene)
	var manager: EditorUndoRedoManager = plugin.get_undo_redo()
	var history := manager.get_history_undo_redo(manager.get_object_history_id(scene))
	history.undo()
	assert(layout.get_node("Generated") == previous)
	assert(previous.owner == scene)
	assert(scene.get_node("Player").global_position == original_position)
	history.redo()
	assert(layout.get_node("Generated") == generated)
	assert(generated.owner == scene)
	plugin._build_level(layout, summary)
	assert(layout.get_child_count() == 1)
	var packed := PackedScene.new()
	assert(packed.pack(scene) == OK)
	assert(ResourceSaver.save(packed, "user://layout_roundtrip.tscn") == OK)
	var restored: Node = load("user://layout_roundtrip.tscn").instantiate()
	var crate := restored.get_node("LevelLayout/Generated/Crates").get_child(0)
	assert(crate.scene_file_path == "res://scenes/push_block.tscn")
	assert(restored.get_node("LevelLayout/Generated/Targets").get_child_count() == 2)
	restored.free()
	layout.level_number = 999
	var before := layout.get_node("Generated")
	plugin._build_level(layout, summary)
	assert(layout.get_node("Generated") == before)
	print("PASS: actual editor plugin build, undo/redo, repeated generation, save/reopen, invalid input preservation")
	summary.free()
	quit()

func _find_plugin(node: Node) -> Node:
	if node.get_script() != null and node.get_script().resource_path == "res://addons/sokoban_layout/plugin.gd":
		return node
	for child in node.get_children():
		var found := _find_plugin(child)
		if found != null:
			return found
	return null
