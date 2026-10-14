class_name Player
extends CharacterBody3D

const Models = preload("res://scripts/models.gd")
const Movement = preload("res://scripts/locomotion.gd")
const Cover = preload("res://scripts/cover_controller.gd")

const WALK_SPEED := 5.2
const SPRINT_SPEED := 7.6
const GRAVITY := 28.0

var in_vehicle := false
var locked := false
var vitality := HealthComponent.new()
var health: float:
	get: return vitality.current
	set(value): vitality.current = clampf(value, 0.0, vitality.maximum)
var stamina := 100.0
var weapon := Arsenal.Id.NONE
var owned_weapons: Array[int] = []
var ammo := {1: 0, 2: 0, 3: 0, 4: 0}
var magazines: Dictionary = {}
var reload_remaining := 0.0
var _reload_weapon := Arsenal.Id.NONE
var aiming := false
var combat_remaining := 0.0
var crouched := false
var movement_state := "Idle"
var slide_remaining := 0.0
var slide_cooldown := 0.0
var tactical_remaining := 0.0
var tactical_cooldown := 0.0
var _slide_direction := Vector3.ZERO
var _capsule: CollisionShape3D
var _visual: Node3D
var _visual_scale := Vector3.ONE
var _gun: Node3D
var _gun_kick := 0.0
var uniform_color := Color.WHITE
var _skin_materials: Array[ShaderMaterial] = []
var in_cover := false
var _cover_normal := Vector3.ZERO
var _cover_low := false
var _cover_was_crouched := false
var _punch_cd := 0.0
var _fire_cd := 0.0
var _anim: AnimationPlayer
var locomotion := Movement.new()
var tactical: TacticalConfig
var armor_plates := 0
var plate_remaining := 0.0
var sprint_to_fire_remaining := 0.0
var sprinting := false
var _sprint_block_remaining := 0.0
var first_person_visual := false
var vault_remaining := 0.0
var _vault_points: Array[Vector3] = []
var _vault_stage := 0
var _vault_stage_time := 0.0


func request_jump() -> void:
	if not locked and not in_vehicle:
		if vault_remaining > 0.0: return
		exit_cover()
		if tactical and try_mantle(): return
		if tactical and slide_remaining > 0.0 and set_crouched(false):
			slide_remaining = 0.0
		locomotion.request_jump()


func _ready() -> void:
	CombatInput.install()
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
	_capsule = cap
	_build_mesh()
	_build_gun()


func _build_mesh() -> void:
	var made := Models.instance_urban_player()
	add_child(made["root"])
	_visual = made["root"]
	Models.normalize_person(_visual)
	for node in _visual.find_children("*", "MeshInstance3D", true, false):
		if node.material_override is ShaderMaterial:
			node.material_override.set_shader_parameter("shirt_color", uniform_color)
			_skin_materials.append(node.material_override)
	_visual_scale = _visual.scale
	_anim = made["anim"]


func set_hidden(on: bool) -> void:
	if on:
		reset_combat()
	visible = not on
	collision_layer = 0 if on else 2
	collision_mask = 0 if on else (1 | 4 | 8 | 16)


