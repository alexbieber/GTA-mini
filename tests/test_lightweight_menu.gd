extends SceneTree
var failures := 0
var checks := 0

func _initialize() -> void: call_deferred("run")
func check(ok: bool, text: String) -> void:
	checks += 1
	if ok: print("PASS: " + text)
	else:
		failures += 1
		push_error("FAIL: " + text)

func run() -> void:
	var start := Time.get_ticks_msec()
	var game = load("res://scenes/competitive_main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	print("MENU_STARTUP_MS: ", Time.get_ticks_msec() - start, " MEMORY_STATIC_BYTES: ", Performance.get_monitor(Performance.MEMORY_STATIC))
	check(game.player == null and game.matches.arena == null, "menu loads no character or map")
	check(get_nodes_in_group("peds").is_empty() and get_nodes_in_group("vehicles").is_empty(), "menu loads no civilians traffic or vehicles")
	check(not ResourceLoader.has_cached("res://assets/pbr/hdri/wide_street_01_2k.hdr"), "menu loads no archived HDRI")
	check(not ResourceLoader.has_cached("res://assets/people/real/man.fbx"), "menu defers character model until selection")
	check(game.clock.quality == GraphicsProfile.Quality.LOW, "new menu starts LOW")
	game.start_mode(MatchRules.Mode.FREE)
	check(game.player == null and game.matches.arena == null, "archived open world is not an available mode")
	game.hud.selected_team = 0
	game.start_mode(MatchRules.Mode.CORRE)
	check(game.matches.competitive() and game.matches.rules.participants[0].team == 0, "police team selection reaches actual roster")
	game.matches.return_menu()
	await process_frame
	check(game.player == null and game.matches.arena == null and get_nodes_in_group("match_bots").is_empty(), "return menu releases map player and bots")
	game.hud._show_settings()
	check(game.hud._settings_content.visible, "settings panel builds graphics audio and controls")
	game.queue_free()
	await process_frame
	print("LIGHTWEIGHT_MENU: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
