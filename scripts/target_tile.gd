extends Area3D

signal block_entered_target(block: Node3D)
signal block_exited_target(block: Node3D)

@export var should_log_events := true
@export var centered_tolerance := 0.05
@export var beam: Node3D

var overlapping_blocks := {}
var active_blocks := {}

func _ready() -> void:
	if beam == null:
		beam = get_node_or_null("Beam") as Node3D
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_update_beam_visibility()

func has_block_on_target() -> bool:
	return not active_blocks.is_empty()

func _physics_process(_delta: float) -> void:
	for block in overlapping_blocks.keys():
		if not is_instance_valid(block):
			overlapping_blocks.erase(block)
			active_blocks.erase(block)
			continue

		var is_centered := _is_block_centered_on_target(block)
		if is_centered and not active_blocks.has(block):
			active_blocks[block] = true
			_update_beam_visibility()
			if should_log_events:
				Log.print("%s entered %s" % [block.name, name])
			block_entered_target.emit(block)
		elif not is_centered and active_blocks.has(block):
			active_blocks.erase(block)
			_update_beam_visibility()
			if should_log_events:
				Log.print("%s exited %s" % [block.name, name])
			block_exited_target.emit(block)

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("push_block"):
		return

	overlapping_blocks[body] = true

func _on_body_exited(body: Node3D) -> void:
	if not overlapping_blocks.has(body):
		return

	overlapping_blocks.erase(body)
	if active_blocks.has(body):
		active_blocks.erase(body)
		_update_beam_visibility()
		if should_log_events:
			Log.print("%s exited %s" % [body.name, name])
		block_exited_target.emit(body)

func _is_block_centered_on_target(block: Node3D) -> bool:
	var offset := block.global_position - global_position
	offset.y = 0.0
	return offset.length() <= centered_tolerance

func _update_beam_visibility() -> void:
	if beam == null:
		return

	beam.visible = not has_block_on_target()
