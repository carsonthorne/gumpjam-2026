extends Motion

@export var minimum_push_duration := 0.0
@export var pushing_trim_offset := 0.15
@export var pushing_animation_delay := 0.0
@export var pushing_loop_animation := true
@export var brace_transition_lead_time := 0.14

var elapsed := 0.0
var has_started_pushing_animation := false

func _enter() -> void:
	elapsed = 0.0
	has_started_pushing_animation = false
	velocity = Vector3.ZERO
	velocity_updated.emit(velocity)

	if pushing_animation_delay <= 0.0:
		_start_pushing_animation()

func _update(delta: float) -> void:
	elapsed += delta
	velocity = Vector3.ZERO
	velocity_updated.emit(velocity)

	if not has_started_pushing_animation and elapsed >= pushing_animation_delay:
		_start_pushing_animation()

	if elapsed < minimum_push_duration:
		return

	if owner.has_method("is_push_animation_within_end_transition") and owner.is_push_animation_within_end_transition(brace_transition_lead_time):
		finished.emit("Push_start")
		return

	if owner.has_method("is_push_animation_active") and owner.is_push_animation_active():
		return

	if owner.has_method("is_push_ready_active") and owner.is_push_ready_active():
		finished.emit("Push_start")
	else:
		finished.emit("Push_end")

func _start_pushing_animation() -> void:
	has_started_pushing_animation = true

	if owner.has_node("Pivot/CharacterModel"):
		var character_model: CharacterModel = owner.get_node("Pivot/CharacterModel") as CharacterModel
		if character_model != null:
			character_model.set_pushing_playback(pushing_trim_offset, pushing_loop_animation)
			character_model.set_movement_time_scale(1.0)

	animation_state_changed.emit("pushing")