func _physics_process(delta: float) -> void:
	_update_skin()
	if in_vehicle or locked:
		reset_combat()
		movement_state = "Death" if health <= 0.0 else "Idle"
		velocity = Vector3.ZERO
		locomotion.reset()
		return
	tick_combat(delta)
	if vault_remaining > 0.0:
		_tick_mantle(delta)
		return
	slide_cooldown = maxf(slide_cooldown - delta, 0.0)
	tactical_cooldown = maxf(tactical_cooldown - delta, 0.0)
	tactical_remaining = maxf(tactical_remaining - delta, 0.0)
	var touch_input := get_tree().get_first_node_in_group("touch") as TouchControls
	aiming = weapon != Arsenal.Id.NONE and (Input.is_action_pressed("aim") or (touch_input != null and touch_input.aiming)) and slide_remaining <= 0.0 and plate_remaining <= 0.0
	if tactical and aiming:
		tactical_remaining = 0.0
	if tactical and Input.is_action_pressed("armor_plate"):
		request_plate()
	if Input.is_action_just_pressed("crouch"):
		request_crouch()
	if Input.is_action_just_pressed("cover"):
		request_cover()
	if in_cover and not Cover.retains_contact(self, _cover_normal):
		exit_cover()
	if in_cover and _cover_low:
		set_crouched(not aiming)
	if Input.is_action_just_pressed("tactical_sprint"):
		request_tactical_sprint()
	var grounded := is_on_floor()
	if locomotion.tick(delta, grounded):
		velocity.y = Movement.JUMP_SPEED
	elif not grounded:
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0
	var cam := get_tree().get_first_node_in_group("camera_rig") as CameraRig
	var yaw := control_yaw()
	var input := _move_input()
	var basis := Basis(Vector3.UP, yaw)
	var dir := (basis * Vector3(input.x, 0, input.y))
	if dir.length_squared() > 1.0:
		dir = dir.normalized()
	if in_cover:
		if dir.dot(_cover_normal) > 0.55:
			exit_cover()
		else:
			var tangent := _cover_normal.cross(Vector3.UP).normalized()
			dir = tangent * dir.dot(tangent)
	var touch := get_tree().get_first_node_in_group("touch") as TouchControls
	var sprint_input := Input.is_action_pressed("sprint") or (touch != null and touch.sprint)
	var fire_held := Input.is_action_pressed("fire") or (touch != null and touch.firing)
	var want_sprint := (sprint_input or tactical_remaining > 0.0) and stamina > 4.0 and not aiming and not crouched and not in_cover and reload_remaining <= 0.0 and plate_remaining <= 0.0 and _sprint_block_remaining <= 0.0 and (tactical == null or not fire_held)
	sprinting = want_sprint and dir.length_squared() > 0.05
	if want_sprint and dir.length_squared() > 0.05:
		stamina = maxf(stamina - 18.0 * delta, 0.0)
	else:
		stamina = minf(stamina + 12.0 * delta, 100.0)
	var speed := SPRINT_SPEED if want_sprint else WALK_SPEED
	if weapon != Arsenal.Id.NONE:
		speed *= Arsenal.data(weapon).mobility
	if crouched:
		speed = 2.4
	elif aiming:
		speed *= 0.55
	elif want_sprint and tactical_remaining > 0.0:
		speed *= 1.3
	if slide_remaining > 0.0:
		slide_remaining = maxf(slide_remaining - delta, 0.0)
		dir = _slide_direction
		speed = lerpf(3.0, 10.0, slide_remaining / 0.65)
	if tactical and slide_remaining <= 0.0:
		var rate := tactical.deceleration if dir.length_squared() < 0.01 else tactical.acceleration
		var planar := Vector2(velocity.x, velocity.z).move_toward(Vector2(dir.x, dir.z) * speed, rate * delta)
		velocity.x = planar.x
		velocity.z = planar.y
	else:
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
	try_step(Vector3(velocity.x, 0, velocity.z) * delta)
	move_and_slide()
	_punch_cd = maxf(_punch_cd - delta, 0.0)
	if in_cover and not aiming:
		rotation.y = lerp_angle(rotation.y, atan2(_cover_normal.x, _cover_normal.z), 1.0 - exp(-24.0 * delta))
	elif aiming or combat_remaining > 0.0:
		rotation.y = lerp_angle(rotation.y, yaw, 1.0 - exp(-24.0 * delta))
	elif dir.length_squared() > 0.05:
		var target_yaw := atan2(-dir.x, -dir.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, 1.0 - exp(-12.0 * delta))
	# Reuse shipped clips; a dedicated jump animation is still pending.
	Models.play_move(_anim, is_on_floor() and dir.length_squared() > 0.05, want_sprint)
	movement_state = "Idle" if dir.length_squared() < 0.05 else ("Sprint" if want_sprint else "Jog")
	if crouched: movement_state = "Crouch" if dir.length_squared() < 0.05 else "Crouch Walk"
	if in_cover: movement_state = "Cover"
	if tactical_remaining > 0.0 and want_sprint: movement_state = "Tactical Sprint"
	if aiming: movement_state = "Aim"
	if reload_remaining > 0.0: movement_state = "Reload"
	if slide_remaining > 0.0: movement_state = "Slide"
	if plate_remaining > 0.0: movement_state = "Armor Plate"
	if not is_on_floor(): movement_state = "Jump" if velocity.y > 0.0 else "Fall"
	elif not grounded: movement_state = "Land"
	if _visual:
		_visual.scale.y = lerpf(_visual.scale.y, _visual_scale.y * (0.65 if crouched else 1.0), 1.0 - exp(-16.0 * delta))
	if _gun:
		_gun.visible = weapon != Arsenal.Id.NONE and not first_person_visual and plate_remaining <= 0.0
		_gun_kick = move_toward(_gun_kick, 0.0, delta * 0.5)
		_gun.position = Vector3(0.32, 0.82 if crouched else 1.22, -0.38 + _gun_kick)
		_gun.rotation.x = (cam.pitch if cam else 0.0) - (0.5 if reload_remaining > 0.0 else 0.0)
		_gun.scale.z = 0.5 if weapon == Arsenal.Id.PISTOL else 1.0


