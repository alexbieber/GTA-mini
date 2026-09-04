class_name Aircraft
extends CharacterBody3D

const GRAVITY := 18.0

const Models = preload("res://scripts/models.gd")

var occupied := false
var display_name := "AN-2"
var speed := 0.0
var max_speed := 88.0
var hp := 140.0
var wrecked := false
var _near: Area3D
var _night := true


func setup(spawn: Vector3, facing_y := 0.0) -> void:
	if is_inside_tree():
		global_position = spawn
		rotation.y = facing_y
	else:
		position = spawn
		rotation.y = facing_y


func _ready() -> void:
	add_to_group("aircraft")
	add_to_group("time_sensitive")
	collision_layer = 4
	collision_mask = 1 | 4 | 8
	motion_mode = MOTION_MODE_FLOATING
	floor_snap_length = 0.0
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.6, 2.0, 8.4)
	col.shape = box
	col.position.y = 1.15
	add_child(col)
	_build_mesh()
	_near = Area3D.new()
	_near.collision_layer = 0
	_near.collision_mask = 2
	_near.monitoring = true
	var ac := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 8.5
	ac.shape = sph
	ac.position.y = 1.0
	_near.add_child(ac)
	add_child(_near)


func can_board(who: Node3D) -> bool:
	if wrecked or occupied or who == null:
		return false
	if global_position.distance_to(who.global_position) < 9.5:
		return true
	if _near:
		for body in _near.get_overlapping_bodies():
			if body == who:
				return true
	return false


func apply_time(night: bool) -> void:
	_night = night


func _build_mesh() -> void:
	add_child(Models.instance_plane(false))
	var glow := Palette.mat(Color("ff5533"), 0.2, 0.2, Color("ff5533"), 2.4)
	_box(Vector3(-0.45, 1.15, 5.1), Vector3(0.28, 0.18, 0.12), glow)
	_box(Vector3(0.45, 1.15, 5.1), Vector3(0.28, 0.18, 0.12), glow)


func _box(pos: Vector3, size: Vector3, mat: Material) -> void:
	var m := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	m.mesh = b
	m.position = pos
	m.material_override = mat
	add_child(m)


func _physics_process(delta: float) -> void:
	if wrecked:
		velocity.y -= GRAVITY * delta
		move_and_slide()
		return
	var throttle := 0.0
	var yaw_in := 0.0
	var pitch_in := 0.0
	if occupied:
		if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
			throttle += 1.0
		if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
			throttle -= 1.0
		if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
			yaw_in -= 1.0
		if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
			yaw_in += 1.0
		var touch := get_tree().get_first_node_in_group("touch") as TouchControls
		if touch:
			yaw_in += touch.move.x
			if touch.gas:
				throttle += 1.0
			if touch.brake:
				throttle -= 1.0
		var cam := get_tree().get_first_node_in_group("camera_rig") as CameraRig
		if cam:
			pitch_in = clampf(-cam.pitch * 2.4, -1.0, 1.0)
	if occupied:
		collision_mask = 8 if (speed > 14.0 or global_position.y > 3.0) else (1 | 4 | 8)
		speed = move_toward(speed, max_speed * clampf(throttle, -0.25, 1.0), (62.0 if throttle > 0.0 else 28.0) * delta)
		rotate_y(-yaw_in * 1.35 * delta)
		rotation.x = lerp_angle(rotation.x, pitch_in * 0.42, 4.0 * delta)
		rotation.z = lerp_angle(rotation.z, -yaw_in * 0.28, 4.0 * delta)
		var fwd := -global_transform.basis.z
		velocity = fwd * speed
		if speed < 12.0 and global_position.y <= 2.8:
			if not is_on_floor():
				velocity.y -= GRAVITY * delta
			else:
				velocity.y = 0.0
				rotation.x = move_toward(rotation.x, 0.0, 2.0 * delta)
				global_position.y = maxf(global_position.y, 0.55)
		else:
			velocity.y += pitch_in * 22.0 * delta
			if throttle > 0.2:
				velocity.y += 10.0 * delta
			if global_position.y < 1.4:
				global_position.y = 1.4
				velocity.y = maxf(velocity.y, 4.0)
	else:
		collision_mask = 1 | 4 | 8
		speed = move_toward(speed, 0.0, 14.0 * delta)
		rotation.x = move_toward(rotation.x, 0.0, 2.5 * delta)
		rotation.z = move_toward(rotation.z, 0.0, 2.5 * delta)
		if not is_on_floor():
			velocity.y -= GRAVITY * delta
		else:
			velocity.y = 0.0
		velocity.x = 0.0
		velocity.z = 0.0
		if global_position.y < 0.2:
			global_position.y = 0.35
	move_and_slide()
	if get_slide_collision_count() > 0 and speed > 18.0:
		apply_damage(speed * 0.8)
		speed *= 0.4


func apply_damage(amount: float) -> void:
	hp = clampf(hp - amount, 0.0, 140.0)
	if hp <= 0.0:
		wrecked = true
