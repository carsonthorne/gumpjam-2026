@tool
extends EditorPlugin

const Layout = preload("level_layout.gd")
const Reader = preload("map_reader.gd")
const Builder = preload("layout_builder.gd")
const Inspector = preload("inspector.gd")
var inspector: EditorInspectorPlugin

func _enter_tree() -> void:
	add_custom_type("LevelLayout", "Node3D", Layout, get_editor_interface().get_base_control().get_theme_icon("GridMap", "EditorIcons"))
	inspector = Inspector.new()
	inspector.build_level = _build_level
	add_inspector_plugin(inspector)

func _exit_tree() -> void:
	remove_inspector_plugin(inspector)
	remove_custom_type("LevelLayout")

func _build_level(layout: Node3D, summary: Label) -> void:
	var map := Reader.read_level(layout.collection, layout.level_number)
	if map.has("error"):
		summary.text = map.error
		return
	var scene := get_editor_interface().get_edited_scene_root()
	var player := layout.get_node_or_null(layout.player_path) as CharacterBody3D
	if scene == null or player == null or not scene.is_ancestor_of(layout) or not scene.is_ancestor_of(player):
		summary.text = "Layout and Player Path must belong to the open scene."
		return
	if not layout.global_transform.basis.is_equal_approx(Basis.IDENTITY) or not is_zero_approx(layout.global_position.y):
		summary.text = "Keep LevelLayout unrotated, unscaled, and at ground height (Y = 0)."
		return
	if map.width > 40 or map.height > 40 or absf(layout.global_position.x) > 1 or absf(layout.global_position.z) > 1:
		summary.text = "This lab supports boards up to 40 × 40, with LevelLayout X/Z within one unit of the origin."
		return
	var generated := Builder.build(map)
	var previous := layout.get_node_or_null("Generated")
	var history := get_undo_redo()
	history.create_action("Build Sokoban Level", UndoRedo.MERGE_DISABLE, scene)
	history.add_undo_method(layout, "remove_child", generated)
	if previous != null:
		history.add_do_method(layout, "remove_child", previous)
		history.add_undo_method(layout, "add_child", previous)
		history.add_undo_method(Builder, "set_owners", previous, scene)
		history.add_undo_reference(previous)
	history.add_do_method(layout, "add_child", generated)
	history.add_do_method(Builder, "set_owners", generated, scene)
	history.add_do_property(player, "global_position", layout.to_global(Builder.cell_position(map.player, map)))
	history.add_do_reference(generated)
	history.add_undo_property(player, "global_position", player.global_position)
	history.commit_action()
	summary.text = "Built level %d: %d × %d, %d crates. Save the scene to keep it." % [layout.level_number, map.width, map.height, map.crates]
