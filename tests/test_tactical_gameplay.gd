extends SceneTree
var checks := 0
var failures := 0

class TestPlayer extends Player:
	func _build_mesh() -> void:
		_visual = Node3D.new()
		_visual_scale = Vector3.ONE
		add_child(_visual)

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if ok: print("PASS: " + label)
	else:
		failures += 1
		push_error("FAIL: " + label)

func frames(count: int) -> void:
	for i in count:
		await physics_frame
		await process_frame

func box(parent: Node, at: Vector3, dimensions: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = dimensions
	collider.shape = shape
	body.add_child(collider)
	parent.add_child(body)
	body.position = at
	return body

func run() -> void:
	var config := TacticalConfig.new()
	var health := HealthComponent.new()
	health.armor_first = true
	health.armor = 150.0
	health.regeneration_delay = 5.0
	health.regeneration_per_second = 20.0
	health.apply_damage(60.0)
	check(health.current == 100.0 and health.armor == 90.0, "tactical armor absorbs damage before health")
	health.apply_damage(150.0)
	check(health.current == 40.0 and health.armor == 0.0, "armor break transfers only overflow to health")
	health.tick(5.0)
	check(health.current == 40.0, "health waits five seconds after damage")
	health.tick(0.25)
	check(health.current == 45.0, "health regenerates at configured rate")
	health.apply_damage(5.0)
	health.tick(4.9)
	check(health.current == 40.0, "new damage resets regeneration delay")
	health.tick(0.2)
	check(is_equal_approx(health.current, 42.0), "regeneration counts only time beyond delay")
	health.reset()
	health.armor = 100.0
	health.apply_damage(6.0, 1.0, true)
	check(health.current == 94.0 and health.armor == 100.0, "gas bypasses armor and resets health timer")
	health.apply_damage(1000.0)
	health.tick(20.0)
	check(health.current == 0.0, "passive regeneration never resurrects")
	var rifle := Arsenal.data(Arsenal.Id.RIFLE)
	check(rifle.damage_at(5.0) == rifle.damage, "close shots retain base damage")
	check(rifle.damage_at(rifle.effective_range) < rifle.damage and rifle.damage_at(rifle.effective_range + 1.0) == 0.0, "distance falloff and range limit are enforced")
	var world := Node3D.new()
	root.add_child(world)
	box(world, Vector3(0, -0.5, 0), Vector3(30, 1, 30))
	var player := TestPlayer.new()
	world.add_child(player)
	player.configure_tactical(config)
	player.give_weapon(Arsenal.Id.RIFLE, 90)
	await frames(5)
	player.set_physics_process(false)
	check(player.request_plate(), "plate application starts with spare inventory")
	check(player.armor_plates == 3 and not player.can_fire(), "plate insertion blocks shooting without spending inventory early")
	player.tick_combat(config.plate_seconds - 0.1)
	check(player.vitality.armor == 0.0 and player.armor_plates == 3, "incomplete plate grants no protection")
	player.tick_combat(0.11)
	check(player.vitality.armor == 50.0 and player.armor_plates == 2, "completed plate grants exactly fifty armor and spends one")
	player.request_plate()
	player.take_damage(10.0)
	check(player.plate_remaining == 0.0 and player.armor_plates == 2, "damage cancels insertion without consuming pending plate")
	player.request_plate()
	player.select_weapon(Arsenal.Id.NONE)
	check(player.plate_remaining == 0.0, "weapon switch cancels insertion")
	player.select_weapon(Arsenal.Id.RIFLE)
	player.magazines[3] = 29
	player.request_reload()
	check(not player.request_plate(), "reload and armor application cannot overlap")
	player.reset_combat()
	player.vitality.armor = 150.0
	check(not player.request_plate(), "full armor rejects wasted plate")
	player.vitality.armor = 145.0
	player.request_plate()
	player.tick_combat(2.0)
	check(player.vitality.armor == 150.0, "partial top up clamps to armor cap")
	check(player.add_plates(100) == 7 and player.armor_plates == 8, "spare inventory has a hard cap")
	player.armor_plates = 0
	player.vitality.armor = 0.0
	check(not player.request_plate(), "no spare plates cannot create armor")
	player.armor_plates = 3
	player.locked = true
	check(not player.request_plate(), "locked actor cannot apply armor")
	player.locked = false
	player.sprinting = true
	var ammo_before: int = player.magazines[3]
	check(player.spend_shot().is_empty() and player.sprint_to_fire_remaining > 0.0, "firing interrupts sprint with a short readiness delay")
	check(player.magazines[3] == ammo_before and not player.sprinting, "sprint interruption spends no ammunition")
	player.tick_combat(0.13)
	check(not player.spend_shot().is_empty(), "weapon can fire after sprint readiness delay")
	player.tick_combat(0.3)
	var camera := CameraRig.new()
	world.add_child(camera)
	camera.add_to_group("camera_rig")
	camera.follow = player
	camera.set_process(false)
	camera.set_first_person(true)
	camera.yaw = 0.0
	camera.pitch = 0.0
	camera._process(0.3)
	check(camera.camera().global_position.distance_to(player.global_position + Vector3.UP * 1.5) < 0.001, "first person camera anchors to capsule eye")
	check(not player._visual.visible and not player._gun.visible and camera._view_model.visible, "first person hides only own meshes and shows view weapon")
	player.aiming = true
	camera._process(0.3)
	check(camera.ads_blend == 1.0 and camera.camera().fov < 70.0, "first person ADS narrows FOV")
	var heading := camera.yaw
	camera.add_look(Vector2(10, 0))
	check(absf(camera.yaw - heading) < camera.mouse_sens * 10.0, "first person retains reduced ADS sensitivity")
	player.aiming = false
	player.set_crouched(true)
	camera._process(0.3)
	check(is_equal_approx(camera.camera().global_position.y - player.global_position.y, 0.94), "first person eye follows crouch capsule")
	camera.set_first_person(false)
	camera._process(0.3)
	check(player._visual.visible and not camera._view_model.visible, "third person restores visible original character")
	camera.set_first_person(true)
	player.set_crouched(false)
	player.global_position = Vector3.ZERO
	player.velocity = Vector3.ZERO
	player.set_physics_process(true)
	camera.yaw = 0.0
	await frames(4)
	player.set_physics_process(false)
	var obstacle := box(world, Vector3(0, 0.45, -1.1), Vector3(2, 0.9, 0.5))
	await frames(3)
	Input.action_press("move_forward")
	check(player.try_mantle(), "moving jump can vault low cover with capsule clearance")
	check(not player.can_fire(), "mantle blocks firing during traversal")
	player._tick_mantle(0.42)
	check(player.global_position.z < -1.4 and player.vault_remaining == 0.0, "mantle traverses cover and lands beyond it")
	player.global_position = Vector3.ZERO
	player.set_physics_process(true)
	Input.action_release("move_forward")
	await frames(4)
	player.set_physics_process(false)
	var ceiling := box(world, Vector3(0, 2.0, -0.7), Vector3(3, 0.2, 3))
	await frames(3)
	Input.action_press("move_forward")
	check(not player.try_mantle(), "overhead ceiling rejects vault before any movement")
	ceiling.queue_free()
	await frames(3)
	obstacle.queue_free()
	var wall := box(world, Vector3(0, 1.5, -1.1), Vector3(2, 3, 0.5))
	await frames(3)
	check(not player.try_mantle(), "high wall cannot be vaulted")
	wall.queue_free()
	Input.action_release("move_forward")
	await frames(3)
	player.set_physics_process(true)
	await frames(4)
	player.set_physics_process(false)
	player.velocity = Vector3(0, 0, -7.6)
	player.request_crouch()
	check(player.slide_remaining > 0.0, "sprinting crouch starts slide in tactical profile")
	player.request_jump()
	check(player.slide_remaining == 0.0 and not player.crouched, "jump cancels slide when standing capsule has clearance")
	world.queue_free()
	await process_frame
	await test_real_match()
	print("TACTICAL_GAMEPLAY: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func test_real_match() -> void:
	var game = load("res://scenes/competitive_main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.camera.set_first_person(true)
	game.start_mode(MatchRules.Mode.CORRE)
	game.matches.rules.tick(3.0)
	game.set_process(false)
	game.matches.set_process(false)
	for actor: Player in game.matches.actors.values(): actor.set_physics_process(false)
	game.player.global_position = Vector3(10, 0.1, 0)
	var fps_enemy: Player = game.matches.actors[5]
	fps_enemy.global_position = Vector3(-10, 0.1, 0)
	game.camera.yaw = PI * 0.5
	game.camera.pitch = -0.02
	fps_enemy.vitality.armor = 150.0
	await frames(3)
	game.camera._process(0.3)
	game._try_fire()
	check(fps_enemy.vitality.armor < 150.0 and game.hud.reticle.hit_remaining > 0.0, "actual first person camera ray hits real enemy through shared muzzle validation")
	game.player.tick_combat(1.0)
	game.player.select_weapon(Arsenal.Id.PISTOL)
	game.player.sprinting = true
	var pistol_before: int = game.player.magazines[1]
	game._try_fire()
	game.player.tick_combat(0.13)
	game._process(0.016)
	check(game.player.magazines[1] == pistol_before - 1 and game._pending_shot == 0.0, "queued semi automatic trigger fires once after sprint delay")
	game.start_mode(MatchRules.Mode.BATTLE)
	var manager: MatchManager = game.matches
	manager.rules.tick(3.0)
	game.set_process(false)
	manager.set_process(false)
	for actor: Player in manager.actors.values(): actor.set_physics_process(false)
	check(game.player.tactical != null and game.player.vitality.armor == 100.0 and game.player.armor_plates == 3, "Royale starts with armor and spare plates")
	var supplies: Dictionary = manager._loot[2]
	game.player.global_position = supplies.position
	var armor_before: float = game.player.vitality.armor
	check(manager._collect_loot(0, true, 1.4) and game.player.armor_plates == 5, "proximity loot adds spare plates")
	check(game.player.vitality.armor == armor_before and not manager._collect_loot(0, true, 1.4), "plate loot neither auto equips armor nor duplicates")
	var weapon: Dictionary = manager._loot[0]
	game.player.global_position = weapon.position
	check(not manager._collect_loot(0, true, 1.4), "weapon pickup requires explicit interaction")
	check(manager.interact_player() and game.player.weapon == Arsenal.Id.RIFLE, "explicit loot equips weapon with loaded magazine")
	var ammo: Dictionary = manager._loot[1]
	game.player.global_position = ammo.position + Vector3(0, 0, 1)
	var barrier := box(manager.arena, ammo.position + Vector3(0, 0.7, 0.5), Vector3(2, 1.4, 0.15))
	await frames(3)
	check(not manager._collect_loot(0, true, 1.4) and ammo.available, "auto pickup cannot collect supplies through wall")
	barrier.queue_free()
	await frames(3)
	check(manager._collect_loot(0, true, 1.4), "unobstructed nearby ammunition is collected")
	var enemy: Player = manager.actors[1]
	enemy.global_position = game.player.global_position + Vector3(0, 0, -2)
	enemy.vitality.armor = 10.0
	check(manager.apply_hit(0, enemy, 20.0) and game.hud.reticle.hit_color == Color("bc8cff"), "real armor break changes hit confirmation color")
	game.player.vitality.armor = 100.0
	var before_health: float = game.player.health
	manager.apply_hit(1, game.player, 10.0)
	check(game.player.health == before_health and game.hud.overlay.indicators.size() == 1, "incoming armored damage shows directional feedback")
	game.player.global_position = Vector3(106, 0.1, 106)
	manager._zone_damage(6.0)
	check(game.player.health < before_health and game.player.vitality.armor == 90.0, "real safe zone damages health instead of armor")
	game.player.sprinting = true
	game._try_fire()
	check(game._pending_shot > 0.0, "trigger queues shot while exiting sprint")
	manager.return_menu()
	await process_frame
	check(game._pending_shot == 0.0 and game.hud.overlay.indicators.is_empty() and not game.camera._view_model.visible, "return menu clears pending shot weapon view and damage feedback")
	game.queue_free()
	await create_timer(0.15).timeout
