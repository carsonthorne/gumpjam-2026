extends StateMachine

@export var character_model: CharacterModel

func _ready() -> void:
	for child: Motion in get_children():
		child.animation_state_changed.connect(character_model.on_state_machine_animation_state_changed)

	if owner.has_signal("push_ready_started"):
		owner.push_ready_started.connect(_on_player_push_ready_started)
	if owner.has_signal("push_ready_ended"):
		owner.push_ready_ended.connect(_on_player_push_ready_ended)
	if owner.has_signal("push_started"):
		owner.push_started.connect(_on_player_push_started)
	
	return super._ready()

func _on_player_push_ready_started() -> void:
	if current_state.name in ["Idle", "Walk", "Run"]:
		_change_state("Push_start")

func _on_player_push_ready_ended() -> void:
	if current_state.name == "Push_start":
		_change_state("Push_end")

func _on_player_push_started() -> void:
	if current_state.name == "Push_start":
		_change_state("Pushing")
