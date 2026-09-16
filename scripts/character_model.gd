extends Node3D
class_name CharacterModel

@export var animation_tree: AnimationTree

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func on_state_machine_animation_state_changed(state: String) -> void:
	animation_tree["parameters/movement/transition_request"] = state
