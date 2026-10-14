extends SceneTree
## Rendered smoke of menu, modes and results. No manual-gameplay/FPS claim.
var game: Node

func _initialize() -> void:
	call_deferred("run")

func capture(label: String) -> void:
	for i in 45:
		await process_frame
	await RenderingServer.frame_post_draw
	var path := OS.get_environment("TEMP").path_join("caos-%s.png" % label)
	var result := root.get_texture().get_image().save_png(path)
	print("CAPTURE: ", label, " result=", result, " draw_calls=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		" static_memory_bytes=", Performance.get_monitor(Performance.MEMORY_STATIC))

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await capture("menu")
	game.start_mode(MatchRules.Mode.CORRE)
	game.matches.rules.tick(3.0)
	Input.action_press("aim")
	await capture("corre")
	Input.action_release("aim")
	game.start_mode(MatchRules.Mode.BATTLE)
	game.matches.rules.tick(3.0)
	await capture("battle")
	game.matches.rules.finish(0)
	await capture("results")
	game.matches.return_menu()
	game.queue_free()
	await process_frame
	quit()
