class_name GameModels
## Kenney CC0 + Quaternius CC0 + OpenGameArt CC0. Collision stays on gameplay nodes.

const PERSON := "res://assets/people/characterMedium.fbx"
const IDLE := "res://assets/people/idle.fbx"
const RUN := "res://assets/people/run.fbx"
const COLORMAP := "res://assets/cars/Textures/colormap.png"
const REAL_MAN := "res://assets/people/real/man.fbx"
const REAL_WOMAN := "res://assets/people/real/woman.fbx"
const AN2 := "res://assets/aircraft/an2.fbx"
const AN2_TEX := "res://assets/aircraft/An2Tex.png"
const AN2_CIV := "res://assets/aircraft/An2_aeroflot.png"
const AIRLINER := "res://assets/aircraft/jetliner.obj"

const CAR_SCALE := 1.58
const PERSON_SCALE := 0.62
const CAR_LENGTH := 4.35
const PERSON_HEIGHT := 1.55
const PLANE_SPAN := 13.6
const AIRLINER_SPAN := 36.0

const CIV_CARS := [
	["res://assets/cars/real/NormalCar1.fbx", "CIVIC"],
	["res://assets/cars/real/NormalCar2.fbx", "CRUISER"],
	["res://assets/cars/real/Taxi.fbx", "TAXI"],
	["res://assets/cars/real/SUV.fbx", "SUV"],
	["res://assets/cars/sedan.glb", "SEDAN"],
	["res://assets/cars/taxi.glb", "CAB"],
	["res://assets/cars/van.glb", "VAN"],
	["res://assets/cars/suv.glb", "WAGON"],
	["res://assets/cars/hatchback-sports.glb", "HATCH"],
	["res://assets/cars/suv-luxury.glb", "LUX SUV"],
	["res://assets/cars/delivery.glb", "DELIVERY"],
	["res://assets/cars/truck.glb", "HAULER"],
]

const PARKED_CARS := [
	["res://assets/cars/real/NormalCar1.fbx", "CIVIC"],
	["res://assets/cars/real/SportsCar2.fbx", "ROADSTER"],
	["res://assets/cars/real/SUV.fbx", "SUV"],
	["res://assets/cars/sedan.glb", "SEDAN"],
	["res://assets/cars/suv.glb", "SUV"],
	["res://assets/cars/hatchback-sports.glb", "HATCH"],
	["res://assets/cars/ambulance.glb", "AMBULANCE"],
	["res://assets/cars/firetruck.glb", "LADDER"],
	["res://assets/cars/garbage-truck.glb", "SANITATION"],
	["res://assets/cars/race.glb", "RACE"],
]


static func car_for(kind: int) -> Dictionary:
	match kind:
		0:
			return {"path": "res://assets/cars/real/SportsCar.fbx", "name": "AMBER COUPE"}
		1:
			return {"path": "res://assets/cars/real/Cop.fbx", "name": "UNIT"}
		2:
			var row: Array = PARKED_CARS[randi() % PARKED_CARS.size()]
			return {"path": row[0], "name": row[1]}
		4:
			return {"path": "res://assets/cars/real/SUV.fbx", "name": "PATROL JEEP"}
		_:
			var row2: Array = CIV_CARS[randi() % CIV_CARS.size()]
			return {"path": row2[0], "name": row2[1]}


static func instance_car(path: String) -> Node3D:
	var vis := _load_visual(path, "CarVisual")
	_strip_physics(vis)
	vis.rotation.y = PI
	if path.contains("/real/"):
		_fit_xz(vis, CAR_LENGTH)
		_polish_real_car(vis)
	else:
		vis.scale = Vector3.ONE * CAR_SCALE
		_paint_car(vis)
	return vis


static func instance_plane(civilian := false) -> Node3D:
	var vis := _load_visual(AN2, "PlaneVisual")
	_strip_physics(vis)
	vis.rotation.y = PI
	_fit_xz(vis, PLANE_SPAN)
	_paint_tex(vis, AN2_CIV if civilian else AN2_TEX)
	return vis


static func instance_airliner() -> Node3D:
	var wrap := Node3D.new()
	wrap.name = "Airliner"
	var mesh := load(AIRLINER) as Mesh
	if mesh:
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		wrap.add_child(mi)
	_fit_xz(wrap, AIRLINER_SPAN)
	_polish_metal(wrap, Color("c8d0d6"))
	return wrap


static func tint_car(root: Node, color: Color) -> void:
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi.name.to_lower().contains("wheel"):
			continue
		var mat := mi.material_override as StandardMaterial3D
		if mat == null:
			if mi.get_active_material(0) is StandardMaterial3D:
				mat = (mi.get_active_material(0) as StandardMaterial3D).duplicate()
			else:
				mat = StandardMaterial3D.new()
		else:
			mat = mat.duplicate() as StandardMaterial3D
		mat.albedo_color = color
		mat.metallic = 0.86
		mat.roughness = 0.16
		mat.clearcoat_enabled = true
		mat.clearcoat = 1.0
		mat.clearcoat_roughness = 0.05
		mi.material_override = mat


