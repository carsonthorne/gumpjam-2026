extends CanvasLayer

const Reader = preload("res://addons/sokoban_layout/map_reader.gd")
const Builder = preload("res://addons/sokoban_layout/layout_builder.gd")

@export var level_layout_path := NodePath("../LevelLayout")
@export var player_path := NodePath("../Player")
@export var level_goal_path := NodePath("../LevelGoal")
@export_dir var collections_directory := "res://levels"

var level_layout: Node3D
var player: CharacterBody3D
var level_goal: Node
var collection_select: OptionButton
var level_select: OptionButton
var status_label: Label
var panel: PanelContainer
var content: VBoxContainer
var toggle_button: Button
var collections: Array[String] = []
var previous_mouse_mode := Input.MOUSE_MODE_VISIBLE

func _ready() -> void:
	level_layout = get_node_or_null(level_layout_path) as Node3D
	player = get_node_or_null(player_path) as CharacterBody3D
	level_goal = get_node_or_null(level_goal_path)
	_build_ui()
	_load_collections()
	_sync_with_layout()
	_update_level_options()

func _build_ui() -> void:
	layer = 20

	var root := Control.new()
	root.name = "Root"
	root.anchor_left = 1.0
	root.anchor_right = 1.0
	root.anchor_top = 0.0
	root.anchor_bottom = 0.0
	root.offset_left = -300.0
	root.offset_right = -12.0
	root.offset_top = 12.0
	root.offset_bottom = 220.0
	add_child(root)

	var stack := VBoxContainer.new()
	stack.name = "Stack"
	stack.anchor_left = 0.0
	stack.anchor_right = 1.0
	stack.anchor_top = 0.0
	stack.anchor_bottom = 0.0
	stack.offset_bottom = 208.0
	stack.alignment = BoxContainer.ALIGNMENT_BEGIN
	root.add_child(stack)

	toggle_button = Button.new()
	toggle_button.text = "Levels"
	toggle_button.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	toggle_button.pressed.connect(_toggle_menu)
	stack.add_child(toggle_button)

	panel = PanelContainer.new()
	panel.visible = false
	stack.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	margin.add_child(content)

	var title := Label.new()
	title.text = "Dev level loader"
	content.add_child(title)

	var collection_label := Label.new()
	collection_label.text = "Collection"
	content.add_child(collection_label)

	collection_select = OptionButton.new()
	collection_select.item_selected.connect(_on_collection_selected)
	content.add_child(collection_select)

	var level_label := Label.new()
	level_label.text = "Level"
	content.add_child(level_label)

	level_select = OptionButton.new()
	content.add_child(level_select)

	var load_button := Button.new()
	load_button.text = "Load Level"
	load_button.pressed.connect(_load_selected_level)
	content.add_child(load_button)

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.text = ""
	content.add_child(status_label)

func _load_collections() -> void:
	collections.clear()
	collection_select.clear()

	var dir := DirAccess.open(collections_directory)
	if dir == null:
		status_label.text = "Cannot open %s" % collections_directory
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while not file_name.is_empty():
		if not dir.current_is_dir() and file_name.get_extension().to_lower() in ["txt", "sok"]:
			collections.append(collections_directory.path_join(file_name))
		file_name = dir.get_next()
	dir.list_dir_end()

	collections.sort()
	for collection in collections:
		collection_select.add_item(collection.get_file())
		collection_select.set_item_metadata(collection_select.get_item_count() - 1, collection)

func _sync_with_layout() -> void:
	if level_layout == null or collection_select.get_item_count() == 0:
		return

	var current_collection: String = level_layout.get("collection")
	for index in collection_select.get_item_count():
		if collection_select.get_item_metadata(index) == current_collection:
			collection_select.select(index)
			break

func _on_collection_selected(_index: int) -> void:
	_update_level_options()

func _update_level_options() -> void:
	level_select.clear()
	var collection := _selected_collection()
	if collection.is_empty():
		return

	var level_count := _count_levels(collection)
	for level_number in range(1, level_count + 1):
		level_select.add_item(str(level_number))
		level_select.set_item_metadata(level_select.get_item_count() - 1, level_number)

	if level_layout != null:
		var current_level: int = level_layout.get("level_number")
		if current_level >= 1 and current_level <= level_count:
			level_select.select(current_level - 1)

	status_label.text = "%d levels available" % level_count

func _selected_collection() -> String:
	var selected := collection_select.selected
	if selected < 0:
		return ""
	return collection_select.get_item_metadata(selected)

func _selected_level_number() -> int:
	var selected := level_select.selected
	if selected < 0:
		return 1
	return level_select.get_item_metadata(selected)

func _count_levels(path: String) -> int:
	if not FileAccess.file_exists(path):
		return 0

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return 0

	var count := 0
	var has_rows := false
	for line in file.get_as_text().replace("\r", "").split("\n"):
		if line.begins_with(";"):
			continue
		if line.strip_edges().is_empty():
			if has_rows:
				count += 1
				has_rows = false
		else:
			has_rows = true

	if has_rows:
		count += 1
	return count

func _load_selected_level() -> void:
	if level_layout == null or player == null:
		status_label.text = "Missing LevelLayout or Player."
		return

	var collection := _selected_collection()
	var level_number := _selected_level_number()
	var map := Reader.read_level(collection, level_number)
	if map.has("error"):
		status_label.text = map.error
		return

	var previous := level_layout.get_node_or_null("Generated")
	if previous != null:
		level_layout.remove_child(previous)
		previous.queue_free()

	var generated := Builder.build(map)
	level_layout.add_child(generated)
	level_layout.set("collection", collection)
	level_layout.set("level_number", level_number)

	_reset_player(level_layout.to_global(Builder.cell_position(map.player, map)))

	if level_goal != null and level_goal.has_method("refresh_targets"):
		level_goal.refresh_targets()

	status_label.text = "Loaded %s level %d" % [collection.get_file(), level_number]

func _reset_player(position: Vector3) -> void:
	player.global_position = position
	player.velocity = Vector3.ZERO

	if player.has_method("set_push_ready"):
		player.set_push_ready(false)

	player.set("push_follow_direction", Vector3.ZERO)
	player.set("push_follow_contact_time_left", 0.0)
	player.set("push_follow_distance_left", 0.0)
	player.set("push_follow_source", null)
	player.set("brace_release_backstep_direction", Vector3.ZERO)
	player.set("brace_release_backstep_distance_left", 0.0)

func _toggle_menu() -> void:
	panel.visible = not panel.visible
	toggle_button.text = "Close" if panel.visible else "Levels"

	if panel.visible:
		previous_mouse_mode = Input.mouse_mode
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	elif previous_mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