func _move_input() -> Vector2:
	var v := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if Input.is_physical_key_pressed(KEY_LEFT):
		v.x -= 1
	if Input.is_physical_key_pressed(KEY_RIGHT):
		v.x += 1
	if Input.is_physical_key_pressed(KEY_UP):
		v.y -= 1
	if Input.is_physical_key_pressed(KEY_DOWN):
		v.y += 1
	var touch := get_tree().get_first_node_in_group("touch") as TouchControls
	if touch:
		v += touch.move
	return v.limit_length(1.0)

func control_yaw() -> float:
	var cam := get_tree().get_first_node_in_group("camera_rig") as CameraRig
	return cam.yaw if cam else rotation.y


func take_damage(amount: float, bypass_armor := false) -> void:
	if locked:
		return
	if amount > 0.0: cancel_plate()
	vitality.apply_damage(amount, 1.0, bypass_armor)


func heal(amount: float) -> void:
	vitality.heal(amount)


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
	cancel_plate()
	weapon = id
	reload_remaining = 0.0
	var extra: int = rounds if rounds >= 0 else int(Arsenal.spec(id)["ammo"])
	ammo[id] = int(ammo.get(id, 0)) + extra
	if not magazines.has(id):
		var loaded := mini(Arsenal.data(id).magazine_size, int(ammo[id]))
		magazines[id] = loaded
		ammo[id] -= loaded


func add_ammo(rounds := 40) -> void:
	if weapon == Arsenal.Id.NONE:
		return
	ammo[weapon] = int(ammo.get(weapon, 0)) + rounds


func cycle_weapon(dir: int) -> void:
	cancel_plate()
	if owned_weapons.is_empty():
		weapon = Arsenal.Id.NONE
		return
	var i := owned_weapons.find(weapon)
	i = (i + dir) % owned_weapons.size()
	if i < 0:
		i = owned_weapons.size() - 1
	weapon = owned_weapons[i]
	reload_remaining = 0.0


func select_weapon(id: int) -> bool:
	if id == Arsenal.Id.NONE:
		cancel_plate()
		weapon = Arsenal.Id.NONE
		reload_remaining = 0.0
		return true
	if not owned_weapons.has(id):
		return false
	cancel_plate()
	weapon = id
	reload_remaining = 0.0
	return true


func can_fire() -> bool:
	if in_vehicle or locked or health <= 0.0 or weapon == Arsenal.Id.NONE or _fire_cd > 0.0 or reload_remaining > 0.0 or slide_remaining > 0.0 or tactical_remaining > 0.0 or plate_remaining > 0.0 or sprint_to_fire_remaining > 0.0 or vault_remaining > 0.0:
		return false
	return int(magazines.get(weapon, 0)) > 0


