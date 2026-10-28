extends SceneTree
class Harness extends Node:
	var arena: MatchArena
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
	var arena := MatchArena.new()
	arena.definition = load("res://resources/maps/favela_royale.tres") as ArenaDefinition
	root.add_child(arena)
	GridNavigation.ensure_region(arena)
	await frames(4)
	var map := arena.get_world_3d().navigation_map
	var spawns: Array[Vector3] = []
	for id in 8:
		var angle := TAU * id / 8.0
		spawns.append(arena.nearest_clear(Vector3(cos(angle), 0, sin(angle)) * 90.0))
	var connected := true
	var query := NavigationPathQueryParameters3D.new()
	query.map = map
	query.path_search_max_polygons = 20000
	var result := NavigationPathQueryResult3D.new()
	for a in 8:
		for b in range(a + 1, 8):
			query.start_position = spawns[a]
			query.target_position = spawns[b]
			NavigationServer3D.query_path(query, result)
			var path := result.path
			if path.size() < 2 or path[path.size() - 1].distance_to(spawns[b]) > 3.0:
				connected = false
				print("NAV GAP: ", a, " -> ", b, " from=", spawns[a], " to=", spawns[b], " last=", path[path.size() - 1] if path.size() > 0 else Vector3.ZERO)
	check(connected, "real server navigation connects all eight BR spawns through clearance-safe cells")
	var ramp := NavigationServer3D.map_get_path(map, Vector3(22, 0.1, 62), Vector3(40, 1.7, 62), true)
	check(ramp.size() >= 2 and ramp[ramp.size() - 1].distance_to(Vector3(40, 1.7, 62)) < 1.0, "server navigation traverses the continuous elevated ramp")
	var harness := Harness.new()
	harness.arena = arena
	root.add_child(harness)
	var bot := MatchBot.new()
	bot.manager = harness
	bot.participant_id = 1
	arena.add_child(bot)
	bot.global_position = Vector3(22, 0.12, 62)
	bot.decision_remaining = 100.0
	bot.bot_state = "ZONE"
	bot.move_to(Vector3(40, 1.72, 62))
	await frames(360)
	check(bot.global_position.y > 1.4 and bot.global_position.x > 37.0 and bot.navigation_steps > 100, "actual bot follows NavigationAgent path and climbs the physical favela ramp")
	arena.queue_free()
	harness.queue_free()
	await frames(3)
	print("BOT NAVIGATION: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
