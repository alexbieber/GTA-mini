class_name City
extends Node3D

const Models = preload("res://scripts/models.gd")

const AVE_STEP := 50.0
const ST_STEP := 38.0
const AVE_N := 11
const ST_N := 15
const ROAD_W := 9.4

var ave_xs: Array[float] = []
var st_zs: Array[float] = []

var player_spawn := Vector3(8, 0.15, 45.6)
var coupe_spawn := Vector3(-100, 0.15, 0)
var coupe_facing := PI * 0.5
var garage_pos := Vector3(-50, 0.15, -228)
var hospital_pos := Vector3(150, 0.15, 190)
var station_pos := Vector3(200, 0.15, 38)
var spray_pos := Vector3(-200, 0.15, 0)
var gun_shop_pos := Vector3(-80, 0.15, -80)
var bar_pos := Vector3(80, 0.15, 80)
var base_pos := Vector3(-80, 0.15, 280)
var aircraft_spawns: Array[Dictionary] = []
var military_spawns: Array[Dictionary] = []
var crate_spawns: Array[Vector3] = []
var patrol: Array[Vector3] = []
var cop_spawns: Array[Vector3] = []
var parked_spawns: Array[Dictionary] = []
var traffic_spawns: Array[Dictionary] = []
var sidewalk_paths: Array = []
var package_spawns: Array[Vector3] = []
var health_spawns: Array[Vector3] = []

var street_lamps: Array[Light3D] = []
var window_mats: Array[StandardMaterial3D] = []
var road_mats: Array[StandardMaterial3D] = []
var neon_mats: Array[StandardMaterial3D] = []
var water_mat: ShaderMaterial

var _garage: Area3D
var _spray: Area3D
var _water: MeshInstance3D
var _facades: Dictionary = {}


func make_graph() -> RoadGraph:
	return RoadGraph.grid(ave_xs, st_zs)


func build() -> void:
	_grid()
	_ground()
	_water_body()
	_roads()
	_buildings()
	_lamps()
	_props()
	_pier()
	_garage_zone()
	_civic_zones()
	_shops()
	_army_base()
	_markers()
	refresh_reflections()


func refresh_reflections() -> void:
	for node in get_children():
		if node is ReflectionProbe:
			node.queue_free()
	var probe := ReflectionProbe.new()
	probe.position = Vector3(0, 48, 0)
	probe.size = Vector3(720, 180, 800)
	probe.box_projection = true
	probe.interior = false
	probe.update_mode = ReflectionProbe.UPDATE_ONCE
	add_child(probe)


func apply_time(night: bool) -> void:
	for lamp in street_lamps:
		lamp.visible = night
		lamp.light_energy = 3.6 if night else 0.0
	for m in window_mats:
		m.emission_energy_multiplier = 0.55 if night else 0.03
	for m in neon_mats:
		m.emission_energy_multiplier = 4.2 if night else 0.35
	for m in road_mats:
		m.roughness = 0.42 if night else 0.78
		m.metallic = 0.08 if night else 0.0
	if water_mat:
		water_mat.set_shader_parameter("glow", 0.22 if night else 0.04)
		water_mat.set_shader_parameter("roughness_val", 0.06 if night else 0.14)
		if night:
			water_mat.set_shader_parameter("deep_color", Color("061018"))
			water_mat.set_shader_parameter("shallow_color", Color("163848"))
		else:
			water_mat.set_shader_parameter("deep_color", Color("1a5a72"))
			water_mat.set_shader_parameter("shallow_color", Color("4aa0b4"))


func spray_contains(node: Node3D) -> bool:
	return _area_has(_spray, node)


func near_gun_shop(pos: Vector3) -> bool:
	return pos.distance_to(gun_shop_pos) < 5.4


func near_bar(pos: Vector3) -> bool:
	return pos.distance_to(bar_pos) < 5.0


func on_base(pos: Vector3) -> bool:
	return absf(pos.x - base_pos.x) < 40.0 and absf(pos.z - base_pos.z) < 34.0


func near_base_gate(pos: Vector3) -> bool:
	return absf(pos.x - base_pos.x) < 32.0 and pos.z > base_pos.z - 52.0 and pos.z < base_pos.z - 18.0


func near_crate(pos: Vector3) -> bool:
	for c in crate_spawns:
		if pos.distance_to(c) < 2.8:
			return true
	return false


func garage_contains(node: Node3D) -> bool:
	if _garage == null or node == null:
		return false
	return _area_has(_garage, node)


func _area_has(area: Area3D, node: Node3D) -> bool:
	if area == null or node == null:
		return false
	for body in area.get_overlapping_bodies():
		if body == node:
			return true
	return false


