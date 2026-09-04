class_name Pedestrian
extends CharacterBody3D

const Models = preload("res://scripts/models.gd")

enum Mood { WALK, WAIT, LOOK, FLEE, COWER, CHASE, DOWN }

const WALK_SPEED := 1.65
const FLEE_SPEED := 5.6

var path: Array[Vector3] = []
var path_i := 0
var mood: Mood = Mood.WALK
var downed := false
var is_officer := false

var _down_t := 0.0
var _wait_t := 0.0
var _look: Node3D
var _anim: AnimationPlayer


func setup(p_path: Array[Vector3], start_i: int, slots := 6) -> void:
	path = p_path
	if path.size() >= 2:
		var n := maxi(slots, 1)
		var t := (float(posmod(start_i, n)) + 0.12) / float(n)
		global_position = path[0].lerp(path[1], clampf(t, 0.04, 0.96))
		path_i = 1
	elif path.size() == 1:
		path_i = 0
		global_position = path[0]


func _ready() -> void:
	add_to_group("peds")
	if is_officer:
		add_to_group("foot_cops")
	collision_layer = 16
	collision_mask = 1 | 4 | 8
	floor_snap_length = 0.25
	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.28
	shape.height = 1.6
	col.shape = shape
	col.position.y = 0.8
	add_child(col)
	_mesh()


func knock_down() -> void:
	if downed:
		return
	downed = true
	mood = Mood.DOWN
	_down_t = 7.0 if not is_officer else 3.2
	rotation.z = 1.15


func scare(from: Vector3) -> void:
	if downed:
		return
	if is_officer:
		mood = Mood.CHASE
		return
	if randf() < 0.28:
		mood = Mood.COWER
		_wait_t = 2.2
		return
	mood = Mood.FLEE
	var away := global_position + (global_position - from).normalized() * (12.0 + randf() * 10.0)
	away.y = 0.15
	path = [away, path[path_i] if path.size() else global_position]
	path_i = 0


func _mesh() -> void:
	var skin := Models.officer_skin() if is_officer else Models.civilian_skin()
	var made := Models.instance_person(skin)
	add_child(made["root"])
	_anim = made["anim"]


func _physics_process(delta: float) -> void:
	if downed:
		_down_t -= delta
		velocity = Vector3.ZERO
		Models.play_move(_anim, false)
		if _down_t <= 0.0:
			downed = false
			mood = Mood.CHASE if is_officer else Mood.WALK
			rotation.z = 0.0
		return
	if not is_on_floor():
		velocity.y -= 24.0 * delta
	else:
		velocity.y = 0.0

	if mood == Mood.COWER or mood == Mood.WAIT or mood == Mood.LOOK:
		_wait_t -= delta
		velocity.x = 0.0
		velocity.z = 0.0
		if _look:
			var to := _look.global_position - global_position
			rotation.y = lerp_angle(rotation.y, atan2(-to.x, -to.z), 6.0 * delta)
		if _wait_t <= 0.0:
			mood = Mood.WALK
		Models.play_move(_anim, false)
		move_and_slide()
		return

	if mood == Mood.CHASE:
		var ply := get_tree().get_first_node_in_group("player") as Node3D
		if ply:
			var to := ply.global_position - global_position
			to.y = 0.0
			if to.length() > 0.2:
				var dir := to.normalized()
				velocity.x = dir.x * 6.1
				velocity.z = dir.z * 6.1
				rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), 10.0 * delta)
		Models.play_move(_anim, true, true)
		move_and_slide()
		return

	if path.size() == 0:
		return
	var dest: Vector3 = path[path_i % path.size()]
	var to := dest - global_position
	to.y = 0.0
	if to.length() < 1.1:
		path_i = (path_i + 1) % path.size()
		if mood == Mood.FLEE and path_i == 0:
			mood = Mood.WALK
		elif mood == Mood.WALK and randf() < 0.34:
			mood = Mood.WAIT
			_wait_t = randf_range(0.8, 2.6)
			var ply := get_tree().get_first_node_in_group("player") as Node3D
			if ply and global_position.distance_to(ply.global_position) < 8.0:
				mood = Mood.LOOK
				_look = ply
	var fwd := to.normalized() if to.length() > 0.05 else Vector3.ZERO
	# Don't walk into traffic.
	var space := get_world_3d().direct_space_state
	var car := space.intersect_ray(PhysicsRayQueryParameters3D.create(
		global_position + Vector3(0, 0.8, 0),
		global_position + Vector3(0, 0.8, 0) + fwd * 2.4,
		4 | 8
	))
	if car:
		mood = Mood.WAIT
		_wait_t = 0.7
		velocity = Vector3.ZERO
		move_and_slide()
		return
	var spd := FLEE_SPEED if mood == Mood.FLEE else WALK_SPEED
	velocity.x = fwd.x * spd
	velocity.z = fwd.z * spd
	move_and_slide()
	if fwd.length_squared() > 0.01:
		rotation.y = lerp_angle(rotation.y, atan2(-fwd.x, -fwd.z), 1.0 - exp(-8.0 * delta))
	Models.play_move(_anim, fwd.length_squared() > 0.01, mood == Mood.FLEE)
