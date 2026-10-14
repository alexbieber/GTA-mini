class_name MatchArena
extends Node3D
## Both maps use shared modular geometry; collision footprints also drive A*.
const ORIGIN := Vector3.ZERO
var definition: ArenaDefinition
var navigation := AStarGrid2D.new()
var obstacles: Array[Rect2] = []
var bases: Dictionary = {}
var _objective_meshes: Dictionary = {}
var zone_mesh: MeshInstance3D
var _materials: Dictionary = {}
var _batches: Dictionary = {}
var _nav_half := Vector2i(38, 25)
var _plateau := Rect2(35, 36, 65, 64)
var _ramp := Rect2(27, 48, 8, 18)

func _ready() -> void:
	if definition == null: definition = load("res://resources/maps/protege_o_corre.tres") as ArenaDefinition
	position = ORIGIN
	var half := definition.dimensions * 0.5
	_build_box(Vector3(0, -0.5, 0), Vector3(definition.dimensions.x, 1, definition.dimensions.y), Color("867a67"))
	for x in [-half.x, half.x]:
		_build_box(Vector3(x, 2, 0), Vector3(1, 4, definition.dimensions.y), Color("a9987c"))
	for z in [-half.y, half.y]:
		_build_box(Vector3(0, 2, z), Vector3(definition.dimensions.x, 4, 1), Color("a9987c"))
	if definition.favela: _build_favela()
	else: _build_corre()
	for team in 2:
		var x := -definition.base_distance if team == 0 else definition.base_distance
		bases[team] = Vector3(x, 0.1, 0)
		if not definition.favela:
			var mesh := CylinderMesh.new()
			mesh.top_radius = 5.0
			mesh.bottom_radius = 5.0
			mesh.height = 0.05
			_instance("base", mesh, Transform3D(Basis.IDENTITY, Vector3(x, 0.025, 0)), team_color(team))
			_tag("POLÍCIA" if team == 0 else "COLETIVO AURORA", Vector3(x, 3, 0), team_color(team))
	_nav_half = Vector2i(floori((half.x - 4) / 2), floori((half.y - 4) / 2))
	navigation.region = Rect2i(-_nav_half, _nav_half * 2 + Vector2i.ONE)
	navigation.cell_size = Vector2(2, 2)
	navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	navigation.update()
	for x in range(-_nav_half.x, _nav_half.x + 1):
		for z in range(-_nav_half.y, _nav_half.y + 1):
			for obstacle in obstacles:
				if obstacle.grow(0.85).has_point(Vector2(x * 2, z * 2)):
					navigation.set_point_solid(Vector2i(x, z))
	_flush_batches()

static func team_color(team: int) -> Color:
	return Color("4299d9") if team == 0 else Color("efad45")

func _build_corre() -> void:
	for x in [-28.0, 28.0]:
		for z in [-20.0, 20.0]:
			_house(Vector2(x, z), Vector2(20, 16), 5.2, Color("ae7856"), false)
	# Spawn screens remove every direct shot between the opposing spawn rows.
	for x in [-52.0, 52.0]:
		_obstacle(Vector2(x, 0), Vector2(3, 24), 3.2, Color("cabca4"))
	for at in [Vector2(-10, -6), Vector2(10, 6), Vector2(-12, -38), Vector2(12, 38)]:
		_obstacle(at, Vector2(5, 3), 1.2, Color("806944"))
	for z in [-38.0, 0.0, 38.0]:
		_build_box(Vector3(0, 0.012, z), Vector3(150, 0.02, 7), Color("625e56"), false)
		for x in [-60.0, -40.0, -20.0, 0.0, 20.0, 40.0, 60.0]:
			_build_box(Vector3(x, 0.035, z), Vector3(3, 0.025, 0.08), Color("ded6ba"), false)
	_tag("PÁTIO DO CORRE", Vector3(0, 3, -8), Color("efad45"))
	_tag("ARSENAL", Vector3(-64, 1.5, 8), team_color(0))
	_tag("ARSENAL", Vector3(64, 1.5, 8), team_color(1))
	_poles([-65.0, 0.0, 65.0], [-45.0, 45.0])