func _grid() -> void:
	ave_xs.clear()
	st_zs.clear()
	for i in AVE_N:
		ave_xs.append((float(i) - float(AVE_N - 1) * 0.5) * AVE_STEP)
	for j in ST_N:
		st_zs.append((float(j) - float(ST_N - 1) * 0.5) * ST_STEP)
	player_spawn = Vector3(16.0, 0.15, st_zs[8] + 7.6)
	coupe_spawn = Vector3(ave_xs[6] - 6.0, 0.35, st_zs[8])
	coupe_facing = -PI * 0.5
	garage_pos = Vector3((ave_xs[4] + ave_xs[5]) * 0.5, 0.15, (st_zs[1] + st_zs[2]) * 0.5)
	hospital_pos = Vector3((ave_xs[8] + ave_xs[9]) * 0.5, 0.15, (st_zs[12] + st_zs[13]) * 0.5)
	station_pos = Vector3((ave_xs[9] + ave_xs[10]) * 0.5, 0.15, (st_zs[8] + st_zs[9]) * 0.5)
	spray_pos = Vector3((ave_xs[1] + ave_xs[2]) * 0.5, 0.15, (st_zs[7] + st_zs[8]) * 0.5)
	gun_shop_pos = Vector3((ave_xs[7] + ave_xs[8]) * 0.5, 0.15, (st_zs[3] + st_zs[4]) * 0.5)
	bar_pos = Vector3((ave_xs[3] + ave_xs[4]) * 0.5, 0.15, (st_zs[10] + st_zs[11]) * 0.5)
	base_pos = Vector3((ave_xs[2] + ave_xs[3]) * 0.5, 0.15, st_zs[ST_N - 1] + 38.0)


func _ground() -> void:
	var dirt := Palette.surfaced("bitumen", Color("c8c2b8"), 0.0, 0.92, 0.06)
	_static_box(Vector3(0, -0.8, 20), Vector3(620, 1.5, 720), dirt)


func _water_body() -> void:
	var edge := st_zs[0] - 22.0
	_water = MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(620, 90)
	plane.subdivide_width = 28
	plane.subdivide_depth = 12
	_water.mesh = plane
	_water.position = Vector3(0, -0.2, edge - 36.0)
	water_mat = ShaderMaterial.new()
	water_mat.shader = load("res://shaders/water.gdshader")
	_water.material_override = water_mat
	add_child(_water)
	_static_box(Vector3(0, 1.4, edge), Vector3(580, 3.2, 1.6), Palette.surfaced("concrete", Color.WHITE, 0.05, 0.7, 0.22))


func _roads() -> void:
	var road := Palette.surfaced("asphalt", Color.WHITE, 0.0, 0.78, 0.07)
	road_mats.append(road)
	var walk := Palette.surfaced("sidewalk", Color.WHITE, 0.0, 0.78, 0.18)
	var curb := Palette.surfaced("concrete", Color("d8d4cc"), 0.0, 0.7, 0.35)
	var paint := Palette.mat(Color("e8e6dc"), 0.05, 0.42)
	var dash := Palette.mat(Color("e8c84a"), 0.08, 0.38)
	var span_x := (ave_xs[AVE_N - 1] - ave_xs[0]) + 28.0
	var span_z := (st_zs[ST_N - 1] - st_zs[0]) + 28.0
	var mid_x := (ave_xs[0] + ave_xs[AVE_N - 1]) * 0.5
	var mid_z := (st_zs[0] + st_zs[ST_N - 1]) * 0.5
	for z in st_zs:
		_mesh_box(Vector3(mid_x, 0.03, z), Vector3(span_x, 0.05, ROAD_W), road)
		_mesh_box(Vector3(mid_x, 0.07, z - 6.2), Vector3(span_x, 0.12, 0.35), curb)
		_mesh_box(Vector3(mid_x, 0.07, z + 6.2), Vector3(span_x, 0.12, 0.35), curb)
		_mesh_box(Vector3(mid_x, 0.055, z - 7.7), Vector3(span_x, 0.08, 2.6), walk)
		_mesh_box(Vector3(mid_x, 0.055, z + 7.7), Vector3(span_x, 0.08, 2.6), walk)
		_mesh_box(Vector3(mid_x, 0.055, z - 4.55), Vector3(span_x, 0.02, 0.12), paint)
		_mesh_box(Vector3(mid_x, 0.055, z + 4.55), Vector3(span_x, 0.02, 0.12), paint)
		_dashes(Vector3(ave_xs[0] - 10.0, 0.055, z), Vector3(1, 0, 0), span_x + 8.0, dash)
	for x in ave_xs:
		_mesh_box(Vector3(x, 0.035, mid_z), Vector3(ROAD_W, 0.05, span_z), road)
		_mesh_box(Vector3(x - 6.2, 0.07, mid_z), Vector3(0.35, 0.12, span_z), curb)
		_mesh_box(Vector3(x + 6.2, 0.07, mid_z), Vector3(0.35, 0.12, span_z), curb)
		_mesh_box(Vector3(x - 7.7, 0.055, mid_z), Vector3(2.6, 0.08, span_z), walk)
		_mesh_box(Vector3(x + 7.7, 0.055, mid_z), Vector3(2.6, 0.08, span_z), walk)
		_mesh_box(Vector3(x - 4.55, 0.055, mid_z), Vector3(0.12, 0.02, span_z), paint)
		_mesh_box(Vector3(x + 4.55, 0.055, mid_z), Vector3(0.12, 0.02, span_z), paint)
		_dashes(Vector3(x, 0.056, st_zs[0] - 10.0), Vector3(0, 0, 1), span_z + 8.0, dash)


