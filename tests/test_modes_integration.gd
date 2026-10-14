extends SceneTree
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if ok: print("PASS: " + label)
	else:
		failures += 1
		push_error("FAIL: " + label)

func frames(n: int) -> void:
	for i in n:
		await physics_frame
		await process_frame

func run() -> void:
	var game = load("res://scenes/competitive_main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	check(game.matches != null and game.clock.quality == GraphicsProfile.Quality.LOW, "shared modes start with LOW and menu")
	game.start_mode(MatchRules.Mode.CORRE)
	var manager: MatchManager = game.matches
	check(manager.actors.size() == 10 and get_nodes_in_group("match_bots").size() == 9, "Protege o Corre spawns player plus nine bots")
	check(manager.arena.definition.dimensions == Vector2(160, 110), "Corre map uses compact 160x110 dimensions")
	var spawn_screens := true
	for own in range(0, 5):
		for opposing in range(5, 10):
			var query := PhysicsRayQueryParameters3D.create(manager.actors[own].global_position + Vector3.UP * 1.3, manager.actors[opposing].global_position + Vector3.UP * 1.3, 1)
			if game.get_world_3d().direct_space_state.intersect_ray(query).is_empty(): spawn_screens = false
	check(spawn_screens, "geometry blocks all direct opposing spawn sightlines")
	check(manager.rules.participants[0].team == 1 and manager.rules.participants[5].team == 0, "teams divide into five per side")
	check(manager.rules.objectives.size() == 6 and manager.arena != null, "two bases each own three objective objects")
	check(game.player.locked and manager.rules.state == MatchRules.State.COUNTDOWN, "countdown locks combat movement")
	var path := manager.arena.route(MatchArena.ORIGIN + Vector3(-60, 0, -28), MatchArena.ORIGIN + Vector3(60, 0, -28))
	check(path.size() > 2, "A* finds route around urban buildings")
	var navigable := true
	for point in path:
		if manager.arena.navigation.is_point_solid(manager.arena.cell(point)): navigable = false
	check(navigable, "route avoids blocked collision cells")
	manager.rules.tick(3.0)
	var start: Vector3 = manager.actors[1].global_position
	await frames(40)
	check(manager.actors[1].global_position.distance_to(start) > 1.0 and manager.actors[1].bot_state != "WAIT", "bots make real decisions and move with physics")
	var enemy: MatchBot = manager.actors[5]
	enemy.set_physics_process(false)
	manager.rules.config.bot_accuracy = 1.0
	enemy.global_position = MatchArena.ORIGIN + Vector3(-10, 0.2, 0)
	game.player.global_position = MatchArena.ORIGIN + Vector3(10, 0.2, 0)
	await frames(3)
	var before_health: float = game.player.health
	manager.decide_bot(enemy)
	check(game.player.health < before_health and enemy.bot_state == "ATTACK", "bot perceives and physically shoots player through clear LOS")
	var camera: Camera3D = game.camera.camera()
	game.camera.set_process(false)
	camera.global_position = game.player.global_position + Vector3(0, 1.4, 4)
	camera.look_at(enemy.global_position + Vector3.UP * 1.2)
	var enemy_health := enemy.health
	game._try_fire()
	check(enemy.health < enemy_health and game.hud.reticle.hit_remaining > 0.0, "player fire ray damages real enemy and confirms hit")
	game.camera.set_process(true)
	enemy.global_position = MatchArena.ORIGIN + Vector3(-42, 0.2, -20)
	game.player.global_position = MatchArena.ORIGIN + Vector3(-14, 0.2, -20)
	enemy.attack_remaining = 0.0
	await frames(3)
	before_health = game.player.health
	manager.decide_bot(enemy)
	check(game.player.health == before_health and enemy.bot_state != "ATTACK", "urban building prevents bot perception and shots through walls")
	enemy.set_physics_process(true)
	manager.rules.config.bot_accuracy = 0.7
	var item: ObjectiveState = manager.rules.objectives["0:0"]
	game.player.global_position = item.position
	manager.rules.participants[0].position = item.position
	check(manager.interact_player() and manager.rules.carried_by(0) == item, "real player interaction collects enemy objective")
	game.player.global_position = manager.arena.bases[1]
	manager.rules.participants[0].position = game.player.global_position
	manager._process(0.01)
	check(manager.rules.score[1] == 1 and manager.rules.carried_by(0) == null, "real deposit scores carried enemy objective")
	check(not manager.apply_hit(1, game.player, 50.0), "friendly bot cannot damage real player")
	check(manager.apply_hit(5, game.player, 1000.0), "enemy can damage real player")
	manager._process(0.01)
	check(not manager.rules.participants[0].alive and game.player.locked, "real elimination removes player from active combat")
	manager.rules.tick(5.0)
	check(game.player.health == 100.0 and not game.player.locked and manager.rules.participants[0].alive, "real respawn restores health collision and control")
	check(get_nodes_in_group("vehicles").is_empty(), "competitive map loads no archived vehicles")
	manager.restart()
	await process_frame
	check(get_nodes_in_group("match_bots").size() == 9 and manager.rules.score == [0, 0], "restart clears actors objectives score and event residues")
	manager.rules.tick(3.0)
	for actor: Player in manager.actors.values(): actor.set_physics_process(false)
	for capture_index in 5:
		var objective: ObjectiveState = manager.rules.objectives["0:0"]
		game.player.global_position = objective.position
		manager.rules.participants[0].position = objective.position
		manager.interact_player()
		game.player.global_position = manager.arena.bases[1]
		manager._process(0.01)
		if capture_index < 4: manager.rules.tick(2.0)
	check(manager.rules.score[1] == 5 and manager.rules.winner == 1 and game.hud._results.visible, "five physical-object captures complete 5v5 match with results")
	manager.return_menu()
	await process_frame
	check(get_nodes_in_group("match_bots").is_empty() and manager.arena == null, "return menu removes competitive actors")
	check(game.player == null, "menu releases player model with map")
	game.start_mode(MatchRules.Mode.BATTLE)
	check(manager.arena.definition.dimensions == Vector2(220, 220) and manager.arena.definition.favela, "Favela Royale selects its own 220x220 map")
	check(manager.actors.size() == 10 and get_nodes_in_group("match_bots").size() == 9, "battle spawns ten participants")
	check(manager.zone != null and manager._loot.size() == 24 and game.player.weapon == Arsenal.Id.NONE, "battle creates zone loot and unarmed start")
	var loot_walkable := true
	for supply in manager._loot:
		if manager.arena.navigation.is_point_solid(manager.arena.cell(supply.position)) or supply.position.y < manager.arena.height_at(supply.position): loot_walkable = false
	check(loot_walkable, "all loot lies on navigable cells at actual terrain height")
	manager.rules.tick(3.0)
	var loot: Dictionary = manager._loot[0]
	game.player.global_position = loot.position
	check(manager.interact_player() and game.player.weapon == Arsenal.Id.RIFLE and not loot.available, "loot equips real weapon once")
	var collected := manager.interact_player()
	check(not collected, "collected loot cannot duplicate")
	game.player.global_position = MatchArena.ORIGIN + Vector3(106, 0.1, 106)
	var health: float = game.player.health
	manager._zone_damage(6.0)
	check(game.player.health < health, "zone damages real outside participant")
	for id in range(1, 10):
		manager.apply_hit(0, manager.actors[id], 1000.0)
	manager._process(0.01)
	check(manager.rules.state == MatchRules.State.FINISHED and manager.rules.winner == 0 and game.hud._results.visible, "battle last survivor triggers real victory screen")
	manager.restart()
	await process_frame
	check(manager.rules.alive_ids().size() == 10 and get_nodes_in_group("match_bots").size() == 9, "battle restart has fresh participants without ghosts")
	manager.return_menu()
	await process_frame
	game.queue_free()
	await process_frame
	print("MODES_INTEGRATION: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
