extends CanvasLayer

signal next_requested
signal restart_requested
signal main_menu_requested

const MAX_NAME_LENGTH := 12
const MAX_SCORE_ROWS := 10
const DESIGN_SIZE := Vector2(628.0, 662.0)
const CURRENT_ROW_COLOR := Color(0.82, 0.06, 0.04, 1.0)

@onready var design_root: Control = $Overlay/DesignRoot
@onready var title_label: Label = $Overlay/DesignRoot/Shell/Content/Title
@onready var subtitle_label: Label = $Overlay/DesignRoot/Shell/Content/Subtitle
@onready var status_label: Label = $Overlay/DesignRoot/Shell/Content/StatusLabel
@onready var score_rows: VBoxContainer = $Overlay/DesignRoot/Shell/Content/Scores/Rows
@onready var next_level_button: Button = $Overlay/DesignRoot/Shell/Content/Buttons/NextLevelButton
@onready var restart_button: Button = $Overlay/DesignRoot/Shell/Content/Buttons/RestartButton
@onready var main_menu_button: Button = $Overlay/DesignRoot/Shell/Content/Buttons/MainMenuButton

var current_score := {}
var loaded_scores: Array = []
var current_name_input: LineEdit = null

func _ready() -> void:
	_update_layout()
	get_viewport().size_changed.connect(_update_layout)
	title_label.text = "Level Completed"
	next_level_button.pressed.connect(next_requested.emit)
	restart_button.pressed.connect(restart_requested.emit)
	main_menu_button.pressed.connect(main_menu_requested.emit)

func _update_layout() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var scale_factor := minf(1.0, minf(viewport_size.x / DESIGN_SIZE.x, viewport_size.y / DESIGN_SIZE.y) * 0.94)
	design_root.position = (viewport_size - (DESIGN_SIZE * scale_factor)) * 0.5
	design_root.size = DESIGN_SIZE
	design_root.scale = Vector2.ONE * scale_factor

func show_results(player_name: String, score: Dictionary, collection_name: String, level_number: int, has_next_level: bool) -> void:
	current_score = score.duplicate(true)
	current_score["playerName"] = _clean_player_name(player_name)
	loaded_scores = []
	current_name_input = null
	subtitle_label.text = "%s - level %d" % [collection_name, level_number]
	next_level_button.visible = has_next_level
	status_label.text = "Loading high scores..."
	_render_scores()
	visible = true
	_focus_current_name.call_deferred()

func set_scores(scores: Array) -> void:
	loaded_scores = scores.duplicate(true)
	status_label.text = ""
	_render_scores()

func set_status(message: String) -> void:
	status_label.text = message

func player_name() -> String:
	if current_name_input == null:
		return _clean_player_name(str(current_score.get("playerName", "Player")))
	return _clean_player_name(current_name_input.text)

func _on_name_changed(value: String) -> void:
	current_score["playerName"] = _clean_player_name(value)

func _render_scores() -> void:
	var previous_name := player_name()
	current_name_input = null
	for child in score_rows.get_children():
		score_rows.remove_child(child)
		child.queue_free()

	if not current_score.is_empty():
		current_score["playerName"] = previous_name

	var merged := _scores_with_current_run()
	if merged.is_empty():
		_add_empty_row()
		return

	for index in range(mini(merged.size(), MAX_SCORE_ROWS)):
		_add_score_row(index + 1, merged[index])

	if current_name_input != null:
		_focus_current_name.call_deferred()

func _scores_with_current_run() -> Array:
	var merged := loaded_scores.duplicate(true)
	if not current_score.is_empty():
		var player_score := current_score.duplicate(true)
		player_score["isCurrentRun"] = true
		merged.append(player_score)

	merged.sort_custom(func(left, right): return int(left.get("score", 0)) > int(right.get("score", 0)))
	return merged

func _add_empty_row() -> void:
	var label := Label.new()
	label.text = "No scores yet"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(0.16, 0.14, 0.12, 1.0))
	score_rows.add_child(label)

func _add_score_row(rank: int, score: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 24)
	row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	row.add_theme_constant_override("separation", 6)
	score_rows.add_child(row)

	var rank_label := _row_label("%d." % rank, 30, HORIZONTAL_ALIGNMENT_RIGHT)
	row.add_child(rank_label)

	var is_current_run := bool(score.get("isCurrentRun", false))
	var name_control: Control
	if is_current_run:
		name_control = _current_name_field(str(score.get("playerName", "Player")))
		current_name_input = name_control as LineEdit
	else:
		name_control = _row_label(str(score.get("playerName", "Player")), 120, HORIZONTAL_ALIGNMENT_LEFT)
	row.add_child(name_control)

	var meta: Variant = score.get("metadata", {})
	var moves: int = int(meta.get("moves", 0)) if typeof(meta) == TYPE_DICTIONARY else 0
	var milliseconds: int = int(meta.get("milliseconds", 0)) if typeof(meta) == TYPE_DICTIONARY else 0
	var moves_label := _row_label(str(moves), 78, HORIZONTAL_ALIGNMENT_RIGHT)
	row.add_child(moves_label)

	var time_label := _row_label(_format_time(milliseconds), 62, HORIZONTAL_ALIGNMENT_RIGHT)
	row.add_child(time_label)

	if is_current_run:
		rank_label.add_theme_color_override("font_color", CURRENT_ROW_COLOR)
		moves_label.add_theme_color_override("font_color", CURRENT_ROW_COLOR)
		time_label.add_theme_color_override("font_color", CURRENT_ROW_COLOR)

func _current_name_field(value: String) -> LineEdit:
	var input := LineEdit.new()
	input.custom_minimum_size = Vector2(120, 22)
	input.max_length = MAX_NAME_LENGTH
	input.text = _clean_player_name(value)
	input.caret_blink = true
	input.select_all_on_focus = false
	var empty_style := StyleBoxEmpty.new()
	input.add_theme_stylebox_override("normal", empty_style)
	input.add_theme_stylebox_override("focus", empty_style)
	input.add_theme_stylebox_override("read_only", empty_style)
	input.add_theme_color_override("font_color", CURRENT_ROW_COLOR)
	input.add_theme_color_override("font_focus_color", CURRENT_ROW_COLOR)
	input.add_theme_font_size_override("font_size", 16)
	input.text_changed.connect(_on_name_changed)
	return input

func _focus_current_name() -> void:
	if current_name_input == null:
		return

	current_name_input.grab_focus()
	current_name_input.caret_column = current_name_input.text.length()

func _row_label(text: String, width: float, alignment: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.custom_minimum_size = Vector2(width, 22)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.text = text
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.horizontal_alignment = alignment
	label.add_theme_color_override("font_color", Color(0.11, 0.095, 0.075, 1.0))
	label.add_theme_font_size_override("font_size", 16)
	return label

func _clean_player_name(value: String) -> String:
	var cleaned := value.strip_edges()
	if cleaned.is_empty():
		return "Player"
	return cleaned.substr(0, MAX_NAME_LENGTH)

func _format_time(milliseconds: int) -> String:
	var total_seconds := milliseconds / 1000
	var minutes := total_seconds / 60
	var seconds := total_seconds % 60
	return "%02d:%02d" % [minutes, seconds]
