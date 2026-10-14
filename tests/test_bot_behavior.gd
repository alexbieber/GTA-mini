extends SceneTree
var checks := 0
var failures := 0

func _initialize() -> void: call_deferred("run")
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

func run() -> void:
	var game = load("res://scenes/competitive_main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.start_mode(MatchRules.Mode.CORRE)
	var manager: MatchManager = game.matches
	manager.announcer.set_enabled(false)
	manager.rules.tick(3.0)
	var bot: MatchBot = manager.actors[5]
	for id in manager.actors:
		if id == 0 or id == 5: continue
		manager.actors[id].set_physics_process(false)
		manager.actors[id].collision_layer = 0
		manager.actors[id].global_position = Vector3(70, 0.1, 45)
	bot.set_physics_process(false)
	bot.global_position = Vector3(-10, 0.12, 0)
	game.player.global_position = Vector3(10, 0.12, 0)
	bot.rotation.y = -PI * 0.5
	await frames(3)
	check(bot.can_perceive(game.player, game.player.global_position + Vector3.UP * 1.2), "FOV and actual physics ray detect forward enemy")
	bot.rotation.y = PI * 0.5
	check(not bot.can_perceive(game.player, game.player.global_position + Vector3.UP * 1.2), "enemy behind bot remains outside field of view")
	bot.rotation.y = -PI * 0.5
	bot.global_position = Vector3(-60, 0.12, 0)
	game.player.global_position = Vector3(-40, 0.12, 0)
	await frames(2)
	check(not bot.can_perceive(game.player, game.player.global_position + Vector3.UP * 1.2), "spawn screen occludes perception even inside field of view")
	bot.global_position = Vector3(-10, 0.12, 0)
	game.player.global_position = Vector3(70, 0.12, 0)
	await frames(2)
	check(bot.hear_sound(Vector3(-16, 0.12, 0), 0), "near enemy shot behind bot can be heard")
	check(not bot.hear_sound(Vector3(-16, 0.12, 0), 6), "friendly shot does not initiate enemy investigation")
	check(not bot.hear_sound(Vector3(90, 0.12, 0), 0), "out of range shot is ignored")
	bot.memory_until = -1.0
	check(bot.brain.plan(bot) and bot.brain.state == BotBrain.State.INVESTIGATE and bot.bot_state == "INVESTIGATE", "heard shot produces investigative FSM movement without visual target")
	check(bot.brain.threat_id == -1, "hearing does not invent a visible enemy ID")
	bot.brain.heard_until = -1.0
	bot.magazines[bot.weapon] = 0
	bot.ammo[bot.weapon] = 60
	check(bot.brain.plan(bot) and bot.reload_remaining > 0 and bot.brain.state == BotBrain.State.RELOAD, "empty magazine enters reload state and transfers through player weapon system")
	bot.tick_combat(10.0)
	check(int(bot.magazines.get(bot.weapon, 0)) > 0 and int(bot.ammo.get(bot.weapon, 0)) < 60, "reload completion uses actual reserve ammunition")
	bot.observe_enemy(0, Vector3(10, 0.1, 0))
	bot.health = 15.0
	check(bot.brain.plan(bot) and bot.brain.state == BotBrain.State.RETREAT and bot.target_position != Vector3(10, 0.1, 0), "low health triggers a navigable retreat instead of a frontal charge")
	bot.health = 100.0
	bot.memory_until = -1.0
	bot.set_difficulty("easy")
	var easy_accuracy := bot.difficulty.accuracy
	var easy_reaction := bot.difficulty.reaction_seconds
	bot.set_difficulty("hard")
	check(bot.difficulty.accuracy > easy_accuracy and bot.difficulty.reaction_seconds < easy_reaction, "difficulty presets change accuracy and reaction through resources")
	bot.set_difficulty("normal")
	bot.global_position = Vector3(-60, 0.12, -32)
	bot.bot_state = "STEAL"
	bot.move_to(Vector3(60, 0.12, -32))
	bot.decision_remaining = 100.0
	bot.set_physics_process(true)
	var start := bot.global_position
	await frames(100)
	check(manager.arena.has_meta("bot_navigation_region") and (manager.arena.get_meta("bot_navigation_region") as NavigationRegion3D).navigation_mesh.get_polygon_count() > 100, "arena registers real shared NavigationRegion3D surface")
	check(bot.navigation_steps > 50 and bot.navigation_agent.get_current_navigation_path().size() >= 2, "NavigationAgent3D queries server path and actually drives locomotion")
	check(bot.global_position.distance_to(start) > 3.0 and bot.global_position.y > -0.1, "navigation path produces real collision movement on arena ground")
	game.queue_free()
	await frames(3)
	print("BOT BEHAVIOR: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
