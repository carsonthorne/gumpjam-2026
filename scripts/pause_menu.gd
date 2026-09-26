extends CanvasLayer

signal pause_requested
signal resume_requested

const DESIGN_SIZE := Vector2(628.0, 662.0)

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
	panel.position = (viewport_size - (DESIGN_SIZE * scale_factor)) * 0.5
	panel.size = DESIGN_SIZE
	panel.scale = Vector2.ONE * scale_factor

func _unhandled_input(event: InputEvent) -> void:
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
