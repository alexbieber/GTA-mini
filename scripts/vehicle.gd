class_name Vehicle
extends CharacterBody3D

const Models = preload("res://scripts/models.gd")

enum Kind { COUPE, COP, PARKED, CIVILIAN, MILITARY }

const GRAVITY := 32.0

@export var kind: Kind = Kind.COUPE

var occupied := false
var ai_enabled := false
var chase_target: Node3D
var patrol: Array[Vector3] = []
var stolen := false
var fleeing := false
var wrecked := false
var has_driver := true
var chase_slot := 0
var display_name := "Car"
var speed := 0.0
var max_speed := 22.0
var ai_max_speed := 17.5
var hp := 100.0
var last_impact := 0.0
var graph: RoadGraph
var node_i := 0
var next_i := 1
var prev_i := -1
var braking := false

var patrol_i := 0
var _near: Area3D
var _light_a: OmniLight3D
var _light_b: OmniLight3D
var _head_l: OmniLight3D
var _head_r: OmniLight3D
var _head_mats: Array[StandardMaterial3D] = []
var _tail_mats: Array[StandardMaterial3D] = []
var _wheels: Array[Node3D] = []
var _blink := 0.0
var _night := true


func setup(p_kind: Kind, spawn: Vector3, facing_y := 0.0) -> void:
	kind = p_kind
	_apply_kind()
	if is_inside_tree():
		global_position = spawn
		rotation.y = facing_y
	else:
		position = spawn
		rotation.y = facing_y


func _apply_kind() -> void:
	match kind:
		Kind.COUPE:
			max_speed = 112.0
		Kind.COP:
			max_speed = 78.0
			ai_max_speed = 68.0
			ai_enabled = true
		Kind.PARKED:
			max_speed = 64.0
			has_driver = false
			ai_enabled = false
		Kind.CIVILIAN:
			max_speed = 56.0
			ai_max_speed = 36.0
			ai_enabled = true
		Kind.MILITARY:
			max_speed = 68.0
			has_driver = false
			ai_enabled = false


func _ready() -> void:
	_apply_kind()
	add_to_group("vehicles")
	add_to_group("time_sensitive")
	if kind == Kind.COP:
		add_to_group("cops")
		collision_layer = 8
	else:
		collision_layer = 4
	collision_mask = 1 | 2 | 4 | 8 | 16
	floor_snap_length = 0.4
	motion_mode = MOTION_MODE_GROUNDED
	_build_collision()
	_build_mesh()
	_build_near()


func apply_time(night: bool) -> void:
	_night = night
	var on := night or occupied
	if _head_l:
		_head_l.visible = on
		_head_r.visible = on
		_head_l.light_energy = 1.5 if on else 0.0
		_head_r.light_energy = 1.5 if on else 0.0
	for m in _head_mats:
		m.emission_energy_multiplier = 2.2 if on else 0.15
	for m in _tail_mats:
		m.emission_energy_multiplier = 2.8 if night else 0.8


func _build_collision() -> void:
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.78, 1.05, 4.25)
	col.shape = box
	col.position.y = 0.52
	add_child(col)


func _build_near() -> void:
	_near = Area3D.new()
	_near.collision_layer = 0
	_near.collision_mask = 2
	var col := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 3.4
	col.shape = sph
	col.position.y = 0.6
	_near.add_child(col)
	add_child(_near)


func _build_mesh() -> void:
	var spec := Models.car_for(kind)
	display_name = spec["name"]
	var vis := Models.instance_car(spec["path"])
	add_child(vis)
	_wheels = Models.car_wheels(vis)
	if kind == Kind.COUPE:
		Models.tint_car(vis, Color("e39a22"))
	elif kind == Kind.MILITARY:
		Models.tint_car(vis, Color("4a5336"))

	_head_l = _spot(Vector3(-0.5, 0.55, -2.15), Color("fff3c8"))
	_head_r = _spot(Vector3(0.5, 0.55, -2.15), Color("fff3c8"))
	_add_light_pod(Vector3(-0.55, 0.52, -2.12), Color("fff4cc"), true)
	_add_light_pod(Vector3(0.55, 0.52, -2.12), Color("fff4cc"), true)
	_add_light_pod(Vector3(-0.55, 0.52, 2.05), Color("ff3344"), false)
	_add_light_pod(Vector3(0.55, 0.52, 2.05), Color("ff3344"), false)

	if kind == Kind.COP:
		_light_a = OmniLight3D.new()
		_light_a.light_color = Color("ff3344")
		_light_a.light_energy = 2.8
		_light_a.omni_range = 9.0
		_light_a.position = Vector3(-0.32, 1.42, 0.15)
		add_child(_light_a)
		_light_b = OmniLight3D.new()
		_light_b.light_color = Color("3a66ff")
		_light_b.light_energy = 2.8
		_light_b.omni_range = 9.0
		_light_b.position = Vector3(0.32, 1.42, 0.15)
		add_child(_light_b)


