extends CanvasLayer

@onready var timer_label: Label = $Panel/Margin/Stats/TimerLabel
@onready var moves_label: Label = $Panel/Margin/Stats/MovesLabel

var elapsed_seconds := 0.0
var move_count := 0
var is_tracking := false
var _displayed_second := -1


func _ready() -> void:
	_update_moves_label()
	_update_timer_label()


func _process(delta: float) -> void:
	if not is_tracking:
		return

	elapsed_seconds += delta
	var current_second := int(elapsed_seconds)
	if current_second != _displayed_second:
		_update_timer_label()


func reset() -> void:
	elapsed_seconds = 0.0
	move_count = 0
	_displayed_second = -1
	is_tracking = true
	_update_timer_label()
	_update_moves_label()


func stop() -> void:
	is_tracking = false


func record_move() -> void:
	if not is_tracking:
		return

	move_count += 1
	_update_moves_label()


func _update_timer_label() -> void:
	var total_seconds := int(elapsed_seconds)
	var hours := total_seconds / 3600
	var minutes := (total_seconds % 3600) / 60
	var seconds := total_seconds % 60
	if hours > 0:
		timer_label.text = "Time  %02d:%02d:%02d" % [hours, minutes, seconds]
	else:
		timer_label.text = "Time  %02d:%02d" % [minutes, seconds]
	_displayed_second = total_seconds


func _update_moves_label() -> void:
	moves_label.text = "Moves  %d" % move_count