static func car_wheels(root: Node) -> Array[Node3D]:
	var out: Array[Node3D] = []
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var key := node.name.to_lower()
		if key.contains("wheel-front") or key.contains("wheel-back-left") or key.contains("wheel-back-right"):
			out.append(node)
	return out


static func instance_person(skin_path: String) -> Dictionary:
	if not skin_path.begins_with("res://"):
		skin_path = civilian_skin()
	return _instance_kenney_person(skin_path)


static func play_move(ap: AnimationPlayer, moving: bool, fast := false) -> void:
	if ap == null:
		return
	var idle := _best_anim(ap, ["idle", "stand"])
	var run := _best_anim(ap, ["run", "sprint"])
	var walk := _best_anim(ap, ["walk", "jog"])
	var want := idle
	if moving:
		want = run if (fast or walk.is_empty()) else walk
		if want.is_empty():
			want = run if not run.is_empty() else walk
	if want.is_empty():
		return
	if ap.current_animation != want:
		ap.play(want)
	ap.speed_scale = (1.35 if fast else 1.0) if moving else 1.0


static func player_skin() -> String:
	return "res://assets/people/humanMaleA.png"


static func officer_skin() -> String:
	return "res://assets/people/officer.png"


static func civilian_skin() -> String:
	var skins := [
		"res://assets/people/humanMaleA.png",
		"res://assets/people/humanFemaleA.png",
		"res://assets/people/survivorMaleB.png",
		"res://assets/people/survivorFemaleA.png",
		"res://assets/people/criminalMaleA.png",
		"res://assets/people/skaterMaleA.png",
		"res://assets/people/skaterFemaleA.png",
	]
	return skins[randi() % skins.size()]


static func _instance_real_person(path: String) -> Dictionary:
	var wrap := Node3D.new()
	wrap.name = "PersonVisual"
	wrap.rotation.y = PI
	var vis := _load_visual(path, "Body")
	_strip_physics(vis)
	_polish_skin(vis)
	wrap.add_child(vis)
	var ap := vis.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if ap:
		for n in ap.get_animation_list():
			var anim := ap.get_animation(n)
			if anim:
				anim.loop_mode = Animation.LOOP_LINEAR
		var idle := _best_anim(ap, ["idle", "stand"])
		if not idle.is_empty():
			ap.autoplay = idle
			ap.play(idle)
	wrap.set_script(preload("res://scripts/person_fit.gd"))
	return {"root": wrap, "anim": ap}


static func normalize_person(wrap: Node3D) -> void:
	if not wrap.is_inside_tree():
		return
	var box := _world_aabb(wrap)
	if box.size.y < 0.04:
		return
	var s := PERSON_HEIGHT / box.size.y
	if absf(s - 1.0) < 0.04:
		_plant(wrap)
		return
	wrap.scale *= clampf(s, 0.001, 90.0)
	_plant(wrap)


static func _plant(wrap: Node3D) -> void:
	var box := _world_aabb(wrap)
	var parent := wrap.get_parent() as Node3D
	if parent == null:
		return
	wrap.global_position.y += parent.global_position.y - box.position.y


static func _world_aabb(root: Node) -> AABB:
	var acc := AABB()
	var started := false
	var nodes: Array = []
	if root is MeshInstance3D:
		nodes.append(root)
	nodes.append_array(root.find_children("*", "MeshInstance3D", true, false))
	for node in nodes:
		var mi := node as MeshInstance3D
		if mi == null or mi.mesh == null or not mi.is_inside_tree():
			continue
		var box := mi.global_transform * mi.get_aabb()
		if not started:
			acc = box
			started = true
		else:
			acc = acc.merge(box)
	return acc


static func _instance_kenney_person(skin_path: String) -> Dictionary:
	var wrap := Node3D.new()
	wrap.name = "PersonVisual"
	wrap.rotation.y = PI
	wrap.position.y = -0.12
	wrap.scale = Vector3.ONE * PERSON_SCALE
	var packed := load(PERSON) as PackedScene
	if packed == null:
		return {"root": wrap, "anim": null}
	var body := packed.instantiate() as Node3D
	_strip_physics(body)
	wrap.add_child(body)
	_paint_skin(body, skin_path)
	var ap := AnimationPlayer.new()
	ap.name = "Anim"
	body.add_child(ap)
	var lib := AnimationLibrary.new()
	var idle := _take_anim(IDLE, "Root|Idle")
	var run := _take_anim(RUN, "Root|Run")
	if idle:
		idle.loop_mode = Animation.LOOP_LINEAR
		lib.add_animation("idle", idle)
	if run:
		run.loop_mode = Animation.LOOP_LINEAR
		lib.add_animation("run", run)
	ap.add_animation_library("", lib)
	if idle:
		ap.play("idle")
	return {"root": wrap, "anim": ap}


static func _load_visual(path: String, node_name: String) -> Node3D:
	var packed := load(path) as PackedScene
	if packed == null:
		var empty := Node3D.new()
		empty.name = node_name
		return empty
	var vis := packed.instantiate() as Node3D
	if vis == null:
		vis = Node3D.new()
	vis.name = node_name
	return vis


