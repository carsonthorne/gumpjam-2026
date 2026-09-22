extends Node

const Reader = preload("res://addons/sokoban_layout/map_reader.gd")
const Builder = preload("res://addons/sokoban_layout/layout_builder.gd")

@onready var level_layout: Node3D = $LevelLayout
@onready var player: CharacterBody3D = $Player
@onready var level_goal: Node = $LevelGoal

func _ready() -> void:
	if LevelSelection.has_selection:
		var dev_level_menu := get_node_or_null("DevLevelMenu") as CanvasLayer
		if dev_level_menu != null:
			dev_level_menu.visible = false
		load_level(LevelSelection.collection, LevelSelection.level_number)

func load_level(collection: String, level_number: int) -> void:
	var map := Reader.read_level(collection, level_number)
	if map.has("error"):
		push_error(map.error)
		return

	var previous := level_layout.get_node_or_null("Generated")
	if previous != null:
		level_layout.remove_child(previous)
		previous.queue_free()

	var generated := Builder.build(map)
	level_layout.add_child(generated)
	level_layout.set("collection", collection)
	level_layout.set("level_number", level_number)

	player.global_position = level_layout.to_global(Builder.cell_position(map.player, map))
	player.velocity = Vector3.ZERO
	if player.has_method("set_push_ready"):
		player.set_push_ready(false)

	if level_goal.has_method("refresh_targets"):
		level_goal.refresh_targets()
