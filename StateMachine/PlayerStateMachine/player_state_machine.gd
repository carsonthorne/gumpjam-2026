extends StateMachine

@export var character_model: CharacterModel

func _ready() -> void:
	for child: Motion in get_children():
		child.animation_state_changed.connect(character_model.on_state_machine_animation_state_changed)
	
	return super._ready()
