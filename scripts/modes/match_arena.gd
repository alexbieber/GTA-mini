class_name MatchArena
extends Node3D
## Original compact urban annex; one collision layout also drives bot A*.
const ORIGIN := Vector3(850, 0, 0)
const LIMIT := 90.0
var navigation := AStarGrid2D.new()
var obstacles: Array[Rect2] = []
var bases: Dictionary = {}
var _objective_meshes: Dictionary = {}
var zone_mesh: MeshInstance3D

func _ready() -> void:
	position = ORIGIN
	_build_box(Vector3(0, -0.5, 0), Vector3(180, 1, 180), Color("404952"))
	for x in [-90.0, 90.0]:
		_build_box(Vector3(x, 2, 0), Vector3(1, 4, 180), Color("73818b"))
	for z in [-90.0, 90.0]:
		_build_box(Vector3(0, 2, z), Vector3(180, 4, 1), Color("73818b"))
	for center in [Vector2(-30, -28), Vector2(-30, 28), Vector2(30, -28), Vector2(30, 28)]:
		_obstacle(center, Vector2(18, 24), 12.0, Color("6d7c88"))
	for center in [Vector2(-12, -10), Vector2(12, 10), Vector2(-12, 35), Vector2(12, -35)]:
		_obstacle(center, Vector2(5, 3), 1.25, Color("a48659"))
	for team in 2:
		var x := -64.0 if team == 0 else 64.0
		bases[team] = ORIGIN + Vector3(x, 0.1, 0)
		var pad := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 5.0
		mesh.bottom_radius = 5.0
		mesh.height = 0.03
		pad.mesh = mesh
		pad.material_override = Palette.mat(team_color(team))
		pad.position = Vector3(x, 0.025, 0)
		add_child(pad)
		var label := Label3D.new()
		label.text = "POLÍCIA" if team == 0 else "COLETIVO AURORA"
		label.position = Vector3(x, 3, 0)
		label.font_size = 48
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(label)
	for z in [-65.0, 65.0]:
		for x in [-50.0, 0.0, 50.0]:
			var lamp := OmniLight3D.new()
			lamp.position = Vector3(x, 4, z)
			lamp.omni_range = 20.0
			lamp.light_energy = 1.5
			lamp.shadow_enabled = false
			add_child(lamp)
	navigation.region = Rect2i(-43, -43, 87, 87)
	navigation.cell_size = Vector2(2, 2)
	navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	navigation.update()
	for x in range(-43, 44):
		for z in range(-43, 44):
			for obstacle in obstacles:
				if obstacle.grow(0.8).has_point(Vector2(x * 2, z * 2)):
					navigation.set_point_solid(Vector2i(x, z))

static func team_color(team: int) -> Color:
	return Color("4299d9") if team == 0 else Color("efad45")

func _obstacle(center: Vector2, dimensions: Vector2, height: float, color: Color) -> void:
	obstacles.append(Rect2(center - dimensions * 0.5, dimensions))
	_build_box(Vector3(center.x, height * 0.5, center.y), Vector3(dimensions.x, height, dimensions.y), color)

func _build_box(at: Vector3, size: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	var view := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	view.mesh = mesh
	view.material_override = Palette.mat(color, 0.05, 0.8)
	body.add_child(view)
	body.position = at
	add_child(body)

func cell(at: Vector3) -> Vector2i:
	var local := at - ORIGIN
	return Vector2i(clampi(roundi(local.x / 2.0), -43, 43), clampi(roundi(local.z / 2.0), -43, 43))

func route(from: Vector3, to: Vector3) -> PackedVector3Array:
	var result := PackedVector3Array()
	var start := cell(from)
	var end := cell(to)
	if navigation.is_point_solid(start) or navigation.is_point_solid(end):
		return result
	for point in navigation.get_point_path(start, end):
		result.append(ORIGIN + Vector3(point.x, 0.1, point.y))
	result.append(Vector3(to.x, 0.1, to.z))
	return result

func valid_zone_center(center: Vector3) -> bool:
	var local := center - ORIGIN
	if absf(local.x) > 40.0 or absf(local.z) > 40.0:
		return false
	for obstacle in obstacles:
		if obstacle.grow(2.5).has_point(Vector2(local.x, local.z)):
			return false
	return true

func sync_objectives(items: Dictionary) -> void:
	for item: ObjectiveState in items.values():
		if not _objective_meshes.has(item.id):
			var view := MeshInstance3D.new()
			var mesh := BoxMesh.new()
			mesh.size = Vector3(0.65, 0.45, 0.4)
			view.mesh = mesh
			view.material_override = Palette.mat(team_color(item.owner), 0.2, 0.5)
			add_child(view)
			var label := Label3D.new()
			label.text = item.label
			label.position.y = 0.8
			label.font_size = 24
			label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			view.add_child(label)
			_objective_meshes[item.id] = view
		var view: MeshInstance3D = _objective_meshes[item.id]
		view.visible = item.state not in [ObjectiveState.Status.CAPTURED, ObjectiveState.Status.RETURNING]
		view.global_position = item.position + Vector3.UP * (1.7 if item.state == ObjectiveState.Status.CARRIED else 0.4)

func sync_zone(center: Vector3, radius: float) -> void:
	if zone_mesh == null:
		zone_mesh = MeshInstance3D.new()
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = Color("6be7df")
		zone_mesh.material_override = material
		add_child(zone_mesh)
	var geometry := ImmediateMesh.new()
	geometry.surface_begin(Mesh.PRIMITIVE_LINES)
	for i in 96:
		for angle in [TAU * i / 96.0, TAU * (i + 1) / 96.0]:
			geometry.surface_add_vertex(Vector3(cos(angle) * radius, 0.15, sin(angle) * radius))
	geometry.surface_end()
	zone_mesh.mesh = geometry
	zone_mesh.global_position = center