func spend_shot() -> Dictionary:
	if tactical and not locked and not in_vehicle and health > 0.0:
		cancel_plate()
		if sprinting or tactical_remaining > 0.0:
			tactical_remaining = 0.0
			sprinting = false
			sprint_to_fire_remaining = tactical.sprint_to_fire_seconds
			_sprint_block_remaining = 0.3
	if not can_fire():
		return {}
	var spec := Arsenal.spec(weapon)
	magazines[weapon] = int(magazines.get(weapon, 0)) - 1
	_fire_cd = float(spec["rate"])
	combat_remaining = 2.0
	_gun_kick = 0.07
	movement_state = "Fire"
	return spec


func weapon_label() -> String:
	if weapon == Arsenal.Id.NONE:
		return ""
	return "%s  %d / %d%s" % [Arsenal.spec(weapon)["name"], int(magazines.get(weapon, 0)), int(ammo.get(weapon, 0)), "  RELOADING" if reload_remaining > 0.0 else ""]

func request_reload() -> bool:
	if locked or in_vehicle or weapon == Arsenal.Id.NONE or reload_remaining > 0.0 or vault_remaining > 0.0:
		return false
	if int(ammo.get(weapon, 0)) <= 0 or int(magazines.get(weapon, 0)) >= Arsenal.data(weapon).magazine_size:
		return false
	cancel_plate()
	_reload_weapon = weapon
	reload_remaining = Arsenal.data(weapon).reload_seconds
	return true

func tick_combat(delta: float) -> void:
	vitality.tick(delta)
	sprint_to_fire_remaining = maxf(sprint_to_fire_remaining - delta, 0.0)
	_sprint_block_remaining = maxf(_sprint_block_remaining - delta, 0.0)
	if plate_remaining > 0.0:
		if locked or in_vehicle or health <= 0.0:
			cancel_plate()
		else:
			plate_remaining = maxf(plate_remaining - delta, 0.0)
			if plate_remaining == 0.0 and tactical and armor_plates > 0:
				armor_plates -= 1
				vitality.armor = minf(vitality.armor + tactical.plate_value, tactical.armor_maximum)
	_fire_cd = maxf(_fire_cd - delta, 0.0)
	combat_remaining = maxf(combat_remaining - delta, 0.0)
	if reload_remaining <= 0.0:
		return
	reload_remaining = maxf(reload_remaining - delta, 0.0)
	if reload_remaining == 0.0 and weapon == _reload_weapon:
		var amount := mini(Arsenal.data(weapon).magazine_size - int(magazines.get(weapon, 0)), int(ammo.get(weapon, 0)))
		magazines[weapon] = int(magazines.get(weapon, 0)) + amount
		ammo[weapon] -= amount

func reset_combat() -> void:
	cancel_plate()
	sprint_to_fire_remaining = 0.0
	_sprint_block_remaining = 0.0
	sprinting = false
	vault_remaining = 0.0
	_vault_points.clear()
	exit_cover()
	aiming = false
	reload_remaining = 0.0
	combat_remaining = 0.0
	slide_remaining = 0.0
	tactical_remaining = 0.0
	_fire_cd = 0.0

func configure_tactical(config: TacticalConfig) -> void:
	tactical = config
	vitality.armor_first = config != null
	vitality.regeneration_delay = config.regeneration_delay if config else 0.0
	vitality.regeneration_per_second = config.regeneration_per_second if config else 0.0
	armor_plates = config.starting_plates if config else 0
	reset_combat()

func request_plate() -> bool:
	if tactical == null or locked or in_vehicle or health <= 0.0 or armor_plates <= 0 or vitality.armor >= tactical.armor_maximum or plate_remaining > 0.0 or reload_remaining > 0.0 or slide_remaining > 0.0 or vault_remaining > 0.0:
		return false
	plate_remaining = tactical.plate_seconds
	tactical_remaining = 0.0
	aiming = false
	return true

func cancel_plate() -> void:
	plate_remaining = 0.0