func _buildings() -> void:
	for i in AVE_N - 1:
		for j in ST_N - 1:
			if _is_park(i, j):
				_park_block(i, j)
				continue
			if _is_civic_block(i, j) or (i == 5 and j == 8):
				continue
			_city_block(i, j)
	_landmark(Vector3((ave_xs[5] + ave_xs[6]) * 0.5, 0, (st_zs[8] + st_zs[9]) * 0.5), 142.0, "office")
	_landmark(Vector3((ave_xs[4] + ave_xs[5]) * 0.5, 0, (st_zs[6] + st_zs[7]) * 0.5), 118.0, "concrete")
	_landmark(Vector3((ave_xs[6] + ave_xs[7]) * 0.5, 0, (st_zs[5] + st_zs[6]) * 0.5), 126.0, "office")
	_neon_sign(Vector3(garage_pos.x, 7.2, garage_pos.z + 6.0), "DROP")


func _is_park(i: int, j: int) -> bool:
	return i >= 4 and i <= 5 and j >= 6 and j <= 7


func _is_civic_block(i: int, j: int) -> bool:
	return (i == 4 and j == 1) or (i == 8 and j == 12) or (i == 9 and j == 8) or (i == 1 and j == 7) or (i == 7 and j == 3) or (i == 3 and j == 10)


func _park_block(i: int, j: int) -> void:
	var cx := (ave_xs[i] + ave_xs[i + 1]) * 0.5
	var cz := (st_zs[j] + st_zs[j + 1]) * 0.5
	var grass := Palette.surfaced("grass", Color.WHITE, 0.0, 0.88, 0.14)
	_mesh_box(Vector3(cx, 0.06, cz), Vector3(AVE_STEP - 20.0, 0.08, ST_STEP - 18.0), grass)
	for n in 5:
		var ox := (_h01(i, j, 20 + n) - 0.5) * 14.0
		var oz := (_h01(i, j, 40 + n) - 0.5) * 8.0
		_tree(Vector3(cx + ox, 0, cz + oz))


func _city_block(i: int, j: int) -> void:
	var x0 := ave_xs[i] + 13.8
	var x1 := ave_xs[i + 1] - 13.8
	var z0 := st_zs[j] + 12.4
	var z1 := st_zs[j + 1] - 12.4
	var style := _block_style(i, j)
	var h := _block_height(i, j)
	var mid_x := (x0 + x1) * 0.5
	var mid_z := (z0 + z1) * 0.5
	var w1 := (x1 - x0) * 0.46
	var d := z1 - z0
	_building(Vector3(x0 + w1 * 0.5, 0, mid_z), Vector3(w1, h, d), style)
	var h2 := h * (0.58 + _h01(i, j, 9) * 0.35)
	_building(Vector3(x1 - w1 * 0.5, 0, mid_z), Vector3(w1, h2, d * 0.88), style)


func _block_style(i: int, j: int) -> String:
	if j <= 2:
		return "warehouse" if i % 2 == 0 else "concrete"
	if i >= 4 and i <= 6 and j >= 5 and j <= 9:
		return "office"
	var pick := int(_h01(i, j, 3) * 5.0)
	match pick:
		0:
			return "brick"
		1:
			return "brick_dark"
		2:
			return "concrete"
		3:
			return "plaster"
		_:
			return "office"


func _block_height(i: int, j: int) -> float:
	if j <= 2:
		return 16.0 + _h01(i, j, 4) * 18.0
	var mid := 1.0 - maxf(absf(float(i) - 5.0) / 5.0, absf(float(j) - 7.0) / 7.0)
	if mid > 0.55:
		var tower := 62.0 + _h01(i, j, 5) * 58.0
		if _h01(i, j, 6) > 0.78:
			tower += 36.0
		return tower
	return 22.0 + _h01(i, j, 7) * 28.0


func _landmark(pos: Vector3, height: float, style: String) -> void:
	_building(pos, Vector3(14, height, 12), style, true)
	_neon_sign(pos + Vector3(0, 18.0, 6.2), "NITE")


