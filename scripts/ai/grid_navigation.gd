class_name GridNavigation
extends RefCounted
## Generate a real server navigation surface from the arena's clearance grid.
## No collider parsing, texture baking or per-bot mesh duplication is needed.
static func ensure_region(arena: Node3D) -> NavigationRegion3D:
	if arena.has_meta("bot_navigation_region"):
		return arena.get_meta("bot_navigation_region") as NavigationRegion3D
	var grid: AStarGrid2D = arena.navigation
	var mesh := NavigationMesh.new()
	mesh.agent_radius = 0.34
	mesh.agent_height = 1.72
	var vertices := PackedVector3Array()
	var vertex_ids: Dictionary = {}
	var polygons: Array[PackedInt32Array] = []
	for x in range(grid.region.position.x, grid.region.end.x):
		for z in range(grid.region.position.y, grid.region.end.y):
			if grid.is_point_solid(Vector2i(x, z)): continue
			var footprint := Rect2(Vector2(x * 2 - 1, z * 2 - 1), Vector2(2, 2))
			var blocked := false
			for obstacle in arena.obstacles:
				if footprint.intersects(obstacle.grow(0.4)):
					blocked = true
					break
			if blocked: continue
			var polygon := PackedInt32Array()
			for corner in [Vector2i(x * 2 - 1, z * 2 - 1), Vector2i(x * 2 - 1, z * 2 + 1), Vector2i(x * 2 + 1, z * 2 + 1), Vector2i(x * 2 + 1, z * 2 - 1)]:
				if not vertex_ids.has(corner):
					var point := Vector3(corner.x, 0, corner.y)
					point.y = arena.height_at(point)
					vertex_ids[corner] = vertices.size()
					vertices.append(point)
				polygon.append(vertex_ids[corner])
			polygons.append(polygon)
	mesh.vertices = vertices
	for polygon in polygons: mesh.add_polygon(polygon)
	var region := NavigationRegion3D.new()
	region.name = "BotNavigationSurface"
	region.navigation_mesh = mesh
	region.use_edge_connections = false
	arena.add_child(region)
	arena.set_meta("bot_navigation_region", region)
	return region
