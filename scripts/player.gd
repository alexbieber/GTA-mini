class_name Player
extends CharacterBody3D

const Models = preload("res://scripts/models.gd")

const WALK_SPEED := 5.2
const SPRINT_SPEED := 7.6
const GRAVITY := 28.0

var in_vehicle := false
var locked := false
var health := 100.0
var stamina := 100.0
var weapon := Arsenal.Id.NONE
var owned_weapons: Array[int] = []
var ammo := {1: 0, 2: 0, 3: 0}
var _punch_cd := 0.0
var _fire_cd := 0.0
var _anim: AnimationPlayer


func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1 | 4 | 8 | 16
	floor_snap_length = 0.3
	var cap := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.34
	shape.height = 1.72
	cap.shape = shape
	cap.position.y = 0.86
	add_child(cap)
	_build_mesh()


func _build_mesh() -> void:
	var made := Models.instance_person(Models.player_skin())
	add_child(made["root"])
	_anim = made["anim"]


func set_hidden(on: bool) -> void:
	visible = not on
	collision_layer = 0 if on else 2
	collision_mask = 0 if on else (1 | 4 | 8 | 16)


func _physics_process(delta: float) -> void:
	if in_vehicle or locked:
		velocity = Vector3.ZERO
		return
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0
	var cam := get_tree().get_first_node_in_group("camera_rig") as CameraRig
	var yaw := cam.yaw if cam else rotation.y
	var input := _move_input()
	var basis := Basis(Vector3.UP, yaw)
	var dir := (basis * Vector3(input.x, 0, input.y))
	if dir.length_squared() > 1.0:
		dir = dir.normalized()
	var want_sprint := Input.is_physical_key_pressed(KEY_SHIFT) and stamina > 4.0
	if want_sprint and dir.length_squared() > 0.05:
		stamina = maxf(stamina - 18.0 * delta, 0.0)
	else:
		stamina = minf(stamina + 12.0 * delta, 100.0)
	var speed := SPRINT_SPEED if want_sprint else WALK_SPEED
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	move_and_slide()
	_punch_cd = maxf(_punch_cd - delta, 0.0)
	_fire_cd = maxf(_fire_cd - delta, 0.0)
	if dir.length_squared() > 0.05:
		var target_yaw := atan2(-dir.x, -dir.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, 1.0 - exp(-12.0 * delta))
	Models.play_move(_anim, dir.length_squared() > 0.05, want_sprint)


func _move_input() -> Vector2:
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
		v += touch.move
	return v.limit_length(1.0)


func take_damage(amount: float) -> void:
	if locked:
		return
	health = clampf(health - amount, 0.0, 100.0)


func heal(amount: float) -> void:
	health = clampf(health + amount, 0.0, 100.0)


func try_punch() -> Pedestrian:
	if in_vehicle or locked or _punch_cd > 0.0:
		return null
	_punch_cd = 0.45
	var reach := global_position + (-global_transform.basis.z * 1.5)
	var best: Pedestrian = null
	var best_d := 1.7
	for node in get_tree().get_nodes_in_group("peds"):
		var ped := node as Pedestrian
		if ped == null or ped.downed or ped.is_officer:
			continue
		var d := reach.distance_to(ped.global_position)
		if d < best_d:
			best_d = d
			best = ped
	if best:
		best.knock_down()
		velocity += -global_transform.basis.z * 4.5
	return best


func give_weapon(id: int, rounds := -1) -> void:
	if id == Arsenal.Id.NONE:
		return
	if not owned_weapons.has(id):
		owned_weapons.append(id)
	weapon = id
	var extra: int = rounds if rounds >= 0 else int(Arsenal.spec(id)["ammo"])
	ammo[id] = int(ammo.get(id, 0)) + extra


func add_ammo(rounds := 40) -> void:
	if weapon == Arsenal.Id.NONE:
		return
	ammo[weapon] = int(ammo.get(weapon, 0)) + rounds


func cycle_weapon(dir: int) -> void:
	if owned_weapons.is_empty():
		weapon = Arsenal.Id.NONE
		return
	var i := owned_weapons.find(weapon)
	i = (i + dir) % owned_weapons.size()
	if i < 0:
		i = owned_weapons.size() - 1
	weapon = owned_weapons[i]


func select_weapon(id: int) -> bool:
	if id == Arsenal.Id.NONE:
		weapon = Arsenal.Id.NONE
		return true
	if not owned_weapons.has(id):
		return false
	weapon = id
	return true


func can_fire() -> bool:
	if in_vehicle or locked or weapon == Arsenal.Id.NONE or _fire_cd > 0.0:
		return false
	return int(ammo.get(weapon, 0)) > 0


func spend_shot() -> Dictionary:
	if not can_fire():
		return {}
	var spec := Arsenal.spec(weapon)
	ammo[weapon] = int(ammo.get(weapon, 0)) - 1
	_fire_cd = float(spec["rate"])
	return spec


func weapon_label() -> String:
	if weapon == Arsenal.Id.NONE:
		return ""
	return "%s  %d" % [Arsenal.spec(weapon)["name"], int(ammo.get(weapon, 0))]


func try_punch_officer() -> Pedestrian:
	if in_vehicle or locked or _punch_cd > 0.0:
		return null
	var reach := global_position + (-global_transform.basis.z * 1.6)
	for node in get_tree().get_nodes_in_group("foot_cops"):
		var ped := node as Pedestrian
		if ped == null or ped.downed:
			continue
		if reach.distance_to(ped.global_position) < 1.8:
			_punch_cd = 0.45
			ped.knock_down()
			velocity += -global_transform.basis.z * 4.5
			return ped
	return null
