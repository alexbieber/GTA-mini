extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var archived := "archive" in OS.get_cmdline_user_args()
	var start := Time.get_ticks_msec()
	var game = load("res://scenes/main.tscn" if archived else "res://scenes/competitive_main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	print("STARTUP: archived=", archived, " load_ms=", Time.get_ticks_msec() - start,
		" engine_static_memory_bytes=", Performance.get_monitor(Performance.MEMORY_STATIC), " nodes=", get_node_count())
	game.queue_free()
	await create_timer(0.15).timeout
	quit()
