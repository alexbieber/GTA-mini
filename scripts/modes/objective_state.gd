class_name ObjectiveState
extends RefCounted
enum Status { AT_BASE, CARRIED, DROPPED, RETURNING, CAPTURED }
var id := ""
var owner := 0
var label := ""
var original := Vector3.ZERO
var position := Vector3.ZERO
var points := 1
var state := Status.AT_BASE
var carrier := -1
var remaining := 0.0

func reset() -> void:
	state = Status.AT_BASE
	position = original
	carrier = -1
	remaining = 0.0

func snapshot() -> Dictionary:
	return {"id": id, "owner": owner, "label": label, "original": original,
		"position": position, "points": points, "state": state, "carrier": carrier, "remaining": remaining}
