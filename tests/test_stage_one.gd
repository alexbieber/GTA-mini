extends SceneTree
## Run: godot --headless --path . --script tests/test_stage_one.gd
var failures := 0
var checks := 0

class TestPlayer extends Player:
	func _build_mesh() -> void:
		pass

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + message)
	else:
		print("PASS: " + message)

func frames(count: int) -> void:
	for _i in count:
		await physics_frame
		await process_frame

func run() -> void:
	var move := Locomotion.new()
	move.request_jump()
	check(move.tick(1.0 / 60.0, true), "grounded jump")
	move.request_jump()
	check(not move.tick(1.0 / 60.0, false), "no double jump")
	move.reset()
	move.tick(0.016, true)
	move.request_jump()
	check(move.tick(0.04, false), "coyote jump after leaving ledge")
	move.reset()
	move.request_jump()
	check(not move.tick(0.04, false), "buffer waits for floor")
	check(move.tick(0.016, true), "buffer triggers on landing")
	move.reset()
	move.request_jump()
	move.tick(0.2, false)
	check(not move.tick(0.016, true), "expired buffer does not jump")

	var world := Node3D.new()
	root.add_child(world)
	var floor_body := StaticBody3D.new()
	var floor_col := CollisionShape3D.new()
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(20, 1, 20)
	floor_col.shape = floor_shape
	floor_body.add_child(floor_col)
	floor_body.position.y = -0.5
	world.add_child(floor_body)
	var player := TestPlayer.new()
	world.add_child(player)
	player.position = Vector3(0, 0.05, 0)
	await frames(20)
	check(player.is_on_floor(), "player settles on floor")
	player.request_jump()
	await frames(8)
	check(player.position.y > 0.2, "real physics jump raises character")
	var y_before := player.position.y
	player.request_jump()
	await frames(50)
	check(player.is_on_floor() and player.position.y < y_before, "lands without air jump")
	player.locked = true
	player.request_jump()
	await frames(3)
	check(is_zero_approx(player.velocity.y), "locked player cannot jump")
	player.locked = false
	player.in_vehicle = true
	player.request_jump()
	await frames(3)
	check(is_zero_approx(player.velocity.y), "vehicle player cannot jump")
	player.in_vehicle = false

	var camera := CameraRig.new()
	world.add_child(camera)
	camera.set_process(false)
	var wall := StaticBody3D.new()
	var wall_col := CollisionShape3D.new()
	var wall_shape := BoxShape3D.new()
	wall_shape.size = Vector3(4, 4, 0.2)
	wall_col.shape = wall_shape
	wall.add_child(wall_col)
	wall.position = Vector3(0, 2, 1.5)
	world.add_child(wall)
	await frames(3)
	var resolved := camera.resolve_obstruction(Vector3(0, 2, 0), Vector3(0, 2, 5))
	check(resolved.z < 1.4 and resolved.z > 0.5, "camera stops before close wall")
	var unobstructed := camera.resolve_obstruction(Vector3(0, 2, 0), Vector3(5, 2, 0))
	check(unobstructed.is_equal_approx(Vector3(5, 2, 0)), "camera retains unobstructed distance")
	camera.set_vehicle_mode(true)
	check(camera.vehicle_mode and camera.arm_length == 13.8, "vehicle camera mode retained")
	camera.set_aircraft_mode(true)
	check(camera.aircraft_mode and camera.arm_length == 22.0, "aircraft camera mode retained")
	camera.add_look(Vector2(0, 10000))
	check(camera.pitch >= -0.92, "camera pitch clamped")

	var touch := TouchControls.new()
	root.add_child(touch)
	touch.jump_pressed = true
	check(touch.consume_jump() and not touch.consume_jump(), "touch jump consumed once")
	touch.sprint = true
	touch.set_driving(true)
	check(not touch.sprint and not touch._jump_btn.visible, "vehicle mode clears touch running and hides jump")
	touch.set_driving(false)
	check(touch._jump_btn.visible and touch._sprint_btn.visible, "on foot touch buttons restored")
	var stamina_before := player.stamina
	touch.sprint = true
	touch.move = Vector2(1, -1)
	await frames(3)
	check(player.stamina < stamina_before, "touch RUN consumes stamina")
	check(Vector2(player.velocity.x, player.velocity.z).length() <= Player.SPRINT_SPEED + 0.01, "diagonal input cannot exceed sprint speed")
	touch.sprint = false
	touch.move = Vector2.ZERO
	stamina_before = player.stamina
	await frames(3)
	check(player.stamina > stamina_before, "stamina recovers when touch RUN released")

	var environment := Environment.new()
	var sun := DirectionalLight3D.new()
	GraphicsProfile.apply(environment, sun, GraphicsProfile.Quality.LOW)
	check(not environment.sdfgi_enabled and not environment.ssr_enabled and not sun.shadow_enabled, "low preset disables expensive lighting")
	GraphicsProfile.apply(environment, sun, GraphicsProfile.Quality.HIGH)
	var advanced := RenderingServer.get_current_rendering_method() == "forward_plus"
	check(environment.sdfgi_enabled == advanced and environment.ssr_enabled == advanced and sun.shadow_enabled, "high preset restores supported lighting")
	sun.free()
	touch.queue_free()
	world.queue_free()
	await process_frame
	print("STAGE_ONE: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
