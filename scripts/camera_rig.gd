class_name CameraRig
extends Node3D

var yaw := -1.35
var pitch := -0.22
var follow: Node3D
var look_offset := Vector3(0, 1.55, 0)
var arm_length := 9.4
var mouse_sens := 0.0032
var touch_sens := 0.0065
var shake := 0.0
var vehicle_mode := false
var aircraft_mode := false

var _cam: Camera3D


func _ready() -> void:
	_cam = Camera3D.new()
	_cam.name = "Cam"
	_cam.current = true
	_cam.fov = 70.0
	_cam.far = 2800.0
	_cam.near = 0.16
	add_child(_cam)


func add_look(delta: Vector2, from_touch := false) -> void:
	var s := touch_sens if from_touch else mouse_sens
	yaw -= delta.x * s
	var lo := -0.92 if aircraft_mode else -0.58
	var hi := 0.42 if aircraft_mode else 0.22
	pitch = clampf(pitch - delta.y * s, lo, hi)


func set_vehicle_mode(on: bool) -> void:
	vehicle_mode = on
	aircraft_mode = false
	arm_length = 13.8 if on else 9.4
	look_offset = Vector3(0, 2.05, 0) if on else Vector3(0, 1.55, 0)


func set_aircraft_mode(on: bool) -> void:
	aircraft_mode = on
	vehicle_mode = on
	arm_length = 22.0 if on else 9.4
	look_offset = Vector3(0, 3.4, 0) if on else Vector3(0, 1.55, 0)


func camera() -> Camera3D:
	return _cam


func _process(delta: float) -> void:
	if follow == null:
		return
	var spd := 0.0
	if follow is Vehicle:
		spd = absf((follow as Vehicle).speed)
	elif follow is Aircraft:
		spd = absf((follow as Aircraft).speed)
	if aircraft_mode:
		look_offset.y = 3.4 + spd * 0.014
	elif vehicle_mode:
		look_offset.y = 2.05 + spd * 0.01
	else:
		look_offset.y = 1.55
	var target := follow.global_position + look_offset
	if global_position.distance_to(target) > 24.0:
		global_position = target
	else:
		global_position = global_position.lerp(target, 1.0 - exp(-10.0 * delta))
	if vehicle_mode:
		yaw = lerp_angle(yaw, follow.rotation.y, 1.15 * delta)
	rotation.y = yaw

	var dist := arm_length + spd * 0.045
	var elev := -pitch
	var back := global_transform.basis.z
	var desired := global_position + back * (dist * cos(elev)) + Vector3.UP * (dist * sin(elev)) + global_transform.basis.x * 0.38
	var from := global_position + Vector3(0, 0.2, 0)
	var space := get_world_3d().direct_space_state
	if space:
		var q := PhysicsRayQueryParameters3D.create(from, desired, 1)
		if follow is CollisionObject3D:
			q.exclude = [(follow as CollisionObject3D).get_rid()]
		var hit := space.intersect_ray(q)
		if hit and from.distance_to(hit.position) > 3.0:
			desired = hit.position + (from - desired).normalized() * 0.45
	_cam.global_position = desired
	if _cam.global_position.distance_squared_to(global_position) > 0.04:
		_cam.look_at(global_position)
	var base_fov := 76.0 if aircraft_mode else (72.0 if vehicle_mode else 70.0)
	_cam.fov = lerpf(_cam.fov, minf(base_fov + spd * 0.1, 84.0), 4.0 * delta)
	if shake > 0.0:
		_cam.h_offset = randf_range(-shake, shake)
		_cam.v_offset = randf_range(-shake, shake)
		shake = move_toward(shake, 0.0, delta * 2.2)
	else:
		_cam.h_offset = 0.0
		_cam.v_offset = 0.0


func add_shake(amount: float) -> void:
	shake = minf(shake + amount, 0.5)
