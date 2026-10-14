class_name ShotEffects
extends Node3D
## Fixed pool: no timers or nodes are allocated per shot.
const CAPACITY := 12
var _slots: Array[Node3D] = []
var _life: Array[float] = []
var _cursor := 0

func _ready() -> void:
	var tracer_material := StandardMaterial3D.new()
	tracer_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tracer_material.albedo_color = Color("fff2c0")
	var geometry := BoxMesh.new()
	geometry.size = Vector3(0.018, 0.018, 1.0)
	var flash_geometry := SphereMesh.new()
	flash_geometry.radius = 0.07
	flash_geometry.height = 0.14
	for i in CAPACITY:
		var slot := Node3D.new()
		var tracer := MeshInstance3D.new()
		tracer.mesh = geometry
		tracer.material_override = tracer_material
		slot.add_child(tracer)
		var flash := MeshInstance3D.new()
		flash.mesh = flash_geometry
		flash.material_override = tracer_material
		slot.add_child(flash)
		add_child(slot)
		slot.visible = false
		_slots.append(slot)
		_life.append(0.0)

func emit_shot(from: Vector3, to: Vector3) -> void:
	if from.distance_squared_to(to) < 0.0001:
		return
	var slot := _slots[_cursor]
	var tracer := slot.get_child(0) as MeshInstance3D
	var flash := slot.get_child(1) as MeshInstance3D
	tracer.global_position = (from + to) * 0.5
	tracer.look_at(to)
	tracer.scale = Vector3(1, 1, from.distance_to(to))
	flash.global_position = from
	slot.visible = true
	_life[_cursor] = 0.055
	_cursor = (_cursor + 1) % CAPACITY

func _process(delta: float) -> void:
	for i in CAPACITY:
		if _life[i] > 0.0:
			_life[i] = maxf(_life[i] - delta, 0.0)
			_slots[i].visible = _life[i] > 0.0
