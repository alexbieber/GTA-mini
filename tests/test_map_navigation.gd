extends SceneTree
var checks := 0
var failures := 0
class TestPlayer extends Player:
	func _build_mesh() -> void: pass

func _initialize() -> void: call_deferred("run")
func check(ok: bool, text: String) -> void:
	checks += 1
	if ok: print("PASS: " + text)
	else:
		failures += 1
		push_error("FAIL: " + text)

func run() -> void:
	var arena := MatchArena.new()
	arena.definition = load("res://resources/maps/favela_royale.tres") as ArenaDefinition
	root.add_child(arena)
	await process_frame
	var spawns: Array[Vector3] = []
	for id in 10:
		var angle := TAU * id / 10.0
		spawns.append(arena.nearest_clear(Vector3(cos(angle), 0, sin(angle)) * 90.0))
	var separated := true
	var connected := true
	for a in 10:
		for b in range(a + 1, 10):
			if spawns[a].distance_to(spawns[b]) < 12.0: separated = false
			if arena.route(spawns[a], spawns[b]).size() < 2: connected = false
	check(separated, "ten Favela spawns are separated by at least twelve meters")
	check(connected, "every Favela spawn connects through walkable A* paths")
	var ramp := arena.route(Vector3(22, 0, 62), Vector3(40, 1.6, 62))
	var raised := false
	for point in ramp:
		if point.y > 1.5: raised = true
	check(ramp.size() > 2 and raised, "elevated neighborhood connects through ramp with correct floor heights")
	var zones_valid := true
	var zones_contained := true
	for seed_value in 30:
		var zone := SafeZoneController.new()
		zone.reset(Vector3.ZERO, arena.valid_zone_center)
		zone.rng.seed = seed_value
		zone.choose_next()
		for phase_index in 5:
			if not arena.valid_zone_center(zone.next_center): zones_valid = false
			if zone.center.distance_to(zone.next_center) + zone.next_radius > zone.radius + 0.001: zones_contained = false
			zone.tick(zone.config.waits[phase_index] + zone.config.closures[phase_index])
		if not zone.finished or arena.navigation.is_point_solid(arena.cell(zone.center)): zones_valid = false
	check(zones_contained, "150 safe-zone transitions preserve circle containment")
	check(zones_valid, "all sampled final zones end in accessible Favela terrain")
	var player := TestPlayer.new()
	arena.add_child(player)
	player.global_position = Vector3(-68.65, 0.12, -68)
	for i in 12:
		await physics_frame
		await process_frame
	Input.action_press("move_forward")
	var peak := player.global_position.y
	for i in 130:
		await physics_frame
		await process_frame
		peak = maxf(peak, player.global_position.y)
	Input.action_release("move_forward")
	check(peak > 3.2, "real character physics climbs modular staircase to roof height")
	check(arena._materials.size() < 24, "map shares a bounded palette rather than per-house materials")
	arena.queue_free()
	await process_frame
	print("MAP_NAVIGATION: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
