extends Node

const Reader = preload("res://addons/sokoban_layout/map_reader.gd")
const Builder = preload("res://addons/sokoban_layout/layout_builder.gd")
const START_MENU_SCENE := "res://scenes/start_menu.tscn"

@onready var level_layout: Node3D = $LevelLayout
@onready var player: CharacterBody3D = $Player
@onready var level_goal: Node = $LevelGoal
@onready var level_complete_popup: CanvasLayer = $LevelCompletePopup
@onready var next_level_button: Button = $LevelCompletePopup/Overlay/Panel/Margin/Content/Buttons/NextLevelButton
@onready var main_menu_button: Button = $LevelCompletePopup/Overlay/Panel/Margin/Content/Buttons/MainMenuButton
@onready var pause_menu: CanvasLayer = $PauseMenu
@onready var pause_button: Button = $PauseMenu/PauseButton
@onready var pause_overlay: Control = $PauseMenu/Overlay
@onready var resume_button: Button = $PauseMenu/Overlay/Panel/Margin/Content/ResumeButton
@onready var restart_button: Button = $PauseMenu/Overlay/Panel/Margin/Content/RestartButton
@onready var pause_level_select_button: Button = $PauseMenu/Overlay/Panel/Margin/Content/LevelSelectButton
@onready var pause_main_menu_button: Button = $PauseMenu/Overlay/Panel/Margin/Content/MainMenuButton

var current_collection := ""
var current_level_number := 1

func _ready() -> void:
	current_collection = level_layout.get("collection")
	current_level_number = level_layout.get("level_number")
	if current_collection.is_empty():
		current_collection = LevelSelection.collection

	level_complete_popup.visible = false
	pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_overlay.visible = false
	if level_goal.has_signal("level_completed"):
		level_goal.connect("level_completed", _show_level_completed_popup)
	next_level_button.pressed.connect(_load_next_level)
	main_menu_button.pressed.connect(_return_to_main_menu)
	pause_button.pressed.connect(_show_pause_menu)
	resume_button.pressed.connect(_resume_game)
	restart_button.pressed.connect(_restart_level)
	pause_level_select_button.pressed.connect(_return_to_level_select)
	pause_main_menu_button.pressed.connect(_return_to_main_menu)

	if LevelSelection.has_selection:
		load_level(LevelSelection.collection, LevelSelection.level_number)

func load_level(collection: String, level_number: int) -> void:
	var map := Reader.read_level(collection, level_number)
	if map.has("error"):
		push_error(map.error)
		return

	var previous := level_layout.get_node_or_null("Generated")
	if previous != null:
		level_layout.remove_child(previous)
		previous.queue_free()

	var generated := Builder.build(map)
	level_layout.add_child(generated)
	level_layout.set("collection", collection)
	level_layout.set("level_number", level_number)
	current_collection = collection
	current_level_number = level_number
	LevelSelection.choose(collection, level_number)

	player.global_position = level_layout.to_global(Builder.cell_position(map.player, map))
	player.velocity = Vector3.ZERO
	if player.has_method("set_push_ready"):
		player.set_push_ready(false)

	if level_goal.has_method("refresh_targets"):
		level_goal.refresh_targets()

	level_complete_popup.visible = false
	_resume_game()

func _show_level_completed_popup() -> void:
	_resume_game()
	var level_count := _count_levels(current_collection)
	next_level_button.visible = current_level_number < level_count
	level_complete_popup.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _load_next_level() -> void:
	load_level(current_collection, current_level_number + 1)

func _return_to_main_menu() -> void:
	get_tree().paused = false
	LevelSelection.open_level_select = false
	get_tree().change_scene_to_file(START_MENU_SCENE)

func _show_pause_menu() -> void:
	if level_complete_popup.visible:
		return
	pause_overlay.visible = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _resume_game() -> void:
	pause_overlay.visible = false
	get_tree().paused = false

func _restart_level() -> void:
	_resume_game()
	load_level(current_collection, current_level_number)

func _return_to_level_select() -> void:
	get_tree().paused = false
	LevelSelection.request_level_select()
	get_tree().change_scene_to_file(START_MENU_SCENE)

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