func _box(pos: Vector3, size: Vector3, mat: Material) -> void:
	var m := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	m.mesh = b
	m.position = pos
	m.material_override = mat
	add_child(m)


func _add_light_pod(pos: Vector3, glow: Color, is_head: bool) -> void:
	var mat := Palette.mat(glow, 0.2, 0.15, glow, 0.2)
	if is_head:
		_head_mats.append(mat)
	else:
		_tail_mats.append(mat)
	_box(pos, Vector3(0.32, 0.14, 0.08), mat)


func _spot(pos: Vector3, color: Color) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = color
	l.light_energy = 1.5
	l.omni_range = 8.0
	add_child(l)
	return l


func _physics_process(delta: float) -> void:
	if global_position.y < -0.05:
		global_position.y = 0.16
		velocity.y = 0.0
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0

	var throttle := 0.0
	var steer := 0.0
	if occupied:
		var input := _player_input()
		steer = input.x
		throttle = -input.y
	elif ai_enabled:
		var ai := _ai_drive()
		steer = ai.x
		throttle = ai.y

	var cap := ai_max_speed if (ai_enabled and not occupied) else max_speed
	if fleeing and not occupied:
		cap *= 1.12
	if not occupied:
		cap *= clampf(0.4 + hp / 160.0, 0.35, 1.0)
	if wrecked:
		cap *= 0.12
		throttle = 0.0
	var handbrake := false
	if occupied:
		handbrake = Input.is_physical_key_pressed(KEY_SPACE)
		var pads := get_tree().get_first_node_in_group("touch") as TouchControls
		if pads and pads.handbrake:
			handbrake = true
	braking = throttle < -0.05 or handbrake
	if throttle > 0.05 and not handbrake:
		var accel := 158.0 - absf(speed) * 0.16
		speed = move_toward(speed, cap * throttle, maxf(accel, 52.0) * delta)
	elif throttle < -0.05:
		speed = move_toward(speed, -cap * 0.38, 48.0 * delta)
	else:
		speed = move_toward(speed, 0.0, (52.0 if handbrake else 8.0) * delta)

	var speed_turn := clampf(1.55 - absf(speed) / 100.0, 0.4, 1.3)
	var turn := (2.85 if handbrake else 1.9) * speed_turn
	if abs(speed) > 0.35:
		rotate_y(-steer * turn * signf(speed) * delta)

	var forward := -global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() > 0.001:
		forward = forward.normalized()
	var right := global_transform.basis.x
	right.y = 0.0
	var slip := steer * speed * (0.18 if handbrake else 0.06)
	velocity.x = forward.x * speed + right.x * slip
	velocity.z = forward.z * speed + right.z * slip
	var before := speed
	move_and_slide()
	if get_slide_collision_count() > 0 and abs(before) > 10.0:
		var head_on := 0.0
		for i in get_slide_collision_count():
			head_on = maxf(head_on, (-get_slide_collision(i).get_normal()).dot(forward))
		if head_on > 0.62:
			speed *= 0.84 if occupied else 0.68
			if abs(before) > 22.0:
				apply_damage(absf(before) * (0.22 if occupied else 1.4))
				last_impact = absf(before)
		elif occupied:
			speed = maxf(speed, before * 0.97)

	for wheel in _wheels:
		wheel.rotate_x(speed * delta * 1.35)
	for m in _tail_mats:
		m.emission_energy_multiplier = 5.5 if braking else (2.4 if _night else 0.7)

	if occupied:
		apply_time(_night)

	if kind == Kind.COP and _light_a:
		var wanted := 0
		var game := get_tree().current_scene
		if game and game.has_method("get_wanted"):
			wanted = game.get_wanted()
		_blink += delta * (10.0 if wanted > 0 else 1.2)
		var on := sin(_blink) > 0.0
		_light_a.light_energy = 4.4 if on and wanted > 0 else 0.15
		_light_b.light_energy = 4.4 if (not on) and wanted > 0 else 0.15


