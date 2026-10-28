extends SceneTree
## Rendering smoke capture, not a manual gameplay or performance benchmark.
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.begin()
	game.player.give_weapon(Arsenal.Id.RIFLE)
	Input.action_press("aim")
	for i in 90:
		await process_frame
	await RenderingServer.frame_post_draw
	var path := OS.get_environment("TEMP").path_join("caos-combat.png")
	var error := root.get_texture().get_image().save_png(path)
	print("CAPTURE: ", path, " result=", error)
	Input.action_release("aim")
	game.queue_free()
	await process_frame
	quit(error)
