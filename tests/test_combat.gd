extends SceneTree
var checks := 0
var failures := 0

class TestPlayer extends Player:
	func _build_mesh() -> void:
		_visual = Node3D.new()
		_visual.scale = Vector3.ONE * 0.62
		_visual_scale = _visual.scale
		add_child(_visual)

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: " + label)
	else:
		print("PASS: " + label)

func frames(n: int) -> void:
	for i in n:
		await physics_frame
		await process_frame

func box(parent: Node3D, position: Vector3, dimensions: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = dimensions
	col.shape = shape
	body.add_child(col)
	parent.add_child(body)
	body.position = position
	return body

func run() -> void:
	CombatInput.install()
	check(InputMap.has_action("aim") and InputMap.has_action("reload"), "configurable combat actions installed")
	var keyboard := InputEventKey.new()
	keyboard.physical_keycode = KEY_W
	keyboard.pressed = true
	check(keyboard.is_action_pressed("move_forward"), "physical keyboard event matches serialized movement binding")
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_RIGHT
	mouse.pressed = true
	check(mouse.is_action_pressed("aim"), "mouse button matches serialized ADS binding")
	var custom := InputEventKey.new()
	custom.physical_keycode = KEY_Z
	InputMap.action_add_event("reload", custom)
	CombatInput.install()
	check(InputMap.action_get_events("reload").size() == 2, "custom bindings survive defaults")
	var p := TestPlayer.new()
	p.give_weapon(Arsenal.Id.PISTOL)
	check(p.magazines[1] == 12 and p.ammo[1] == 24, "initial ammunition split conserves total")
	check(not p.request_reload(), "full magazine rejects reload")
	var shot := p.spend_shot()
	check(not shot.is_empty() and p.magazines[1] == 11 and p.ammo[1] == 24, "shot spends only magazine")
	check(p.spend_shot().is_empty(), "cadence prevents duplicate shot")
	p.tick_combat(0.3)
	check(p.request_reload(), "partial magazine starts reload")
	check(not p.can_fire(), "reload blocks fire")
	p.tick_combat(0.4)
	check(p.magazines[1] == 11 and p.ammo[1] == 24, "reload does not grant early ammunition")
	p.give_weapon(Arsenal.Id.RIFLE, 31)
	p.tick_combat(5.0)
	check(p.magazines[1] == 11 and p.ammo[1] == 24, "weapon switch cancels reload without losing ammunition")
	check(p.magazines[3] == 30 and p.ammo[3] == 1, "rifle magazine and reserve independent")
	p.select_weapon(1)
	p.request_reload()
	p.tick_combat(2.0)
	check(p.magazines[1] == 12 and p.ammo[1] == 23, "completed reload transfers exact missing rounds")
	p.magazines[1] = 0
	p.ammo[1] = 3
	p.request_reload()
	p.tick_combat(2.0)
	check(p.magazines[1] == 3 and p.ammo[1] == 0, "partial reserve cannot create ammunition")
	p.magazines[1] = 0
	check(not p.can_fire() and not p.request_reload(), "empty weapon and reserve remain empty")
	p.add_ammo(10)
	check(p.magazines[1] == 0 and p.ammo[1] == 10, "pickup adds reserve only")
	p.request_reload()
	p.in_vehicle = true
	p.reset_combat()
	p.tick_combat(3.0)
	check(not p.can_fire() and p.magazines[1] == 0, "vehicle cancels reload and fire")
	p.in_vehicle = false
	p.locked = true
	check(not p.request_reload(), "locked player cannot reload")
	p.locked = false
	p.cycle_weapon(1)
	check(p.weapon == 3 and p.magazines[3] == 30, "cycling preserves magazines")
	var h := HealthComponent.new()
	h.armor = 20.0
	h.apply_damage(10.0, 2.0)
	check(h.current == 92.0 and h.armor == 8.0, "armor absorbs regional damage")
	h.apply_damage(1000.0)
	check(h.current == 0.0, "damage clamps at death")
	h.heal(10.0)
	check(h.current == 0.0, "healing does not resurrect")
	h.reset()
	check(h.current == 100.0, "explicit respawn resets health")
	var world := Node3D.new()
	root.add_child(world)
	box(world, Vector3(0, -0.5, 0), Vector3(20, 1, 20))
	world.add_child(p)
	await frames(10)
	check(p.set_crouched(true), "crouch reduces capsule")
	var ceiling := box(world, Vector3(0, 1.5, 0), Vector3(3, 0.2, 3))
	await frames(3)
	check(not p.set_crouched(false) and p.crouched, "ceiling prevents standing")
	ceiling.queue_free()
	await frames(3)
	check(p.set_crouched(false) and not p.crouched, "stands after ceiling removed")
	await frames(20)
	check(absf(p._visual.scale.y - 0.62) < 0.003, "standing preserves original character scale")
	p.select_weapon(0)
	p.velocity = Vector3(0, 0, -7.6)
	p.request_crouch()
	check(p.slide_remaining > 0.0 and p.crouched and p.slide_cooldown > 0.0, "running crouch starts bounded slide")
	await frames(45)
	check(p.slide_remaining == 0.0 and p.crouched, "slide ends in crouch")
	p.set_crouched(false)
	p.global_position = Vector3.ZERO
	Input.action_press("move_forward")
	Input.action_press("tactical_sprint")
	await frames(2)
	check(p.tactical_remaining > 0.0 and p.tactical_cooldown > 0.0 and p.velocity.length() > Player.SPRINT_SPEED, "tactical sprint gives temporary speed boost")
	Input.action_release("tactical_sprint")
	Input.action_release("move_forward")
	p.reset_combat()
	p.global_position = Vector3.ZERO
	await frames(3)
	var wall := box(world, Vector3(0, 1.4, -1), Vector3(1, 3, 0.2))
	var target := box(world, Vector3(0, 1.4, -5), Vector3(1, 3, 0.2))
	await frames(3)
	var result := Hitscan.cast(world.get_world_3d(), Vector3(2, 1.4, 0), Vector3(-2, 0, -5), Vector3(0, 1.4, 0), 20.0, [p.get_rid()])
	check(result.hit.get("collider") == wall, "muzzle wall blocks target visible to offset camera")
	wall.queue_free()
	await frames(3)
	result = Hitscan.cast(world.get_world_3d(), Vector3(0, 1.4, 1), Vector3.FORWARD, Vector3(0, 1.4, 0), 20.0, [p.get_rid()])
	check(result.hit.get("collider") == target, "unobstructed hitscan reaches target")
	var camera := CameraRig.new()
	world.add_child(camera)
	camera.follow = p
	camera.set_process(false)
	p.select_weapon(3)
	p.aiming = true
	camera._process(0.3)
	check(camera.ads_blend == 1.0 and camera.camera().fov < 70.0, "ADS transitions distance and FOV")
	var yaw := camera.yaw
	camera.add_look(Vector2(10, 0))
	check(absf(camera.yaw - yaw) < camera.mouse_sens * 10.0, "ADS has reduced independent sensitivity")
	camera.kick(Arsenal.data(3))
	check(camera.recoil.y > 0.0, "shot adds camera recoil")
	var recoil := camera.recoil.y
	camera._process(0.1)
	check(camera.recoil.y < recoil, "recoil recovers progressively")
	p.aiming = false
	camera.set_vehicle_mode(true)
	camera._process(0.3)
	check(camera.ads_blend == 0.0 and camera.combat_blend == 0.0, "vehicle exits combat camera")
	var pool := ShotEffects.new()
	world.add_child(pool)
	for i in 50:
		pool.emit_shot(Vector3.ZERO, Vector3(0, 0, -3))
	check(pool.get_child_count() == 12, "shot pool remains bounded after repeated firing")
	pool._process(0.1)
	check(not pool.get_child(0).visible, "shot effects expire")
	world.queue_free()
	await process_frame
	print("COMBAT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
