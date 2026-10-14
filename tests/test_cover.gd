extends SceneTree
var failures := 0
var checks := 0
class TestPlayer extends Player:
	func _build_mesh() -> void: pass
func _initialize() -> void: call_deferred("run")
func check(ok: bool, text: String) -> void:
	checks += 1
	if ok: print("PASS: " + text)
	else:
		failures += 1
		push_error("FAIL: " + text)
func frames(n: int) -> void:
	for i in n:
		await physics_frame
		await process_frame
func box(parent: Node3D, at: Vector3, dimensions: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = dimensions
	col.shape = shape
	body.add_child(col)
	parent.add_child(body)
	body.position = at
	return body
func run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	box(world, Vector3(0, -0.5, 0), Vector3(20, 1, 20))
	var player := TestPlayer.new()
	world.add_child(player)
	await frames(12)
	check(not player.request_cover(), "cover rejects open space and horizontal floor")
	var wall := box(world, Vector3(0, 1.5, -1), Vector3(4, 3, 0.2))
	await frames(3)
	check(player.request_cover() and player.in_cover, "static wall admits cover with validated capsule placement")
	check(player.position.z > -0.6 and player.position.z < -0.3, "cover maintains capsule clearance from wall")
	Input.action_press("move_forward")
	await frames(6)
	Input.action_release("move_forward")
	check(absf(player.velocity.z) < 0.01, "cover constrains movement along surface")
	var x := player.position.x
	Input.action_press("move_left")
	await frames(10)
	Input.action_release("move_left")
	check(player.position.x < x - 0.3 and player.in_cover, "lateral movement remains attached to eligible wall")
	player.request_cover()
	check(not player.in_cover, "cover toggle exits cleanly")
	wall.queue_free()
	await frames(3)
	box(world, Vector3(0, 0.6, -1), Vector3(4, 1.2, 0.2))
	player.position = Vector3(0, 0.05, 0)
	player.rotation = Vector3.ZERO
	await frames(12)
	check(player.request_cover() and player.crouched, "low cover crouches player behind obstruction")
	player.give_weapon(Arsenal.Id.RIFLE)
	Input.action_press("aim")
	await frames(5)
	check(player.in_cover and player.aiming and not player.crouched, "ADS exposes player over low cover after standing-space validation")
	Input.action_release("aim")
	await frames(3)
	check(player.crouched, "releasing ADS returns to protection")
	player.request_jump()
	check(not player.in_cover, "jump cancels cover")
	world.queue_free()
	await process_frame
	print("COVER: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
