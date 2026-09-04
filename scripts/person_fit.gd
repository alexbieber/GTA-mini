extends Node3D

const Models = preload("res://scripts/models.gd")


func _ready() -> void:
	call_deferred("_fit")


func _fit() -> void:
	if not is_inside_tree():
		return
	await get_tree().process_frame
	Models.normalize_person(self)
	await get_tree().create_timer(0.12).timeout
	if is_inside_tree():
		Models.normalize_person(self)
