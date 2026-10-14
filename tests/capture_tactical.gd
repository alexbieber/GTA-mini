extends SceneTree
## Deterministic native rendering; no manual gameplay or benchmark claim.
var game: Node

func _initialize() -> void:
	call_deferred("run")

func capture(label: String) -> void:
	for i in 18: await process_frame
	await RenderingServer.frame_post_draw
	var path := OS.get_environment("TEMP").path_join("caos-tactical-%s.png" % label)
	print("TACTICAL_CAPTURE: ", label, " result=", root.get_texture().get_image().save_png(path))

func run() -> void:
	game = load("res://scenes/competitive_main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.set_process_unhandled_input(false)
	game.camera.set_first_person(true)
	await capture("menu")
	game.hud._show_settings()
	await capture("settings")
	game.start_mode(MatchRules.Mode.CORRE)
	game.matches.rules.tick(3.0)
	game.matches.set_process(false)
	for actor: Player in game.matches.actors.values(): actor.set_physics_process(false)
	game.player.global_position = Vector3(10, 0.1, 0)
	game.camera.yaw = PI * 0.5
	game.camera.pitch = -0.02
	game.player.vitality.armor = 75.0
	game.matches._update_hud()
	await capture("hip")
	game.player.aiming = true
	await capture("ads")
	game.player.aiming = false
	game.player.request_plate()
	game.player.plate_remaining = 0.6
	game.hud.show_damage(Vector2(0.5, -1).normalized())
	game.matches._update_hud()
	await capture("plate")
	game.player.cancel_plate()
	game.camera.set_first_person(false)
	await capture("third_person")
	game.matches.return_menu()
	game.queue_free()
	await create_timer(0.2).timeout
	quit()
