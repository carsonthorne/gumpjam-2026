extends Control

const MAIN_SCENE := "res://scenes/main.tscn"
const COLLECTIONS_DIRECTORY := "res://levels"

@onready var collection_select: OptionButton = $Shell/Content/LevelSelectPanel/TopBar/CollectionSelect
@onready var level_grid: GridContainer = $Shell/Content/LevelSelectPanel/LevelScroll/LevelGrid
@onready var go_button: Button = $Shell/Content/LevelSelectPanel/GoButton
@onready var detail_label: Label = $Shell/Content/DetailLabel
@onready var main_panel: Control = $Shell/Content/MainPanel
@onready var level_panel: Control = $Shell/Content/LevelSelectPanel
@onready var instructions_panel: Control = $Shell/Content/InstructionsPanel
@onready var level_select_button: Button = $Shell/Content/MainPanel/LevelSelectButton
@onready var instructions_button: Button = $Shell/Content/MainPanel/InstructionsButton
@onready var level_back_button: Button = $Shell/Content/LevelSelectPanel/TopBar/BackButton
@onready var instructions_back_button: Button = $Shell/Content/InstructionsPanel/BackButton

var selected_collection := ""
var selected_level := 0
var selected_level_button: Button = null

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	level_select_button.pressed.connect(_show_level_select)
	instructions_button.pressed.connect(_show_instructions)
	level_back_button.pressed.connect(_show_main)
	instructions_back_button.pressed.connect(_show_main)
	collection_select.item_selected.connect(_on_collection_selected)
	go_button.pressed.connect(_go_to_selected_level)
	_load_collections()
	_show_main()

func _load_collections() -> void:
	collection_select.clear()
	var collections := _collections()
	for collection in collections:
		collection_select.add_item(collection.get_file())
		collection_select.set_item_metadata(collection_select.get_item_count() - 1, collection)

	if collection_select.get_item_count() > 0:
		collection_select.select(0)
		_on_collection_selected(0)

func _collections() -> Array[String]:
	var result: Array[String] = []
	var dir := DirAccess.open(COLLECTIONS_DIRECTORY)
	if dir == null:
		return result

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while not file_name.is_empty():
		if not dir.current_is_dir() and file_name.get_extension().to_lower() in ["txt", "sok"]:
			result.append(COLLECTIONS_DIRECTORY.path_join(file_name))
		file_name = dir.get_next()
	dir.list_dir_end()
	result.sort()
	return result

func _on_collection_selected(index: int) -> void:
	selected_collection = collection_select.get_item_metadata(index)
	selected_level = 0
	selected_level_button = null
	go_button.disabled = true
	_rebuild_level_buttons()

func _rebuild_level_buttons() -> void:
	for child in level_grid.get_children():
		level_grid.remove_child(child)
		child.free()

	var level_count := _count_levels(selected_collection)
	for level_number in range(1, level_count + 1):
		var button := Button.new()
		button.text = str(level_number)
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(56, 38)
		button.pressed.connect(_select_level.bind(level_number, button))
		level_grid.add_child(button)

	detail_label.text = "%s: %d levels" % [selected_collection.get_file(), level_count]

func _select_level(level_number: int, button: Button) -> void:
	if selected_level_button != null and selected_level_button != button:
		selected_level_button.button_pressed = false

	selected_level = level_number
	selected_level_button = button
	selected_level_button.button_pressed = true
	go_button.disabled = false
	detail_label.text = "%s level %d selected" % [selected_collection.get_file(), selected_level]

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

func _go_to_selected_level() -> void:
	if selected_collection.is_empty() or selected_level < 1:
		return

	LevelSelection.choose(selected_collection, selected_level)
	get_tree().change_scene_to_file(MAIN_SCENE)

func _show_main() -> void:
	main_panel.visible = true
	level_panel.visible = false
	instructions_panel.visible = false
	detail_label.text = "Start a puzzle or review the controls."

func _show_level_select() -> void:
	main_panel.visible = false
	level_panel.visible = true
	instructions_panel.visible = false
	if not selected_collection.is_empty():
		detail_label.text = "%s: %d levels" % [selected_collection.get_file(), _count_levels(selected_collection)]

func _show_instructions() -> void:
	main_panel.visible = false
	level_panel.visible = false
	instructions_panel.visible = true
	detail_label.text = "Controls"