func _player_input() -> Vector2:
	var v := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		v.x -= 1
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		v.x += 1
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		v.y -= 1
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		v.y += 1
	var touch := get_tree().get_first_node_in_group("touch") as TouchControls
	if touch:
		v.x += touch.move.x
		if touch.gas:
			v.y -= 1
		if touch.brake:
			v.y += 1
		if abs(touch.move.y) > 0.25:
			v.y += touch.move.y
	return Vector2(clampf(v.x, -1, 1), clampf(v.y, -1, 1))


func bind_graph(g: RoadGraph) -> void:
	graph = g
	node_i = g.nearest(global_position)
	next_i = g.next_toward(node_i, global_position + (-global_transform.basis.z * 20.0))


func _ai_drive() -> Vector2:
	var dest := _ai_destination()
	if graph:
		if global_position.distance_to(graph.nodes[next_i]) < 6.0:
			prev_i = node_i
			node_i = next_i
			if fleeing:
				next_i = graph.next_away(node_i, dest)
			else:
				next_i = graph.next_toward(node_i, dest, prev_i)
		var close_chase := chase_target != null and global_position.distance_to(chase_target.global_position) < 18.0
		if not close_chase:
			dest = graph.nodes[next_i]
		var ignore_light := chase_target != null or fleeing
		if not graph.light_open(node_i, next_i, ignore_light) and global_position.distance_to(graph.nodes[next_i]) < 14.0:
			return Vector2(0.0, -0.15)
	var to := dest - global_position
	to.y = 0.0
	var dist := to.length()
	var desired := to.normalized() if dist > 0.2 else -global_transform.basis.z
	var fwd := -global_transform.basis.z
	fwd.y = 0.0
	if fwd.length_squared() > 0.001:
		fwd = fwd.normalized()
	var angle := fwd.signed_angle_to(desired, Vector3.UP)
	var steer := clampf(angle / 0.42, -1.0, 1.0)
	var space := get_world_3d().direct_space_state
	var wall := space.intersect_ray(PhysicsRayQueryParameters3D.create(
		global_position + Vector3(0, 0.6, 0),
		global_position + Vector3(0, 0.6, 0) + fwd * 8.0,
		1
	))
	if wall:
		steer += 0.85 if angle >= 0.0 else -0.85
	var car_q := PhysicsRayQueryParameters3D.create(
		global_position + Vector3(0, 0.7, 0),
		global_position + Vector3(0, 0.7, 0) + fwd * 9.0,
		4 | 8
	)
	car_q.exclude = [get_rid()]
	var car := space.intersect_ray(car_q)
	if car and not fleeing:
		return Vector2(steer * 0.3, -0.2)
	var throttle := 0.92 if dist > 10.0 else 0.45
	if chase_target and dist < 6.0:
		throttle = 0.25
	if absf(angle) > 0.9:
		throttle *= 0.45
	return Vector2(clampf(steer, -1, 1), throttle)


func _ai_destination() -> Vector3:
	if fleeing:
		var ply := get_tree().get_first_node_in_group("player") as Node3D
		if ply:
			return global_position + (global_position - ply.global_position).normalized() * 24.0
	if chase_target:
		var lead := Vector3.ZERO
		if chase_target is CharacterBody3D:
			lead = (chase_target as CharacterBody3D).velocity * 0.55
		var side := 1.0 if chase_slot % 2 == 0 else -1.0
		var flank := chase_target.global_transform.basis.x * (side * (4.0 + float(chase_slot) * 2.0))
		return chase_target.global_position + lead + flank
	if patrol.size() == 0:
		return global_position
	return patrol[patrol_i % patrol.size()]


func eject_driver() -> Pedestrian:
	if not has_driver:
		return null
	has_driver = false
	var ped := Pedestrian.new()
	ped.is_officer = kind == Kind.COP
	var parent := get_parent()
	parent.add_child(ped)
	ped.global_position = global_position + global_transform.basis.x * 1.9 + Vector3(0, 0.1, 0)
	ped.scare(global_position)
	return ped


func apply_damage(amount: float) -> void:
	hp = clampf(hp - amount, 0.0, 100.0)
	if hp <= 0.0:
		wrecked = true


func repair() -> void:
	hp = 100.0
	wrecked = false