func _building(pos: Vector3, size: Vector3, style: String, is_drop := false) -> void:
	var facade := _facade_mat(style)
	var body_h := maxf(size.y - 3.2, 4.0)
	var base := Palette.surfaced("concrete", Color("d6d2cc"), 0.04, 0.62, 0.16)
	_static_box(pos + Vector3(0, 1.6, 0), Vector3(size.x + 0.22, 3.2, size.z + 0.22), base)
	_static_box(pos + Vector3(0, 3.2 + body_h * 0.5, 0), Vector3(size.x, body_h, size.z), facade)
	if style != "warehouse":
		var shop_glass := Palette.glass(Color(0.12, 0.16, 0.2, 0.78), Color("f0c878"))
		window_mats.append(shop_glass)
		_mesh_box(pos + Vector3(0, 1.45, size.z * 0.5 + 0.14), Vector3(size.x * 0.78, 2.5, 0.08), shop_glass)
		var door := Palette.mat(Color("1a1614"), 0.35, 0.38)
		_mesh_box(pos + Vector3(-size.x * 0.16, 1.15, size.z * 0.5 + 0.18), Vector3(1.2, 2.2, 0.1), door)
		var awning := Palette.surfaced("metal", Color.WHITE, 0.2, 0.45, 0.8)
		_mesh_box(pos + Vector3(0, 2.85, size.z * 0.5 + 0.55), Vector3(size.x * 0.7, 0.08, 1.1), awning)
	var roof := Palette.surfaced("roof", Color.WHITE, 0.04, 0.68, 0.22)
	var cap := Palette.surfaced("concrete", Color("c8ccd0"), 0.05, 0.58, 0.28)
	_mesh_box(pos + Vector3(0, size.y + 0.16, 0), Vector3(size.x + 0.5, 0.28, size.z + 0.5), cap)
	_mesh_box(pos + Vector3(0, size.y + 0.34, 0), Vector3(size.x - 0.35, 0.16, size.z - 0.35), roof)
	if size.y > 28.0:
		var inset := 1.8
		_static_box(pos + Vector3(0, size.y + 4.2, 0), Vector3(size.x - inset * 2.0, 8.2, size.z - inset * 2.0), facade)
		_mesh_box(pos + Vector3(size.x * 0.18, size.y + 8.9, -size.z * 0.12), Vector3(1.8, 1.1, 1.5), cap)
	if is_drop or size.y > 50.0:
		var tank := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.7
		cyl.bottom_radius = 0.7
		cyl.height = 1.6
		tank.mesh = cyl
		tank.position = pos + Vector3(-size.x * 0.2, size.y + 1.15, size.z * 0.1)
		tank.material_override = Palette.surfaced("warehouse", Color.WHITE, 0.45, 0.35, 0.7)
		add_child(tank)


func _facade_mat(style: String) -> StandardMaterial3D:
	if _facades.has(style):
		return _facades[style]
	var m := Palette.facade(style)
	_facades[style] = m
	window_mats.append(m)
	return m


func _neon_sign(pos: Vector3, _text: String) -> void:
	var board := Palette.mat(Color("0c1016"), 0.2, 0.45)
	_mesh_box(pos, Vector3(7.2, 1.15, 0.1), board)
	var neon := Palette.mat(Palette.amber(), 0.1, 0.25, Palette.amber(), 4.0)
	neon_mats.append(neon)
	_mesh_box(pos + Vector3(0, 0, 0.08), Vector3(6.4, 0.72, 0.06), neon)
	var light := OmniLight3D.new()
	light.position = pos + Vector3(0, 0, 1.2)
	light.light_color = Palette.amber()
	light.light_energy = 3.8
	light.omni_range = 16.0
	street_lamps.append(light)
	add_child(light)


func _lamps() -> void:
	for zi in ST_N:
		for xi in AVE_N:
			if (xi + zi) % 2 != 0:
				continue
			_lamp(Vector3(ave_xs[xi] + 7.1, 0, st_zs[zi] + 7.1))


func _lamp(pos: Vector3) -> void:
	var pole := Palette.surfaced("metal", Color("b8bcc0"), 0.72, 0.32, 1.4)
	_mesh_box(pos + Vector3(0, 2.6, 0), Vector3(0.12, 5.2, 0.12), pole)
	_mesh_box(pos + Vector3(0, 5.3, 0.55), Vector3(0.55, 0.1, 1.15), Palette.mat(Color("1c2026"), 0.7, 0.32))
	var bulb := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.16
	sph.height = 0.32
	bulb.mesh = sph
	bulb.position = pos + Vector3(0, 5.15, 0.7)
	var glass := Palette.mat(Color("fff0c8"), 0.1, 0.2, Color("ffc878"), 0.0)
	neon_mats.append(glass)
	bulb.material_override = glass
	add_child(bulb)
	var light := OmniLight3D.new()
	light.position = pos + Vector3(0, 5.0, 0.7)
	light.light_color = Color("ffb75a")
	light.light_energy = 3.4
	light.omni_range = 18.0
	light.omni_attenuation = 1.4
	light.shadow_enabled = false
	street_lamps.append(light)
	add_child(light)