func _build_favela() -> void:
	# One elevated neighborhood, reachable through a continuous ramp.
	_build_box(Vector3(67.5, 0.8, 68), Vector3(65, 1.6, 64), Color("867a67"))
	var angle := -atan2(1.6, 8.0)
	var basis := Basis(Vector3.FORWARD, angle)
	var ramp_position := Vector3(31, 0.7, 57)
	_build_box(ramp_position, Vector3(sqrt(66.56), 0.2, 18), Color("929086"), true, basis)
	# Nav perimeter follows the actual impassable 1.6m plateau step, except ramp.
	obstacles.append(Rect2(34, 36, 1, 11))
	obstacles.append(Rect2(34, 67, 1, 33))
	obstacles.append(Rect2(99, 36, 1, 64))
	obstacles.append(Rect2(35, 35, 65, 1))
	obstacles.append(Rect2(35, 99, 65, 1))
	var colors := [Color("b97350"), Color("bc9a6e"), Color("70969a"), Color("9a8b76"), Color("aeaaa0"), Color("bb8b72")]
	var index := 0
	for x in [-76.0, -44.0, -12.0, 20.0, 52.0, 84.0]:
		for z in [-76.0, -44.0, -12.0, 20.0, 52.0, 84.0]:
			if absf(x) < 25 and absf(z) < 25: continue
			var dimensions := Vector2(12 if index % 2 == 0 else 15, 12)
			var height := 3.4 + float(index % 3) * 0.45
			_house(Vector2(x, z), dimensions, height, colors[index % colors.size()], index % 7 == 0)
			index += 1
	for at in [Vector2(-8, -27), Vector2(28, 10), Vector2(-35, 30), Vector2(10, -55)]:
		_obstacle(at, Vector2(4, 2), 1.2, Color("806944"))
	_build_box(Vector3(0, 0.02, 0), Vector3(32, 0.04, 32), Color("aaa28a"), false)
	_tag("PRAÇA DA AURORA", Vector3(0, 3, -12), Color("efad45"))
	_tag("MERCADINHO SOL", Vector3(-44, 3.1, -69), Color("ead38a"))
	_tag("BAR DA LAJE", Vector3(20, 3.2, 27), Color("ead38a"))
	_poles([-96.0, -32.0, 32.0, 96.0], [-96.0, -32.0, 32.0, 96.0])

func height_at(at: Vector3) -> float:
	if not definition.favela: return 0.0
	var point := Vector2(at.x, at.z)
	if _plateau.has_point(point): return 1.6
	if _ramp.has_point(point): return clampf((at.x - 27.0) / 8.0, 0.0, 1.0) * 1.6
	return 0.0

func _house(center: Vector2, dimensions: Vector2, height: float, color: Color, stairs: bool) -> void:
	var floor_y := height_at(Vector3(center.x, 0, center.y))
	_obstacle(center, dimensions, height, color)
	_build_box(Vector3(center.x, floor_y + height + 0.12, center.y), Vector3(dimensions.x + 0.5, 0.24, dimensions.y + 0.5), Color("b9b3a4"))
	for x in [-dimensions.x * 0.27, dimensions.x * 0.27]:
		_build_box(Vector3(center.x + x, floor_y + 1.8, center.y + dimensions.y * 0.5 + 0.03), Vector3(1.4, 1.3, 0.08), Color("374755"), false)
	_build_box(Vector3(center.x, floor_y + 1.1, center.y + dimensions.y * 0.5 + 0.05), Vector3(1.2, 2.2, 0.1), Color("705c48"), false)
	var tank := CylinderMesh.new()
	tank.top_radius = 0.8
	tank.bottom_radius = 0.8
	tank.height = 1.2
	_instance("tank", tank, Transform3D(Basis.IDENTITY, Vector3(center.x - 2, floor_y + height + 0.85, center.y)), Color("376787"))
	if stairs:
		var steps := ceili((height + 0.24) / 0.18)
		var stair_x := center.x + dimensions.x * 0.5 + 1.35
		for i in steps:
			var h := float(i + 1) * (height + 0.24) / steps
			var z := center.y + dimensions.y * 0.5 - float(i) * 0.34
			_build_box(Vector3(stair_x, floor_y + h * 0.5, z), Vector3(2.6, h, 0.35), Color("b9b3a4"))
		obstacles.append(Rect2(stair_x - 1.4, center.y + dimensions.y * 0.5 - steps * 0.34, 2.8, steps * 0.34 + 0.7))
		_build_box(Vector3(stair_x, floor_y + height + 0.12, center.y + dimensions.y * 0.5 - steps * 0.34), Vector3(3, 0.24, 2), Color("b9b3a4"))

func _poles(xs: Array, zs: Array) -> void:
	for z in zs:
		var previous := Vector3.ZERO
		for x in xs:
			var at := Vector3(x, height_at(Vector3(x, 0, z)), z)
			_build_box(at + Vector3(0, 3.5, 0), Vector3(0.18, 7, 0.18), Color("766854"))
			var top := at + Vector3(0, 6.8, 0)
			if previous != Vector3.ZERO: _wire(previous, top)
			previous = top

func _wire(from: Vector3, to: Vector3) -> void:
	var basis := Basis.looking_at((to - from).normalized(), Vector3.UP).scaled(Vector3(0.018, 0.018, from.distance_to(to)))
	_instance("box", BoxMesh.new(), Transform3D(basis, (from + to) * 0.5), Color("272b2e"))

func _tag(text: String, at: Vector3, color: Color) -> void:
	var tag := Label3D.new()
	tag.text = text
	tag.position = at
	tag.modulate = color
	tag.font_size = 36
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(tag)

