extends Node

const Reader = preload("res://addons/sokoban_layout/map_reader.gd")
const Builder = preload("res://addons/sokoban_layout/layout_builder.gd")
const CheeseReward = preload("res://scenes/cheese_reward.tscn")
const START_MENU_SCENE := "res://scenes/start_menu.tscn"
const MAX_LEADERBOARD_SCORE := 1000000000

@export var leaderboard_player_name := "Player"

@onready var level_layout: Node3D = $LevelLayout
@onready var player: CharacterBody3D = $Player
@onready var character_model: CharacterModel = $Player/Pivot/CharacterModel
@onready var player_pivot: Node3D = $Player/Pivot
@onready var player_camera_pivot: Node3D = $Player/CameraPivot
@onready var player_camera_target: Node3D = $Player/CameraPivot/CameraPosition
@onready var player_camera: Camera3D = $Player/CameraPivot/Camera3D
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
var level_completion_in_progress := false
var level_completion_sequence := 0
var completion_dance_duration_override := -1.0
var completion_idle_settle_duration := 0.18
var completion_turn_duration := 0.55
var completion_cheese_descent_duration := 1.6
var completion_cheese_disappear_duration := 0.18
var completion_cheese_contact_height := 1.27
var completion_reach_blend_duration := 0.42
var completion_reach_release_duration := 0.8
var completion_camera_return_duration := 0.65
var completion_camera_distance_ratio := 2.0 / 3.0
var completion_cheese_camera_distance := 1.25
var completion_phase := ""
var active_reward_cheese: Node3D = null
var default_camera_target_position := Vector3.ZERO
var completion_camera_start_transform := Transform3D.IDENTITY
var completion_camera_tween: Tween = null
var completion_camera_active := false

func _ready() -> void:
	default_camera_target_position = player_camera_target.position
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
	level_completion_sequence += 1
	level_completion_in_progress = false
	completion_phase = ""
	_cleanup_reward_cheese()
	character_model.reset_cheese_reach_pose()
	_reset_completion_camera()
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
	if player.has_method("set_gameplay_enabled"):
		player.set_gameplay_enabled(true)
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
	if level_completion_in_progress:
		return

	level_completion_in_progress = true
	level_completion_sequence += 1
	var completion_sequence := level_completion_sequence
	get_tree().paused = false
	pause_overlay.visible = false
	score_hud.stop()
	pause_button.visible = false
	current_leaderboard_score = _current_score_payload()
	leaderboard_score_saved = false
	leaderboard_save_pending = false
	if player.has_method("set_gameplay_enabled"):
		player.set_gameplay_enabled(false)
	completion_phase = "idle"
	character_model.play_idle()
	if completion_idle_settle_duration > 0.0:
		await get_tree().create_timer(completion_idle_settle_duration).timeout
	if completion_sequence != level_completion_sequence or not is_inside_tree():
		return
	completion_phase = "turning"
	await _turn_player_toward_camera()
	if completion_sequence != level_completion_sequence or not is_inside_tree():
		return
	completion_phase = "cheese"
	await _drop_cheese_reward()
	if completion_sequence != level_completion_sequence or not is_inside_tree():
		return
	completion_phase = "dance"
	character_model.end_cheese_reach_pose(completion_reach_release_duration)
	var dance_duration := character_model.play_chicken_dance()
	if completion_dance_duration_override >= 0.0:
		dance_duration = completion_dance_duration_override
	if dance_duration > 0.0:
		await get_tree().create_timer(dance_duration).timeout
	if completion_sequence != level_completion_sequence or not is_inside_tree():
		return

	completion_phase = "popup"
	get_tree().paused = true
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

func _turn_player_toward_camera() -> void:
	var camera_direction := player_camera.global_position - player.global_position
	camera_direction.y = 0.0
	if camera_direction.length_squared() == 0.0:
		return

	var look_position := player.global_position + camera_direction.normalized()
	var target_transform := player.global_transform.looking_at(look_position, Vector3.UP, true)
	var target_yaw := target_transform.basis.get_euler().y
	var yaw_offset := wrapf(target_yaw - player_pivot.rotation.y, -PI, PI)
	if completion_turn_duration <= 0.0:
		player_pivot.rotation.y += yaw_offset
		return

	var turn_tween := create_tween()
	turn_tween.set_trans(Tween.TRANS_SINE)
	turn_tween.set_ease(Tween.EASE_IN_OUT)
	turn_tween.tween_property(player_pivot, "rotation:y", player_pivot.rotation.y + yaw_offset, completion_turn_duration)
	await turn_tween.finished

