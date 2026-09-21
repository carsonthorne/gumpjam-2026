@tool
extends Node3D

@export_file("*.txt", "*.sok") var collection := "res://levels/wikipedia.txt":
	set(value):
		collection = value
		notify_property_list_changed()
@export_range(1, 10000, 1) var level_number := 1:
	set(value):
		level_number = value
		notify_property_list_changed()
@export_node_path("CharacterBody3D") var player_path := NodePath("../Player")
