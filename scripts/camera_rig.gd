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
var ads_sensitivity := 0.55
var shoulder := 1.0
var ads_blend := 0.0
var combat_blend := 0.0
var exploration_fov := 70.0
var ads_fov := 48.0
var recoil := Vector2.ZERO
var recoil_strength := 1.0

var _cam: Camera3D
var _collision_sphere := SphereShape3D.new()


func _ready() -> void:
	_collision_sphere.radius = 0.25
	_cam = Camera3D.new()
	_cam.name = "Cam"
	_cam.current = true
	_cam.fov = 70.0
	_cam.far = 900.0
	_cam.near = 0.16
	add_child(_cam)


func add_look(delta: Vector2, from_touch := false) -> void:
	var s := touch_sens if from_touch else mouse_sens
	s *= lerpf(1.0, ads_sensitivity, ads_blend)
	yaw -= delta.x * s
	var lo := -0.92 if aircraft_mode else -1.15
	var hi := 0.42 if aircraft_mode else 0.9
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
	var player := follow as Player
	var aim := player != null and player.aiming and not player.locked and not player.in_vehicle
	var combat := player != null and (aim or player.combat_remaining > 0.0) and not player.locked and not player.in_vehicle
	var aim_time := Arsenal.data(player.weapon).aim_seconds if aim else 0.12
	ads_blend = move_toward(ads_blend, 1.0 if aim else 0.0, delta / maxf(aim_time, 0.01))
	combat_blend = move_toward(combat_blend, 1.0 if combat else 0.0, delta * 8.0)
	recoil = recoil.lerp(Vector2.ZERO, 1.0 - exp(-8.0 * delta))
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
		look_offset.y = 1.0 if player != null and player.crouched else 1.55
	var target := follow.global_position + look_offset
	if global_position.distance_to(target) > 24.0:
		global_position = target
	else:
		global_position = global_position.lerp(target, 1.0 - exp(-lerpf(10.0, 35.0, ads_blend) * delta))
	if vehicle_mode:
		yaw = lerp_angle(yaw, follow.rotation.y, 1.15 * delta)
	rotation.y = yaw + recoil.x

	var dist := arm_length + spd * 0.045
	if not vehicle_mode:
		dist = lerpf(dist, lerpf(3.8, 2.6, ads_blend), combat_blend)
	var elev := -pitch - recoil.y
	var back := global_transform.basis.z
	var side := global_transform.basis.x * shoulder * lerpf(0.38, 0.65, combat_blend)
	var desired := global_position + back * (dist * cos(elev)) + Vector3.UP * (dist * sin(elev)) + side
	var from := global_position + Vector3(0, 0.2, 0)
	desired = resolve_obstruction(from, desired)
	_cam.global_position = desired
	if _cam.global_position.distance_squared_to(global_position) > 0.04:
		var aim_target := global_position - back * cos(elev) * 50.0 - Vector3.UP * sin(elev) * 50.0
		var target_blend := 1.0 if player != null and player.weapon != Arsenal.Id.NONE and not player.locked else combat_blend
		_cam.look_at(global_position.lerp(aim_target, target_blend))
	var base_fov := 76.0 if aircraft_mode else (72.0 if vehicle_mode else lerpf(exploration_fov, ads_fov, ads_blend))
	_cam.fov = lerpf(_cam.fov, minf(base_fov + spd * 0.1, 84.0), 1.0 - exp(-12.0 * delta))
	if shake > 0.0:
		_cam.h_offset = randf_range(-shake, shake)
		_cam.v_offset = randf_range(-shake, shake)
		shake = move_toward(shake, 0.0, delta * 2.2)
	else:
		_cam.h_offset = 0.0
		_cam.v_offset = 0.0


func add_shake(amount: float) -> void:
	shake = minf(shake + amount, 0.5)

func kick(data: WeaponData) -> void:
	recoil.y = minf(recoil.y + data.recoil_vertical * recoil_strength, 0.18)
	recoil.x = clampf(recoil.x + randf_range(-data.recoil_horizontal, data.recoil_horizontal) * recoil_strength, -0.08, 0.08)


func resolve_obstruction(from: Vector3, desired: Vector3) -> Vector3:
	var motion := desired - from
	if motion.length_squared() < 0.0001:
		return desired
	var space := get_world_3d().direct_space_state
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _collision_sphere
	query.transform = Transform3D(Basis.IDENTITY, from)
	query.motion = motion
	query.collision_mask = 1
	query.margin = 0.03
	if follow is CollisionObject3D:
		query.exclude = [(follow as CollisionObject3D).get_rid()]
	var fractions := space.cast_motion(query)
	var safe_fraction := fractions[0]
	# Also handle walls closer than the former three metre cutoff.
	var ray := PhysicsRayQueryParameters3D.create(from, desired, 1, query.exclude)
	var hit := space.intersect_ray(ray)
	if hit:
		var safe_distance := maxf(from.distance_to(hit.position) - 0.3, 0.0)
		safe_fraction = minf(safe_fraction, safe_distance / motion.length())
	return from + motion * safe_fraction