func _drop_cheese_reward() -> void:
	_cleanup_reward_cheese()
	active_reward_cheese = CheeseReward.instantiate() as Node3D
	add_child(active_reward_cheese)
	var cheese_target := player.global_position + Vector3.UP * completion_cheese_contact_height
	active_reward_cheese.global_position = cheese_target + Vector3.UP * 2.0
	active_reward_cheese.scale = Vector3.ONE * 0.38
	active_reward_cheese.rotation.y = player_pivot.global_rotation.y
	character_model.begin_cheese_reach_pose(cheese_target, completion_reach_blend_duration)
	_begin_cheese_camera()

	if completion_cheese_descent_duration > 0.0:
		var descent_tween := create_tween().set_parallel(true)
		descent_tween.set_trans(Tween.TRANS_SINE)
		descent_tween.set_ease(Tween.EASE_IN_OUT)
		descent_tween.tween_property(active_reward_cheese, "global_position", cheese_target, completion_cheese_descent_duration)
		descent_tween.tween_property(active_reward_cheese, "rotation:y", active_reward_cheese.rotation.y + PI * 0.35, completion_cheese_descent_duration)
		completion_camera_tween = create_tween()
		completion_camera_tween.set_trans(Tween.TRANS_SINE)
		completion_camera_tween.set_ease(Tween.EASE_IN_OUT)
		completion_camera_tween.tween_method(_track_cheese_camera, 0.0, 1.0, completion_cheese_descent_duration)
		await descent_tween.finished
	else:
		active_reward_cheese.global_position = cheese_target
		_track_cheese_camera(1.0)

	if not is_instance_valid(active_reward_cheese):
		return
	await _return_camera_after_cheese()
	_cleanup_reward_cheese()

func _begin_cheese_camera() -> void:
	if completion_camera_tween != null and completion_camera_tween.is_valid():
		completion_camera_tween.kill()
	completion_camera_start_transform = player_camera.global_transform
	completion_camera_active = true
	player_camera_pivot.set_process(false)
	player_camera.set_process(false)

func _track_cheese_camera(progress: float) -> void:
	if not completion_camera_active or not is_instance_valid(active_reward_cheese):
		return
	var player_focus := player.global_position + Vector3.UP * 1.2
	var camera_direction := completion_camera_start_transform.origin - player_focus
	if camera_direction.length_squared() == 0.0:
		camera_direction = Vector3.BACK
	var camera_offset := camera_direction.normalized() * completion_cheese_camera_distance
	var desired_position := active_reward_cheese.global_position + camera_offset
	var desired_transform := Transform3D(completion_camera_start_transform.basis, desired_position)
	desired_transform = desired_transform.looking_at(active_reward_cheese.global_position, Vector3.UP)
	player_camera.global_transform = completion_camera_start_transform.interpolate_with(desired_transform, progress)

func _return_camera_after_cheese() -> void:
	if not completion_camera_active:
		return
	if completion_camera_tween != null and completion_camera_tween.is_valid():
		completion_camera_tween.kill()
	player_camera_target.position = default_camera_target_position * completion_camera_distance_ratio
	var return_transform := player_camera_target.global_transform
	var return_duration := maxf(completion_camera_return_duration, completion_cheese_disappear_duration)
	if return_duration <= 0.0:
		player_camera.global_transform = return_transform
		active_reward_cheese.scale = Vector3.ZERO
		_finish_completion_camera()
		return
	completion_camera_tween = create_tween().set_parallel(true)
	completion_camera_tween.set_trans(Tween.TRANS_SINE)
	completion_camera_tween.set_ease(Tween.EASE_IN_OUT)
	completion_camera_tween.tween_property(player_camera, "global_transform", return_transform, completion_camera_return_duration)
	completion_camera_tween.tween_property(active_reward_cheese, "scale", Vector3.ZERO, completion_cheese_disappear_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await completion_camera_tween.finished
	_finish_completion_camera()

func _finish_completion_camera() -> void:
	completion_camera_active = false
	completion_camera_tween = null
	player_camera.global_transform = player_camera_target.global_transform
	player_camera.set_process(true)
	player_camera_pivot.set_process(true)

func _reset_completion_camera() -> void:
	if completion_camera_tween != null and completion_camera_tween.is_valid():
		completion_camera_tween.kill()
	completion_camera_tween = null
	completion_camera_active = false
	player_camera_target.position = default_camera_target_position
	player_camera.transform = player_camera_target.transform
	player_camera.set_process(true)
	player_camera_pivot.set_process(true)

func _cleanup_reward_cheese() -> void:
	if is_instance_valid(active_reward_cheese):
		active_reward_cheese.queue_free()
	active_reward_cheese = null

func _load_next_level() -> void:
	await _save_leaderboard_score()
	load_level(current_collection, current_level_number + 1)

func _return_to_main_menu() -> void:
	await _save_leaderboard_score()
	get_tree().paused = false
	LevelSelection.open_level_select = false
	get_tree().change_scene_to_file(START_MENU_SCENE)

func _show_pause_menu() -> void:
	if level_complete_popup.visible or level_completion_in_progress:
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