func _props() -> void:
	_dumpster(Vector3(ave_xs[5] + 14.0, 0.55, st_zs[8] + 9.0))
	_dumpster(Vector3(ave_xs[3] + 14.0, 0.55, st_zs[5] - 9.0))
	_dumpster(Vector3(ave_xs[7] - 14.0, 0.55, st_zs[10] + 9.0))
	_dumpster(Vector3(ave_xs[2] + 14.0, 0.55, st_zs[2] + 9.0))
	_dumpster(Vector3(ave_xs[8] + 14.0, 0.55, st_zs[7] - 9.0))
	_hydrant(Vector3(ave_xs[6] + 8.4, 0.42, st_zs[8] + 8.2))
	_hydrant(Vector3(ave_xs[4] - 8.4, 0.42, st_zs[6] - 8.2))
	_hydrant(Vector3(ave_xs[7] + 8.4, 0.42, st_zs[11] + 8.2))
	_planter(Vector3(ave_xs[5] + 12.2, 0.28, st_zs[9] + 8.0))
	_planter(Vector3(ave_xs[6] - 12.2, 0.28, st_zs[7] - 8.0))
	_tree(Vector3(ave_xs[6] + 12.0, 0, st_zs[9] + 8.5))
	_tree(Vector3(ave_xs[4] - 12.0, 0, st_zs[4] - 8.5))
	_tree(Vector3(ave_xs[8] + 12.0, 0, st_zs[6] + 8.5))
	_tree(Vector3(ave_xs[2] + 12.0, 0, st_zs[10] + 8.5))
	_tree(Vector3(ave_xs[9] - 12.0, 0, st_zs[3] - 8.5))
	_tree(Vector3(ave_xs[5] - 12.0, 0, st_zs[8] - 8.5))
	_tree(Vector3(ave_xs[3] + 12.0, 0, st_zs[12] + 8.5))
	_tree(Vector3(ave_xs[7] - 12.0, 0, st_zs[3] + 8.5))
	_dumpster(Vector3(ave_xs[6] + 14.0, 0.55, st_zs[11] - 9.0))
	_dumpster(Vector3(ave_xs[4] - 14.0, 0.55, st_zs[9] + 9.0))
	_hydrant(Vector3(ave_xs[5] + 8.4, 0.42, st_zs[5] + 8.2))
	_planter(Vector3(ave_xs[8] + 12.2, 0.28, st_zs[8] + 8.0))
	_planter(Vector3(ave_xs[2] - 12.2, 0.28, st_zs[8] - 8.0))
	_crate(Vector3(garage_pos.x - 4.0, 0.45, garage_pos.z - 8.0))
	_crate(Vector3(garage_pos.x + 2.0, 0.45, garage_pos.z - 8.0))
	_crate(Vector3(garage_pos.x - 1.0, 1.2, garage_pos.z - 7.2))


func _dumpster(pos: Vector3) -> void:
	_mesh_box(pos, Vector3(1.8, 1.1, 1.05), Palette.surfaced("metal", Color.WHITE, 0.35, 0.42, 0.7))
	_mesh_box(pos + Vector3(0, 0.62, 0), Vector3(1.85, 0.08, 1.1), Palette.mat(Color("2a2e28"), 0.45, 0.4))


func _hydrant(pos: Vector3) -> void:
	var red := Palette.mat(Color("b42222"), 0.35, 0.38)
	_mesh_box(pos, Vector3(0.28, 0.72, 0.28), red)
	_mesh_box(pos + Vector3(0, 0.42, 0), Vector3(0.46, 0.16, 0.22), red)


func _planter(pos: Vector3) -> void:
	_mesh_box(pos, Vector3(1.15, 0.48, 1.15), Palette.surfaced("concrete", Color("d0ccc6"), 0.0, 0.7, 0.6))
	_mesh_box(pos + Vector3(0, 0.32, 0), Vector3(0.95, 0.12, 0.95), Palette.surfaced("grass", Color.WHITE, 0.0, 0.85, 0.5))


func _tree(pos: Vector3) -> void:
	var trunk := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.12
	cyl.bottom_radius = 0.18
	cyl.height = 4.4
	trunk.mesh = cyl
	trunk.position = pos + Vector3(0, 2.2, 0)
	trunk.material_override = Palette.surfaced("wood", Color.WHITE, 0.0, 0.78, 0.55)
	add_child(trunk)
	var leaf_mat := Palette.surfaced("grass", Color("8aaa6a"), 0.0, 0.82, 0.7)
	var leaf := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 2.4
	sph.height = 3.6
	leaf.mesh = sph
	leaf.position = pos + Vector3(0, 5.1, 0)
	leaf.material_override = leaf_mat
	add_child(leaf)
	var leaf2 := leaf.duplicate() as MeshInstance3D
	leaf2.scale = Vector3(0.78, 0.72, 0.78)
	leaf2.position = pos + Vector3(1.1, 5.6, -0.4)
	add_child(leaf2)
	var leaf3 := leaf.duplicate() as MeshInstance3D
	leaf3.scale = Vector3(0.62, 0.58, 0.64)
	leaf3.position = pos + Vector3(-0.9, 5.8, 0.5)
	add_child(leaf3)


func _crate(pos: Vector3) -> void:
	_mesh_box(pos, Vector3(1.1, 0.9, 1.1), Palette.surfaced("wood", Color.WHITE, 0.0, 0.7, 0.7))


func _pier() -> void:
	var z := st_zs[0] - 16.0
	_static_box(Vector3(0, 0.22, z), Vector3(28, 0.4, 10), Palette.surfaced("wood", Color.WHITE, 0.0, 0.7, 0.2))
	for x in [-8.0, -3.0, 3.0, 8.0]:
		_mesh_box(Vector3(x, -0.6, z - 4.0), Vector3(0.35, 1.8, 0.35), Palette.surfaced("wood", Color.WHITE, 0.0, 0.75, 0.8))


