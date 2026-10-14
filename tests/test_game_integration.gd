extends SceneTree
## Exercises the shipped scene and existing systems, without synthetic replacements.
var failures := 0
var checks := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("PASS: " + message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	var game = packed.instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	check(game.city != null and game.roads.nodes.size() > 0, "main scene creates city and roads")
	check(game.phase == game.Phase.TITLE and game.player.locked, "title keeps player locked")
	check(game.clock.quality == GraphicsProfile.Quality.LOW, "game starts in LOW")
	game.begin()
	check(game.phase == game.Phase.STEAL and not game.player.locked, "existing mission begins")
	for _i in 90:
		await physics_frame
		await process_frame
		if game.player.is_on_floor():
			break
	check(game.player.is_on_floor(), "real game spawn settles before jump")
	var start_y: float = game.player.global_position.y
	var jump := InputEventKey.new()
	jump.keycode = KEY_SPACE
	jump.pressed = true
	game._unhandled_input(jump)
	var peak_y := start_y
	# Physics frames may be batched during the expensive procedural startup.
	# Observe the peak rather than one arbitrary render frame after landing.
	for _i in 45:
		await physics_frame
		peak_y = maxf(peak_y, game.player.global_position.y)
	check(peak_y > start_y + 0.2, "Space input jumps in real game")
	game._enter_vehicle(game.coupe)
	check(game.player.in_vehicle and game.camera.vehicle_mode, "existing car entry works")
	check(game.phase == game.Phase.HEAT and game.heat.stars > 0, "car theft starts police response")
	game.coupe.speed = 0.0
	game._exit_vehicle()
	check(not game.player.in_vehicle and not game.camera.vehicle_mode, "existing car exit works")
	game.clock.set_quality(GraphicsProfile.Quality.MEDIUM)
	game.clock.toggle()
	check(game.clock._env.ssao_enabled and not game.clock._env.sdfgi_enabled, "day/night preserves MEDIUM profile")
	game.player.give_weapon(Arsenal.Id.PISTOL, 3)
	var ammo_before: int = game.player.ammo[Arsenal.Id.PISTOL]
	game.player.locked = false
	var shot: Dictionary = game.player.spend_shot()
	check(not shot.is_empty() and game.player.ammo[Arsenal.Id.PISTOL] == ammo_before - 1, "existing weapon spends ammunition")
	var graphics := InputEventKey.new()
	graphics.keycode = KEY_F6
	graphics.pressed = true
	game._unhandled_input(graphics)
	check(game.clock.quality == GraphicsProfile.Quality.HIGH, "F6 changes graphics profile")
	# Let short driver/UI timers finish before destroying the scene.
	await create_timer(2.5).timeout
	game.queue_free()
	await process_frame
	print("GAME_INTEGRATION: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
