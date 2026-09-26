extends CanvasLayer

signal pause_requested
signal resume_requested

const DESIGN_SIZE := Vector2(628.0, 662.0)

@export_range(0.0, 2.0, 0.01) var entrance_duration := 0.55
@export_range(0.0, 2.0, 0.01) var exit_duration := 0.55

@onready var overlay: Control = $Overlay
@onready var panel: Control = $Overlay/Panel
@onready var title_label: Label = $Overlay/Panel/Margin/Content/Title
@onready var level_info_label: Label = $Overlay/Panel/Margin/Content/LevelInfoLabel
@onready var resume_button: Button = $Overlay/Panel/Margin/Content/ResumeButton
@onready var restart_button: Button = $Overlay/Panel/Margin/Content/RestartButton
@onready var level_select_button: Button = $Overlay/Panel/Margin/Content/LevelSelectButton
@onready var options_button: Button = $Overlay/Panel/Margin/Content/OptionsButton
@onready var main_menu_button: Button = $Overlay/Panel/Margin/Content/MainMenuButton
@onready var options_panel: VBoxContainer = $Overlay/Panel/Margin/Content/OptionsPanel
@onready var music_slider: HSlider = $Overlay/Panel/Margin/Content/OptionsPanel/MusicSlider
@onready var sfx_slider: HSlider = $Overlay/Panel/Margin/Content/OptionsPanel/SfxSlider
@onready var options_back_button: Button = $Overlay/Panel/Margin/Content/OptionsPanel/OptionsBackButton

var resting_position := Vector2.ZERO
var entrance_start_position := Vector2.ZERO
var exit_target_position := Vector2.ZERO
var entrance_tween: Tween = null
var exit_tween: Tween = null
var is_entering := false
var is_exiting := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_update_layout()
	get_viewport().size_changed.connect(_update_layout)
	options_button.pressed.connect(_show_options)
	options_back_button.pressed.connect(_show_pause_actions)
	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	music_slider.value = AudioSettings.get_music_volume()
	sfx_slider.value = AudioSettings.get_sfx_volume()

func _update_layout() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var scale_factor := minf(1.0, minf(viewport_size.x / DESIGN_SIZE.x, viewport_size.y / DESIGN_SIZE.y) * 0.94)
	resting_position = (viewport_size - (DESIGN_SIZE * scale_factor)) * 0.5
	if not is_entering and not is_exiting:
		panel.position = resting_position
	panel.size = DESIGN_SIZE
	panel.scale = Vector2.ONE * scale_factor

func show_with_entrance() -> void:
	_show_pause_actions()
	panel.process_mode = Node.PROCESS_MODE_INHERIT
	if exit_tween != null and exit_tween.is_valid():
		exit_tween.kill()
	exit_tween = null
	is_exiting = false
	_update_layout()
	if entrance_tween != null and entrance_tween.is_valid():
		entrance_tween.kill()
	var viewport_size := get_viewport().get_visible_rect().size
	entrance_start_position = Vector2(resting_position.x, viewport_size.y + 16.0)
	panel.position = entrance_start_position
	is_entering = true
	overlay.visible = true
	if entrance_duration <= 0.0:
		_finish_entrance()
		return
	entrance_tween = create_tween()
	entrance_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	entrance_tween.set_trans(Tween.TRANS_CUBIC)
	entrance_tween.set_ease(Tween.EASE_OUT)
	entrance_tween.tween_property(panel, "position", resting_position, entrance_duration)
	entrance_tween.finished.connect(_finish_entrance)

func hide_menu() -> void:
	if entrance_tween != null and entrance_tween.is_valid():
		entrance_tween.kill()
	if exit_tween != null and exit_tween.is_valid():
		exit_tween.kill()
	entrance_tween = null
	exit_tween = null
	is_entering = false
	is_exiting = false
	panel.process_mode = Node.PROCESS_MODE_INHERIT
	panel.position = resting_position
	overlay.visible = false

func hide_with_exit() -> void:
	if not overlay.visible:
		hide_menu()
		return
	if is_exiting:
		if exit_tween != null and exit_tween.is_valid():
			await exit_tween.finished
		return
	if entrance_tween != null and entrance_tween.is_valid():
		entrance_tween.kill()
	entrance_tween = null
	is_entering = false
	is_exiting = true
	panel.process_mode = Node.PROCESS_MODE_DISABLED
	var viewport_size := get_viewport().get_visible_rect().size
	exit_target_position = Vector2(resting_position.x, viewport_size.y + 16.0)
	if exit_duration <= 0.0:
		_finish_exit()
		return
	exit_tween = create_tween()
	exit_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	exit_tween.set_trans(Tween.TRANS_CUBIC)
	exit_tween.set_ease(Tween.EASE_IN)
	exit_tween.tween_property(panel, "position", exit_target_position, exit_duration)
	await exit_tween.finished
	_finish_exit()

func _finish_entrance() -> void:
	panel.position = resting_position
	is_entering = false
	entrance_tween = null

func _finish_exit() -> void:
	overlay.visible = false
	panel.position = resting_position
	panel.process_mode = Node.PROCESS_MODE_INHERIT
	is_exiting = false
	exit_tween = null

func _unhandled_input(event: InputEvent) -> void:
	if is_exiting:
		return
	var key_event := event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	if key_event.keycode != KEY_ESCAPE:
		return

	get_viewport().set_input_as_handled()
	if overlay.visible:
		if options_panel.visible:
			_show_pause_actions()
		else:
			resume_requested.emit()
	else:
		pause_requested.emit()

func _show_options() -> void:
	title_label.visible = false
	level_info_label.visible = false
	resume_button.visible = false
	restart_button.visible = false
	level_select_button.visible = false
	options_button.visible = false
	main_menu_button.visible = false
	options_panel.visible = true

func _show_pause_actions() -> void:
	title_label.visible = true
	level_info_label.visible = true
	resume_button.visible = true
	restart_button.visible = true
	level_select_button.visible = true
	options_button.visible = true
	main_menu_button.visible = true
	options_panel.visible = false

func _on_music_volume_changed(value: float) -> void:
	AudioSettings.set_music_volume(value)

func _on_sfx_volume_changed(value: float) -> void:
	AudioSettings.set_sfx_volume(value)
