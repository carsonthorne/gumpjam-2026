extends Node

const Reader = preload("res://addons/sokoban_layout/map_reader.gd")
const Builder = preload("res://addons/sokoban_layout/layout_builder.gd")
const START_MENU_SCENE := "res://scenes/start_menu.tscn"
const MAX_LEADERBOARD_SCORE := 1000000000

@export var leaderboard_player_name := "Player"

@onready var level_layout: Node3D = $LevelLayout
@onready var player: CharacterBody3D = $Player
@onready var level_goal: Node = $LevelGoal
@onready var level_complete_popup: CanvasLayer = $LevelCompletePopup
@onready var pause_menu: CanvasLayer = $PauseMenu
@onready var pause_button: Button = $PauseMenu/PauseButton
@onready var pause_overlay: Control = $PauseMenu/Overlay
@onready var pause_level_info_label: Label = $PauseMenu/Overlay/Panel/Margin/Content/LevelInfoLabel
@onready var resume_button: Button = $PauseMenu/Overlay/Panel/Margin/Content/ResumeButton
@onready var restart_button: Button = $PauseMenu/Overlay/Panel/Margin/Content/RestartButton
@onready var pause_level_select_button: Button = $PauseMenu/Overlay/Panel/Margin/Content/LevelSelectButton
@onready var pause_main_menu_button: Button = $PauseMenu/Overlay/Panel/Margin/Content/MainMenuButton
@onready var score_hud: CanvasLayer = $ScoreHUD
@onready var leaderboard_client: Node = $CloudflareLeaderboardClient

var current_collection := ""
var current_level_number := 1
var current_leaderboard_score := {}
var leaderboard_score_saved := false
var leaderboard_save_pending := false

func _ready() -> void:
	current_collection = level_layout.get("collection")
	current_level_number = level_layout.get("level_number")
	if current_collection.is_empty():
		current_collection = LevelSelection.collection

	level_complete_popup.visible = false
	pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	level_complete_popup.process_mode = Node.PROCESS_MODE_ALWAYS
	leaderboard_client.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_overlay.visible = false
	if level_goal.has_signal("level_completed"):
		level_goal.connect("level_completed", _show_level_completed_popup)
	level_complete_popup.next_requested.connect(_load_next_level)
	level_complete_popup.restart_requested.connect(_restart_level)
	level_complete_popup.main_menu_requested.connect(_return_to_main_menu)
	pause_menu.connect("pause_requested", _show_pause_menu)
	pause_menu.connect("resume_requested", _resume_game)
	pause_button.pressed.connect(_show_pause_menu)
	resume_button.pressed.connect(_resume_game)
	restart_button.pressed.connect(_restart_level)
	pause_level_select_button.pressed.connect(_return_to_level_select)
	pause_main_menu_button.pressed.connect(_return_to_main_menu)
	player.push_started.connect(_record_move)
	leaderboard_client.scores_loaded.connect(_on_leaderboard_scores_loaded)
	leaderboard_client.score_submitted.connect(_on_leaderboard_score_submitted)
	leaderboard_client.request_failed.connect(_on_leaderboard_request_failed)

	if LevelSelection.has_selection:
		load_level(LevelSelection.collection, LevelSelection.level_number)
	else:
		score_hud.reset()

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
	score_hud.reset()
	current_leaderboard_score = {}
	leaderboard_score_saved = false
	leaderboard_save_pending = false
	_resume_game()

func _show_level_completed_popup() -> void:
	_resume_game()
	score_hud.stop()
	get_tree().paused = true
	pause_button.visible = false
	current_leaderboard_score = _current_score_payload()
	leaderboard_score_saved = false
	leaderboard_save_pending = false
	var level_count := _count_levels(current_collection)
	level_complete_popup.show_results(
		leaderboard_player_name,
		current_leaderboard_score,
		_collection_display_name(current_collection),
		current_level_number,
		current_level_number < level_count
	)
	if not leaderboard_client.api_base_url.is_empty():
		leaderboard_client.load_scores(current_collection, current_level_number, 10)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _load_next_level() -> void:
	await _save_leaderboard_score()
	load_level(current_collection, current_level_number + 1)

func _return_to_main_menu() -> void:
	await _save_leaderboard_score()
	get_tree().paused = false
	LevelSelection.open_level_select = false
	get_tree().change_scene_to_file(START_MENU_SCENE)

func _show_pause_menu() -> void:
	if level_complete_popup.visible:
		return
	if pause_menu.has_method("_show_pause_actions"):
		pause_menu._show_pause_actions()
	pause_level_info_label.text = "%s - level %d" % [_collection_display_name(current_collection), current_level_number]
	pause_overlay.visible = true
	pause_button.visible = false
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _resume_game() -> void:
	pause_overlay.visible = false
	pause_button.visible = true
	get_tree().paused = false

func _restart_level() -> void:
	await _save_leaderboard_score()
	get_tree().paused = false
	load_level(current_collection, current_level_number)

func _record_move() -> void:
	score_hud.record_move()

func _current_score_payload() -> Dictionary:
	var elapsed_milliseconds: int = int(round(score_hud.elapsed_seconds * 1000.0))
	var score: int = MAX_LEADERBOARD_SCORE - ((score_hud.move_count * 10000) + elapsed_milliseconds)
	score = maxi(score, 0)
	return {
		"collection": current_collection,
		"level": current_level_number,
		"score": score,
		"metadata": {
			"moves": score_hud.move_count,
			"milliseconds": elapsed_milliseconds,
		},
	}

func _save_leaderboard_score() -> void:
	if leaderboard_score_saved or leaderboard_save_pending:
		return

	if leaderboard_client.api_base_url.is_empty() or current_leaderboard_score.is_empty():
		return

	leaderboard_save_pending = true
	leaderboard_client.submit_score(
		level_complete_popup.player_name(),
		current_leaderboard_score["collection"],
		current_leaderboard_score["level"],
		current_leaderboard_score["score"],
		current_leaderboard_score["metadata"]
	)
	var save_deadline := Time.get_ticks_msec() + 2500
	while leaderboard_save_pending and Time.get_ticks_msec() < save_deadline:
		await get_tree().process_frame
	if leaderboard_save_pending:
		leaderboard_save_pending = false
		level_complete_popup.set_status("Score save timed out.")

func _on_leaderboard_scores_loaded(scores: Array) -> void:
	if level_complete_popup.visible:
		level_complete_popup.set_scores(scores)

func _on_leaderboard_score_submitted() -> void:
	leaderboard_score_saved = true
	leaderboard_save_pending = false
	Log.print("leaderboard score submitted")

func _on_leaderboard_request_failed(message: String) -> void:
	leaderboard_save_pending = false
	if level_complete_popup.visible:
		level_complete_popup.set_status(message)
	Log.print(message)

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

func _collection_display_name(path: String) -> String:
	if path.is_empty():
		return "collection"
	return path.get_file().get_basename()