func add_plates(count: int) -> int:
	if tactical == null: return 0
	var before := armor_plates
	armor_plates = clampi(armor_plates + maxi(count, 0), 0, tactical.plate_capacity)
	return armor_plates - before

func request_tactical_sprint() -> bool:
	if locked or in_vehicle or health <= 0.0 or tactical_cooldown > 0.0 or stamina <= 30.0 or not is_on_floor() or crouched or in_cover or aiming or reload_remaining > 0.0 or plate_remaining > 0.0 or _sprint_block_remaining > 0.0 or _move_input().length_squared() <= 0.05:
		return false
	tactical_remaining = 1.4
	tactical_cooldown = 4.0
	return true

func set_first_person_visual(on: bool) -> void:
	first_person_visual = on
	if _visual: _visual.visible = not on
	if _gun: _gun.visible = not on and weapon != Arsenal.Id.NONE and plate_remaining <= 0.0

func try_mantle() -> bool:
	if tactical == null or locked or in_vehicle or health <= 0.0 or not is_on_floor() or vault_remaining > 0.0 or _move_input().length_squared() < 0.05:
		return false
	var yaw := control_yaw()
	var direction := (Basis(Vector3.UP, yaw) * Vector3(_move_input().x, 0, _move_input().y)).normalized()
	var space := get_world_3d().direct_space_state
	var low := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.4, global_position + Vector3.UP * 0.4 + direction * 1.15, 1, [get_rid()])
	var obstacle := space.intersect_ray(low)
	if obstacle.is_empty() or absf(obstacle.normal.y) > 0.3: return false
	var over: Vector3 = obstacle.position + direction * 0.18
	var high := global_position.y + tactical.mantle_maximum_height + 0.12
	var top := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(over.x, high, over.z), Vector3(over.x, global_position.y + 0.2, over.z), 1))
	if top.is_empty() or top.normal.y < 0.7: return false
	var height: float = top.position.y - global_position.y
	if height < 0.25 or height > tactical.mantle_maximum_height: return false
	var across := global_position + direction * tactical.mantle_reach
	var floor_hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(across.x, high, across.z), Vector3(across.x, global_position.y - 0.25, across.z), 1))
	if floor_hit.is_empty() or floor_hit.normal.y < 0.7: return false
	var destination: Vector3 = floor_hit.position + Vector3.UP * 0.055
	var raised := Vector3(global_position.x, maxf(top.position.y, destination.y) + 0.08, global_position.z)
	var across_high := Vector3(destination.x, raised.y, destination.z)
	var shape := CapsuleShape3D.new()
	shape.radius = 0.34
	shape.height = 1.72
	# Validate all three segments with the standing capsule, including overhead space.
	var path: Array[Vector3] = [global_position, raised, across_high, destination]
	for i in 3:
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = shape
		query.transform = Transform3D(Basis.IDENTITY, path[i] + Vector3.UP * 0.87)
		query.motion = path[i + 1] - path[i]
		query.exclude = [get_rid()]
		query.collision_mask = collision_mask
		query.margin = 0.001
		if not space.intersect_shape(query, 1).is_empty() or space.cast_motion(query)[0] < 0.999:
			return false
	if not set_crouched(false): return false
	exit_cover()
	cancel_plate()
	slide_remaining = 0.0
	tactical_remaining = 0.0
	sprinting = false
	_vault_points = path
	_vault_stage = 0
	_vault_stage_time = 0.0
	vault_remaining = 0.42
	velocity = Vector3.ZERO
	return true

func _tick_mantle(delta: float) -> void:
	if vault_remaining <= 0.0 or _vault_points.size() != 4: return
	var durations := [0.12, 0.17, 0.13]
	var budget := delta
	while budget > 0.0 and _vault_stage < 3:
		var consumed := minf(budget, durations[_vault_stage] - _vault_stage_time)
		_vault_stage_time += consumed
		budget -= consumed
		var target := _vault_points[_vault_stage].lerp(_vault_points[_vault_stage + 1], clampf(_vault_stage_time / durations[_vault_stage], 0.0, 1.0))
		if move_and_collide(target - global_position):
			vault_remaining = 0.0
			velocity = Vector3.ZERO
			return
		vault_remaining = maxf(vault_remaining - consumed, 0.0)
		if _vault_stage_time >= durations[_vault_stage] - 0.000001:
			_vault_stage += 1
			_vault_stage_time = 0.0
	if _vault_stage >= 3: vault_remaining = 0.0
	movement_state = "Mantle" if vault_remaining > 0.0 else "Idle"

