extends SceneTree
## Rendered smoke of menu, modes and results. No manual-gameplay/FPS claim.
var game: Node

func _initialize() -> void:
	call_deferred("run")

func capture(label: String) -> void:
	for i in 15:
		await process_frame
	var start := Time.get_ticks_usec()
	var last := start
	var samples: Array[float] = []
	for i in 90:
		await process_frame
		var now := Time.get_ticks_usec()
		samples.append(float(now - last) / 1000.0)
		last = now
	var average_fps := 90.0 / (float(last - start) / 1000000.0)
	samples.sort()
	await RenderingServer.frame_post_draw
	var path := OS.get_environment("TEMP").path_join("caos-%s.png" % label)
	var result := root.get_texture().get_image().save_png(path)
	print("CAPTURE: ", label, " result=", result, " draw_calls=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		" static_memory_bytes=", Performance.get_monitor(Performance.MEMORY_STATIC), " sample_fps=", average_fps, " p95_frame_ms=", samples[85])

func run() -> void:
	var loading := Time.get_ticks_msec()
	game = load("res://scenes/competitive_main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	print("RENDERED_STARTUP_MS: ", Time.get_ticks_msec() - loading)
	await capture("menu")
	game.hud._show_settings()
	await capture("settings")
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
	await create_timer(0.15).timeout
	quit()