func _garage_zone() -> void:
	_garage = Area3D.new()
	_garage.position = garage_pos
	_garage.collision_layer = 0
	_garage.collision_mask = 4
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(9, 3.2, 9)
	col.shape = box
	col.position.y = 1.5
	_garage.add_child(col)
	add_child(_garage)
	var pad := Palette.mat(Color("1c1a10"), 0.15, 0.45, Palette.amber(), 1.4)
	neon_mats.append(pad)
	_mesh_box(garage_pos + Vector3(0, 0.08, 0), Vector3(8.4, 0.05, 8.4), pad)
	var chevron := Palette.mat(Palette.amber(), 0.1, 0.4, Palette.amber(), 2.2)
	neon_mats.append(chevron)
	_mesh_box(garage_pos + Vector3(0, 0.1, 0), Vector3(2.4, 0.04, 0.45), chevron)


func _civic_zones() -> void:
	_building(hospital_pos + Vector3(0, 0, -5.5), Vector3(20, 28, 16), "plaster")
	_building(station_pos + Vector3(0, 0, -5.5), Vector3(18, 24, 15), "concrete")
	_building(garage_pos + Vector3(0, 0, -7.0), Vector3(16, 14, 12), "warehouse")
	_building(spray_pos + Vector3(0, 0, -6.0), Vector3(14, 10, 12), "concrete")
	_spray = _pad_zone(spray_pos, Color("3aa0ff"), 9.0)
	_mesh_box(hospital_pos + Vector3(0, 0.08, 4.2), Vector3(7, 0.05, 7), Palette.mat(Color("144028"), 0.1, 0.5, Color("3dcc6a"), 1.2))
	_mesh_box(station_pos + Vector3(0, 0.08, 4.2), Vector3(7, 0.05, 7), Palette.mat(Color("1a2038"), 0.1, 0.5, Color("4a66ff"), 1.2))
	_neon_sign(hospital_pos + Vector3(0, 8.4, 3.2), "HOSP")
	_neon_sign(station_pos + Vector3(0, 8.4, 3.2), "UNIT")
	_neon_sign(spray_pos + Vector3(0, 6.2, 3.2), "SPRAY")
	_neon_sign(gun_shop_pos + Vector3(0, 5.2, 5.4), "ARMS")
	_neon_sign(bar_pos + Vector3(0, 5.0, 5.4), "BAR")


func _pad_zone(pos: Vector3, color: Color, size: float) -> Area3D:
	var area := Area3D.new()
	area.position = pos
	area.collision_layer = 0
	area.collision_mask = 4
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(size, 3.2, size)
	col.shape = box
	col.position.y = 1.5
	area.add_child(col)
	add_child(area)
	var pad := Palette.mat(Color("10141c"), 0.15, 0.45, color, 1.3)
	neon_mats.append(pad)
	_mesh_box(pos + Vector3(0, 0.08, 0), Vector3(size - 0.6, 0.05, size - 0.6), pad)
	return area


func _shops() -> void:
	_storefront(gun_shop_pos, Color("3a2418"), Color("c45a2a"), 11.0, 8.5)
	_mesh_box(gun_shop_pos + Vector3(0, 1.05, -1.4), Vector3(4.6, 1.05, 0.7), Palette.surfaced("wood", Color.WHITE, 0.0, 0.6, 0.5))
	_mesh_box(gun_shop_pos + Vector3(-1.6, 1.15, -1.05), Vector3(0.7, 0.18, 1.4), Palette.mat(Color("2a2e28"), 0.55, 0.32))
	_mesh_box(gun_shop_pos + Vector3(1.5, 1.15, -1.05), Vector3(0.85, 0.16, 1.6), Palette.mat(Color("1a1c18"), 0.5, 0.28))
	_storefront(bar_pos, Color("2a1814"), Color("f0a030"), 10.0, 8.0)
	_mesh_box(bar_pos + Vector3(0, 1.05, -1.1), Vector3(5.4, 1.1, 0.85), Palette.surfaced("wood", Color.WHITE, 0.0, 0.58, 0.45))
	_mesh_box(bar_pos + Vector3(-1.8, 1.55, 0.6), Vector3(0.55, 0.95, 0.55), Palette.surfaced("wood", Color.WHITE, 0.0, 0.65, 0.8))
	_mesh_box(bar_pos + Vector3(1.6, 1.55, 0.8), Vector3(0.55, 0.95, 0.55), Palette.surfaced("wood", Color.WHITE, 0.0, 0.65, 0.8))


