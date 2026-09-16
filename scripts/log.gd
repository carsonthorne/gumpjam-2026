extends Node

signal message_printed(message: String)

func print(message: String) -> void:
	message_printed.emit(message)
