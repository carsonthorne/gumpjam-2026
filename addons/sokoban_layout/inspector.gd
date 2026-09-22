@tool
extends EditorInspectorPlugin

const Layout = preload("level_layout.gd")
const Reader = preload("map_reader.gd")
var build_level: Callable

func _can_handle(object: Object) -> bool:
	return object is Layout

func _parse_begin(object: Object) -> void:
	var panel := VBoxContainer.new()
	var summary := Label.new()
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(summary)
	var button := Button.new()
	button.text = "Build Level"
	panel.add_child(button)
	var refresh := Button.new()
	refresh.text = "Refresh Collection"
	panel.add_child(refresh)
	var update := func():
		var map := Reader.read_level(object.collection, object.level_number)
		button.disabled = map.has("error")
		summary.text = map.get("error", "")
		if not map.has("error"):
			summary.text = "Level %d / %d · %d × %d cells\n%d crates · %d targets\nBuild replaces Generated and moves the player. Undo restores both." % [object.level_number, map.level_count, map.width, map.height, map.crates, map.targets]
	refresh.pressed.connect(update)
	button.pressed.connect(func(): build_level.call(object, summary))
	update.call()
	add_custom_control(panel)
