extends SceneTree
## 30-second rendered sample with autonomous bots; not manual gameplay.
var game: Node
var eliminations := 0

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var mode := "corre"
	if "battle" in OS.get_cmdline_user_args(): mode = "battle"
	var start_loading := Time.get_ticks_msec()
	game = load("res://scenes/competitive_main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var menu_ms := Time.get_ticks_msec() - start_loading
	var match_loading := Time.get_ticks_msec()
	game.start_mode(MatchRules.Mode.CORRE if mode == "corre" else MatchRules.Mode.BATTLE)
	var match_ms := Time.get_ticks_msec() - match_loading
	game.matches.rules.tick(3.0)
	# Automated sample: leave OS window-close available, disable gameplay shortcuts.
	game.set_process_unhandled_input(false)
	game.matches.bus.occurred.connect(func(name: String, _payload: Dictionary) -> void:
		if name == "ELIMINATION": eliminations += 1)
	for i in 30: await process_frame
	print("BENCH_PID: ", OS.get_process_id(), " MODE: ", mode)
	var start := Time.get_ticks_usec()
	var last := start
	var samples: Array[float] = []
	while Time.get_ticks_usec() - start < 30000000:
		await process_frame
		var now := Time.get_ticks_usec()
		samples.append(float(now - last) / 1000.0)
		last = now
	var average_fps := samples.size() / (float(last - start) / 1000000.0)
	samples.sort()
	var report := {"mode": mode, "pid": OS.get_process_id(), "menu_load_ms": menu_ms,
		"match_load_ms": match_ms, "sample_seconds": float(last - start) / 1000000.0,
		"average_fps": average_fps, "p95_frame_ms": samples[int(samples.size() * 0.95)],
		"draw_calls_last_frame": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"engine_static_memory_bytes": Performance.get_monitor(Performance.MEMORY_STATIC),
		"engine_peak_static_memory_bytes": Performance.get_monitor(Performance.MEMORY_STATIC_MAX),
		"eliminations": eliminations, "alive": game.matches.rules.alive_ids().size(),
		"score": game.matches.rules.score.duplicate()}
	var file := FileAccess.open(OS.get_environment("TEMP").path_join("caos-benchmark-%s.json" % mode), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("BENCHMARK: ", JSON.stringify(report))
	game.matches.return_menu()
	game.queue_free()
	await create_timer(0.15).timeout
	quit()
