class_name MatchEventBus
extends Node
signal occurred(event: String, payload: Dictionary)

func publish(event: String, payload: Dictionary = {}) -> void:
	occurred.emit(event, payload)
