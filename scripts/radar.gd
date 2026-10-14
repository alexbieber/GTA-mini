class_name Radar
extends Control

var world_span := 360.0


func _ready() -> void:
	custom_minimum_size = Vector2(148, 148)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true


func _draw() -> void:
	var r := size * 0.5
	var c := size * 0.5
	draw_circle(c, r.x - 2.0, Color(0.04, 0.07, 0.08, 0.72))
	draw_arc(c, r.x - 3.0, 0, TAU, 40, Color("f0a030"), 2.0)
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return
	var origin := player.global_position
	var game := get_tree().current_scene
	var tracked: Node3D = player
	if game and game.get("active_aircraft") and game.active_aircraft:
		tracked = game.active_aircraft
		origin = tracked.global_position
	elif game and game.get("active_vehicle") and game.active_vehicle:
		tracked = game.active_vehicle
		origin = tracked.global_position
	if game and game.get("matches") and game.matches.competitive():
		_draw_match(game.matches, origin, c, r.x - 8.0)
		return
	for node in get_tree().get_nodes_in_group("peds"):
		_blip(origin, (node as Node3D).global_position, c, r.x - 8.0, Color(0.7, 0.7, 0.65, 0.55), 2.0)
	for node in get_tree().get_nodes_in_group("vehicles"):
		var v := node as Vehicle
		if v == null or v.occupied:
			continue
		var col := Color(0.55, 0.6, 0.7, 0.8)
		if v.kind == Vehicle.Kind.COP:
			col = Color("ff4a4a")
		elif v.kind == Vehicle.Kind.COUPE:
			col = Palette.amber()
		elif v.kind == Vehicle.Kind.MILITARY:
			col = Color("6a8a3a")
		_blip(origin, v.global_position, c, r.x - 8.0, col, 3.2)
	for node in get_tree().get_nodes_in_group("aircraft"):
		_blip(origin, (node as Node3D).global_position, c, r.x - 8.0, Color("9ad46a"), 4.0)
	if game:
		var city = game.get("city")
		if city:
			_blip(origin, city.gun_shop_pos, c, r.x - 8.0, Color("c45a2a"), 2.6)
			_blip(origin, city.bar_pos, c, r.x - 8.0, Color("f0a030"), 2.6)
			_blip(origin, city.base_pos, c, r.x - 8.0, Color("6dff88"), 3.0)
	if game and game.has_method("radar_objective"):
		var obj: Vector3 = game.radar_objective()
		if obj != Vector3.ZERO:
			_blip(origin, obj, c, r.x - 8.0, Color("5dff88"), 4.0)
	draw_colored_polygon([
		c + Vector2(0, -7),
		c + Vector2(5, 6),
		c + Vector2(-5, 6),
	], Color("f0e6c8"))


func _blip(origin: Vector3, pos: Vector3, center: Vector2, radius: float, color: Color, size_px: float) -> void:
	var d := Vector2(pos.x - origin.x, pos.z - origin.z)
	d = d / world_span * radius
	if d.length() > radius:
		d = d.limit_length(radius)
	draw_circle(center + d, size_px, color)

func _draw_match(manager: MatchManager, origin: Vector3, center: Vector2, radius_px: float) -> void:
	var span := 180.0
	if manager.zone:
		var zone_center := center + Vector2(manager.zone.center.x - origin.x, manager.zone.center.z - origin.z) / span * radius_px
		draw_arc(zone_center, manager.zone.radius / span * radius_px, 0, TAU, 64, Color("6be7df"), 1.5)
	for member in manager.rules.participants.values():
		if not member.alive:
			continue
		var at: Vector3 = member.position
		var delta := Vector2(at.x - origin.x, at.z - origin.z) / span * radius_px
		var color := MatchArena.team_color(member.team) if not manager.zone else Color("ff6a6a")
		draw_circle(center + delta.limit_length(radius_px), 3, Color.WHITE if member.id == 0 else color)
	for item: ObjectiveState in manager.rules.objectives.values():
		if item.state in [ObjectiveState.Status.CAPTURED, ObjectiveState.Status.RETURNING]:
			continue
		var delta := Vector2(item.position.x - origin.x, item.position.z - origin.z) / span * radius_px
		draw_circle(center + delta.limit_length(radius_px), 4, MatchArena.team_color(item.owner))


func _process(_delta: float) -> void:
	queue_redraw()