func _storefront(pos: Vector3, wall: Color, neon: Color, w: float, d: float) -> void:
	var plaster := Palette.surfaced("plaster", Color.WHITE, 0.02, 0.7, 0.2)
	var floor := Palette.surfaced("wood", Color.WHITE, 0.0, 0.72, 0.28)
	_static_box(pos + Vector3(0, 0.04, 0), Vector3(w, 0.08, d), floor)
	_static_box(pos + Vector3(0, 2.1, -d * 0.5 + 0.12), Vector3(w, 4.2, 0.24), plaster)
	_static_box(pos + Vector3(-w * 0.5 + 0.12, 2.1, 0), Vector3(0.24, 4.2, d), plaster)
	_static_box(pos + Vector3(w * 0.5 - 0.12, 2.1, 0), Vector3(0.24, 4.2, d), plaster)
	_mesh_box(pos + Vector3(0, 4.25, 0), Vector3(w + 0.3, 0.18, d + 0.3), Palette.surfaced("roof", Color.WHITE, 0.04, 0.65, 0.2))
	var trim := Palette.mat(wall, 0.08, 0.5)
	_mesh_box(pos + Vector3(0, 3.55, d * 0.5 - 0.08), Vector3(w * 0.92, 0.35, 0.16), trim)
	var glow := Palette.mat(neon, 0.1, 0.3, neon, 2.6)
	neon_mats.append(glow)
	_mesh_box(pos + Vector3(0, 3.55, d * 0.5 + 0.02), Vector3(w * 0.7, 0.18, 0.08), glow)


func _army_base() -> void:
	var pad := Palette.surfaced("concrete", Color("c8ccc4"), 0.04, 0.7, 0.08)
	_static_box(base_pos + Vector3(0, 0.0, 0), Vector3(78, 0.4, 62), pad)
	var fence := Palette.surfaced("metal", Color("9aa090"), 0.45, 0.4, 0.7)
	for x in [-38.0, 38.0]:
		_static_box(base_pos + Vector3(x, 1.4, 0), Vector3(0.16, 2.8, 62), fence)
	_static_box(base_pos + Vector3(0, 1.4, 30.5), Vector3(76, 2.8, 0.16), fence)
	# City-side posts only. The gap covers both nearby avenues so you can drive straight in.
	_static_box(base_pos + Vector3(-34, 1.6, -30.5), Vector3(8, 3.2, 0.28), fence)
	_static_box(base_pos + Vector3(34, 1.6, -30.5), Vector3(8, 3.2, 0.28), fence)
	_static_box(base_pos + Vector3(-30, 3.6, -30.5), Vector3(0.45, 7.2, 0.45), fence)
	_static_box(base_pos + Vector3(30, 3.6, -30.5), Vector3(0.45, 7.2, 0.45), fence)
	_mesh_box(base_pos + Vector3(0, 7.1, -30.5), Vector3(61, 0.35, 0.55), Palette.surfaced("metal", Color.WHITE, 0.4, 0.35, 0.5))
	var drive := Palette.surfaced("asphalt", Color.WHITE, 0.0, 0.78, 0.07)
	road_mats.append(drive)
	_mesh_box(base_pos + Vector3(0, 0.05, -42.0), Vector3(56, 0.08, 28), drive)
	var chevron := Palette.mat(Color("e8c84a"), 0.08, 0.38)
	_mesh_box(base_pos + Vector3(0, 0.1, -32.0), Vector3(22, 0.04, 1.1), chevron)
	_mesh_box(base_pos + Vector3(0, 0.1, -36.0), Vector3(18, 0.04, 1.1), chevron)
	var hangar := Palette.surfaced("warehouse", Color.WHITE, 0.2, 0.45, 0.18)
	_static_box(base_pos + Vector3(-28, 3.4, 18), Vector3(0.3, 6.8, 16), hangar)
	_static_box(base_pos + Vector3(-20, 3.4, 26), Vector3(16, 6.8, 0.3), hangar)
	_static_box(base_pos + Vector3(-20, 3.4, 10), Vector3(16, 6.8, 0.3), hangar)
	_mesh_box(base_pos + Vector3(-20, 7.0, 18), Vector3(17, 0.3, 17), Palette.surfaced("metal", Color.WHITE, 0.4, 0.4, 0.25))
	_static_box(base_pos + Vector3(28, 2.4, 18), Vector3(12, 4.8, 10), Palette.surfaced("concrete", Color.WHITE, 0.05, 0.62, 0.16))
	_mesh_box(base_pos + Vector3(0, 0.07, 0), Vector3(12, 0.04, 44), Palette.mat(Color("3a3c34"), 0.05, 0.55))
	_neon_sign(base_pos + Vector3(0, 8.4, -30.7), "BASE")
	var face := Palette.mat(Palette.amber(), 0.1, 0.25, Palette.amber(), 4.0)
	neon_mats.append(face)
	_mesh_box(base_pos + Vector3(0, 8.4, -31.0), Vector3(6.4, 0.72, 0.08), face)
	var tower := Palette.surfaced("concrete", Color.WHITE, 0.05, 0.6, 0.3)
	_static_box(base_pos + Vector3(30, 4.2, 8), Vector3(3.2, 8.4, 3.2), tower)
	_mesh_box(base_pos + Vector3(30, 8.6, 8), Vector3(4.2, 0.25, 4.2), Palette.surfaced("metal", Color.WHITE, 0.4, 0.35, 0.6))
	aircraft_spawns = [
		{"pos": base_pos + Vector3(-4.5, 0.7, 2.0), "yaw": 0.0},
		{"pos": base_pos + Vector3(4.5, 0.7, 8.0), "yaw": 0.0},
	]
	military_spawns = [
		{"pos": base_pos + Vector3(18, 0.4, -18), "yaw": PI},
		{"pos": base_pos + Vector3(22, 0.4, -12), "yaw": PI * 0.5},
	]
	crate_spawns = [
		base_pos + Vector3(-18, 0.2, 16),
		base_pos + Vector3(-14, 0.2, 18),
		base_pos + Vector3(16, 0.2, 6),
	]
	for c in crate_spawns:
		_crate(c + Vector3(0, 0.25, 0))
		_mesh_box(c + Vector3(0, 0.85, 0), Vector3(0.7, 0.12, 0.35), Palette.mat(Color("2a4a28"), 0.2, 0.4, Color("6dff88"), 1.6))
	var liner := Models.instance_airliner()
	liner.position = base_pos + Vector3(8, 0, 48)
	liner.rotation.y = PI * 0.5
	add_child(liner)