func _obstacle(center: Vector2, dimensions: Vector2, height: float, color: Color) -> void:
	obstacles.append(Rect2(center - dimensions * 0.5, dimensions))
	var base := height_at(Vector3(center.x, 0, center.y))
	_build_box(Vector3(center.x, base + height * 0.5, center.y), Vector3(dimensions.x, height, dimensions.y), color)

func material(color: Color) -> StandardMaterial3D:
	var key := color.to_html()
	if not _materials.has(key):
		var made := StandardMaterial3D.new()
		made.albedo_color = color
		made.roughness = 0.85
		_materials[key] = made
	return _materials[key]

func _build_box(at: Vector3, size: Vector3, color: Color, collision := true, basis := Basis.IDENTITY) -> void:
	if collision:
		var body := StaticBody3D.new()
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		col.shape = shape
		body.add_child(col)
		body.transform = Transform3D(basis, at)
		add_child(body)
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE
	_instance("box", mesh, Transform3D(basis.scaled(size), at), color)

func _instance(kind: String, mesh: Mesh, transform: Transform3D, color: Color) -> void:
	var key := kind + color.to_html()
	if not _batches.has(key): _batches[key] = {"mesh": mesh, "material": material(color), "transforms": []}
	_batches[key].transforms.append(transform)

func _flush_batches() -> void:
	for batch in _batches.values():
		var instances := MultiMesh.new()
		instances.transform_format = MultiMesh.TRANSFORM_3D
		instances.mesh = batch.mesh
		instances.instance_count = batch.transforms.size()
		for i in batch.transforms.size(): instances.set_instance_transform(i, batch.transforms[i])
		var node := MultiMeshInstance3D.new()
		node.multimesh = instances
		node.material_override = batch.material
		node.visibility_range_end = 280.0
		add_child(node)
	_batches.clear()

func cell(at: Vector3) -> Vector2i:
	return Vector2i(clampi(roundi(at.x / 2.0), -_nav_half.x, _nav_half.x), clampi(roundi(at.z / 2.0), -_nav_half.y, _nav_half.y))

func nearest_clear(at: Vector3) -> Vector3:
	var start := cell(at)
	for distance in range(0, 16):
		for x in range(-distance, distance + 1):
			for z in range(-distance, distance + 1):
				var candidate := start + Vector2i(x, z)
				if navigation.is_in_boundsv(candidate) and not navigation.is_point_solid(candidate):
					var result := Vector3(candidate.x * 2, 0, candidate.y * 2)
					result.y = height_at(result) + 0.12
					return result
	return Vector3(0, 0.12, 0)

func route(from: Vector3, to: Vector3) -> PackedVector3Array:
	var result := PackedVector3Array()
	var start := cell(nearest_clear(from))
	var end := cell(nearest_clear(to))
	for point in navigation.get_point_path(start, end):
		var at := Vector3(point.x, 0, point.y)
		at.y = height_at(at) + 0.12
		result.append(at)
	return result

func valid_zone_center(center: Vector3) -> bool:
	if absf(center.x) > 35.0 or absf(center.z) > 35.0: return false
	for obstacle in obstacles:
		if obstacle.grow(2.5).has_point(Vector2(center.x, center.z)): return false
	return true

func sync_objectives(items: Dictionary) -> void:
	for item: ObjectiveState in items.values():
		if not _objective_meshes.has(item.id):
			var view := MeshInstance3D.new()
			var mesh := BoxMesh.new()
			mesh.size = Vector3(0.65, 0.45, 0.4)
			view.mesh = mesh
			view.material_override = material(team_color(item.owner))
			add_child(view)
			var tag := Label3D.new()
			tag.text = item.label
			tag.position.y = 0.8
			tag.font_size = 24
			tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			view.add_child(tag)
			_objective_meshes[item.id] = view
		var view: MeshInstance3D = _objective_meshes[item.id]
		view.visible = item.state not in [ObjectiveState.Status.CAPTURED, ObjectiveState.Status.RETURNING]
		view.global_position = item.position + Vector3.UP * (1.7 if item.state == ObjectiveState.Status.CARRIED else 0.4)

func sync_zone(center: Vector3, radius: float) -> void:
	if zone_mesh == null:
		zone_mesh = MeshInstance3D.new()
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color("6be7df")
		zone_mesh.material_override = mat
		add_child(zone_mesh)
	var geometry := ImmediateMesh.new()
	geometry.surface_begin(Mesh.PRIMITIVE_LINES)
	for i in 96:
		for angle in [TAU * i / 96.0, TAU * (i + 1) / 96.0]:
			geometry.surface_add_vertex(Vector3(cos(angle) * radius, 0.2, sin(angle) * radius))
	geometry.surface_end()
	zone_mesh.mesh = geometry
	zone_mesh.global_position = center