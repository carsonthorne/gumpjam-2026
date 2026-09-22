extends Node

var collection := "res://levels/wikipedia.txt"
var level_number := 1
var has_selection := false

func choose(next_collection: String, next_level_number: int) -> void:
	collection = next_collection
	level_number = next_level_number
	has_selection = true