func _markers() -> void:
	patrol.clear()
	for zi in [0, 3, 7, 11, ST_N - 1]:
		for xi in [0, 3, 5, 8, AVE_N - 1]:
			patrol.append(Vector3(ave_xs[xi], 0.15, st_zs[zi]))
	cop_spawns = [
		Vector3(ave_xs[9], 0.15, st_zs[8]),
		Vector3(ave_xs[1], 0.15, st_zs[3]),
		Vector3(ave_xs[5], 0.15, st_zs[12]),
		Vector3(ave_xs[7], 0.15, st_zs[1]),
	]
	parked_spawns.clear()
	for xi in AVE_N:
		for zi in ST_N:
			if (xi * 7 + zi * 3) % 5 != 0:
				continue
			if xi == 6 and zi == 8:
				continue
			var along_ave := (xi + zi) % 2 == 0
			var yaw := 0.0 if along_ave else PI * 0.5
			if (xi + zi) % 4 >= 2:
				yaw += PI
			var pos := Vector3(
				ave_xs[xi] + (5.2 if not along_ave else 0.0),
				0.35,
				st_zs[zi] + (5.2 if along_ave else 0.0)
			)
			parked_spawns.append({"pos": pos, "yaw": yaw})
	parked_spawns.append({"pos": Vector3(ave_xs[5] + 5.1, 0.35, st_zs[8]), "yaw": 0.0})
	parked_spawns.append({"pos": Vector3(ave_xs[6] + 5.1, 0.35, st_zs[8]), "yaw": PI})
	traffic_spawns.clear()
	for xi in AVE_N:
		for zi in ST_N:
			if (xi * 3 + zi * 5) % 4 != 0:
				continue
			var yaw := PI * 0.5 if (xi + zi) % 2 == 0 else 0.0
			var off := 7.2 if (xi + zi) % 4 < 2 else -7.2
			var pos := Vector3(ave_xs[xi], 0.35, st_zs[zi])
			if absf(yaw) < 0.2 or absf(absf(yaw) - PI) < 0.2:
				pos.z += off
			else:
				pos.x += off
			traffic_spawns.append({"pos": pos, "yaw": yaw})
	sidewalk_paths.clear()
	for j in [1, 3, 5, 7, 8, 10, 12, 13]:
		var z := st_zs[j] + 7.6
		sidewalk_paths.append([
			Vector3(ave_xs[1] + 14.0, 0.15, z),
			Vector3(ave_xs[AVE_N - 2] - 14.0, 0.15, z),
		])
	for i in [1, 2, 4, 5, 7, 8, 9]:
		var x := ave_xs[i] + 7.6
		sidewalk_paths.append([
			Vector3(x, 0.15, st_zs[2] + 12.0),
			Vector3(x, 0.15, st_zs[ST_N - 3] - 12.0),
		])
	package_spawns = [
		Vector3(0, 0.2, st_zs[0] - 14.0),
		Vector3(ave_xs[9], 0.2, st_zs[13]),
		Vector3(ave_xs[1], 0.2, st_zs[4]),
	]
	health_spawns = [hospital_pos + Vector3(2.5, 0.2, 0)]


func _dashes(origin: Vector3, axis: Vector3, length: float, material: Material) -> void:
	var step := 5.2
	var n := int(length / step)
	for i in n:
		var t := (float(i) + 0.15) * step
		_mesh_box(origin + axis * t, Vector3(0.14, 0.02, 0.14) + axis * 1.7, material)


func _h01(a: int, b: int, salt: int) -> float:
	var n := sin(float(a * 12.9898 + b * 78.233 + salt * 37.719) * 43758.5453)
	return n - floorf(n)


func _static_box(pos: Vector3, size: Vector3, material: Material) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	body.collision_layer = 1
	body.collision_mask = 0
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = material
	body.add_child(mesh)
	add_child(body)


func _mesh_box(pos: Vector3, size: Vector3, material: Material) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.position = pos
	mesh.material_override = material
	add_child(mesh)