static func _fit_xz(root: Node3D, target: float) -> void:
	var box := _aabb_of(root)
	var span := maxf(box.size.x, box.size.z)
	if span < 0.01:
		return
	var s := target / span
	root.scale = Vector3.ONE * s
	root.position.y = -box.position.y * s


static func _fit_height(root: Node3D, target: float) -> void:
	var box := _aabb_of(root)
	if box.size.y < 0.01:
		return
	var s := target / box.size.y
	root.scale = Vector3.ONE * s
	root.position.y = -box.position.y * s


static func _aabb_of(root: Node) -> AABB:
	var acc := AABB()
	var started := false
	var nodes: Array = []
	if root is MeshInstance3D:
		nodes.append(root)
	nodes.append_array(root.find_children("*", "MeshInstance3D", true, false))
	for node in nodes:
		var mi := node as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var xf := Transform3D.IDENTITY
		var walk: Node = mi
		var chain: Array[Node3D] = []
		while walk and walk != root:
			if walk is Node3D:
				chain.push_front(walk as Node3D)
			walk = walk.get_parent()
		for n in chain:
			xf = xf * n.transform
		var box := xf * mi.get_aabb()
		if not started:
			acc = box
			started = true
		else:
			acc = acc.merge(box)
	return acc


static func _best_anim(ap: AnimationPlayer, keys: Array) -> String:
	var names := ap.get_animation_list()
	for key in keys:
		var needle := str(key).to_lower()
		for n in names:
			if n.to_lower().contains(needle):
				return n
	return ""


static func _strip_physics(root: Node) -> void:
	for node in root.find_children("*", "CollisionObject3D", true, false):
		node.collision_layer = 0
		node.collision_mask = 0
	for node in root.find_children("*", "CollisionShape3D", true, false):
		node.disabled = true


static func _paint_car(root: Node) -> void:
	var tex := load(COLORMAP) as Texture2D
	if tex == null:
		return
	var shared: StandardMaterial3D
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		var src := mi.get_active_material(0)
		if shared == null:
			if src is StandardMaterial3D:
				shared = (src as StandardMaterial3D).duplicate()
			else:
				shared = StandardMaterial3D.new()
			shared.albedo_texture = tex
			shared.roughness = 0.12
			shared.metallic = 0.88
			shared.clearcoat_enabled = true
			shared.clearcoat = 1.0
			shared.clearcoat_roughness = 0.05
			shared.anisotropy_enabled = true
			shared.anisotropy = 0.22
			shared.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
		var key := mi.name.to_lower()
		if key.contains("wheel"):
			var rubber := StandardMaterial3D.new()
			rubber.albedo_color = Color("14161a")
			rubber.roughness = 0.72
			rubber.metallic = 0.12
			mi.material_override = rubber
		else:
			mi.material_override = shared
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON


static func _polish_real_car(root: Node) -> void:
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		var mat := StandardMaterial3D.new()
		var src := mi.get_active_material(0)
		if src is StandardMaterial3D:
			mat = (src as StandardMaterial3D).duplicate()
		mat.vertex_color_use_as_albedo = true
		mat.metallic = 0.72
		mat.roughness = 0.22
		mat.clearcoat_enabled = true
		mat.clearcoat = 0.85
		mat.clearcoat_roughness = 0.08
		mat.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON


static func _polish_metal(root: Node, color: Color) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.82
	mat.roughness = 0.28
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON


static func _polish_skin(root: Node) -> void:
	var tex := Palette.tex("res://assets/people/real/body.png")
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		var mat: StandardMaterial3D
		var src := mi.get_active_material(0)
		if src is StandardMaterial3D:
			mat = (src as StandardMaterial3D).duplicate()
		else:
			mat = StandardMaterial3D.new()
		mat.vertex_color_use_as_albedo = true
		if tex:
			mat.albedo_texture = tex
		mat.roughness = 0.55
		mat.metallic = 0.0
		mat.subsurf_scatter_enabled = true
		mat.subsurf_scatter_strength = 0.16
		mat.subsurf_scatter_skin_mode = true
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON


static func _paint_tex(root: Node, tex_path: String) -> void:
	var tex := load(tex_path) as Texture2D
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.roughness = 0.46
	mat.metallic = 0.18
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON


static func _paint_skin(root: Node, skin_path: String) -> void:
	var tex := load(skin_path) as Texture2D
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.roughness = 0.52
	mat.metallic = 0.0
	mat.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	mat.subsurf_scatter_enabled = true
	mat.subsurf_scatter_strength = 0.18
	mat.subsurf_scatter_skin_mode = true
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON


static func _take_anim(path: String, anim_name: String) -> Animation:
	var packed := load(path) as PackedScene
	if packed == null:
		return null
	var inst := packed.instantiate()
	var ap := inst.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if ap == null or not ap.has_animation(anim_name):
		inst.free()
		return null
	var anim := ap.get_animation(anim_name).duplicate() as Animation
	inst.free()
	return anim