func request_crouch() -> void:
	if locked or in_vehicle:
		return
	if crouched:
		set_crouched(false)
	else:
		if is_on_floor() and Vector2(velocity.x, velocity.z).length() > 6.0 and slide_cooldown <= 0.0 and not aiming:
			slide_remaining = 0.65
			slide_cooldown = 1.6
			_slide_direction = Vector3(velocity.x, 0.0, velocity.z).normalized()
		set_crouched(true)

func set_crouched(on: bool) -> bool:
	if _capsule == null:
		return false
	if on == crouched:
		return true
	if not on:
		var shape := CapsuleShape3D.new()
		shape.radius = 0.34
		shape.height = 1.72
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = shape
		query.transform = Transform3D(Basis.IDENTITY, global_position + Vector3(0, 0.89, 0))
		query.collision_mask = collision_mask
		query.exclude = [get_rid()]
		query.margin = 0.0
		if not get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty():
			return false
	crouched = on
	(_capsule.shape as CapsuleShape3D).height = 1.1 if on else 1.72
	_capsule.position.y = 0.55 if on else 0.86
	return true

func _build_gun() -> void:
	_gun = Node3D.new()
	add_child(_gun)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("28303a")
	material.metallic = 0.65
	material.roughness = 0.4
	for part in [Vector3(0.12, 0.13, 0.6), Vector3(0.09, 0.23, 0.11)]:
		var mesh := MeshInstance3D.new()
		var geometry := BoxMesh.new()
		geometry.size = part
		mesh.mesh = geometry
		mesh.material_override = material
		mesh.position = Vector3(0, 0, -0.2) if part.z > 0.2 else Vector3(0, -0.12, -0.1)
		_gun.add_child(mesh)
	_gun.visible = false

func try_step(motion: Vector3) -> void:
	if not is_on_floor() or motion.length_squared() < 0.00001 or slide_remaining > 0.0:
		return
	if not test_move(global_transform, motion):
		return
	var lift := Vector3.UP * 0.26
	if test_move(global_transform, lift):
		return
	var raised := global_transform.translated(lift)
	if test_move(raised, motion):
		return
	if test_move(raised.translated(motion), Vector3.DOWN * 0.36):
		global_position.y += 0.26

func request_cover() -> bool:
	if locked or in_vehicle or not is_on_floor(): return false
	if in_cover:
		exit_cover()
		return true
	var found := Cover.detect(self)
	if found.is_empty(): return false
	_cover_was_crouched = crouched
	if found.low: set_crouched(true)
	var target: Vector3 = found.point + found.normal * 0.48
	target.y = global_position.y
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _capsule.shape
	query.transform = Transform3D(Basis.IDENTITY, target + Vector3.UP * (_capsule.position.y + 0.04))
	query.exclude = [get_rid()]
	query.collision_mask = collision_mask
	query.margin = 0.0
	if not get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty():
		set_crouched(_cover_was_crouched)
		return false
	global_position = target
	_cover_normal = found.normal
	_cover_low = found.low
	in_cover = true
	return true

func exit_cover() -> void:
	if not in_cover: return
	in_cover = false
	if _cover_low and not _cover_was_crouched and is_inside_tree():
		set_crouched(false)

func _update_skin() -> void:
	for material in _skin_materials:
		material.set_shader_parameter("character_origin", global_position)
		material.set_shader_parameter("character_right", global_basis.x)
		material.set_shader_parameter("character_height", 1.55 * (_visual.scale.y / _visual_scale.y if _visual else 1.0))


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
