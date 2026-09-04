class_name Palette
extends Object

const PBR_SETS := {
	"asphalt": "res://assets/pbr/asphalt_01/asphalt_01",
	"road": "res://assets/pbr/asphalt_01/asphalt_01",
	"sidewalk": "res://assets/pbr/concrete_pavement/concrete_pavement",
	"brick": "res://assets/pbr/red_brick/red_brick",
	"brick_dark": "res://assets/pbr/red_brick_03/red_brick_03",
	"concrete": "res://assets/pbr/cracked_concrete_wall/cracked_concrete_wall",
	"warehouse": "res://assets/pbr/metal_plate/metal_plate",
	"office": "res://assets/pbr/cracked_concrete_wall/cracked_concrete_wall",
	"plaster": "res://assets/pbr/painted_plaster_wall/painted_plaster_wall",
	"roof": "res://assets/pbr/roof_09/roof_09",
	"wood": "res://assets/pbr/wood_floor_deck/wood_floor_deck",
	"grass": "res://assets/pbr/aerial_grass_rock/aerial_grass_rock",
	"metal": "res://assets/pbr/green_metal_rust/green_metal_rust",
	"bitumen": "res://assets/pbr/bitumen/bitumen",
	"beige": "res://assets/pbr/beige_wall_001/beige_wall_001",
}

static var _tex_cache: Dictionary = {}


static func tex(path: String) -> Texture2D:
	if _tex_cache.has(path):
		return _tex_cache[path]
	var t: Texture2D = null
	if ResourceLoader.exists(path):
		t = load(path) as Texture2D
	if t == null:
		var abs_path := ProjectSettings.globalize_path(path)
		if FileAccess.file_exists(abs_path):
			var img := Image.load_from_file(abs_path)
			if img:
				t = ImageTexture.create_from_image(img)
	_tex_cache[path] = t
	return t


static func mat(color: Color, metallic := 0.0, roughness := 0.82, emission := Color.BLACK, energy := 2.2) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = roughness
	m.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	if emission != Color.BLACK:
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = energy
	return m


static func surfaced(tex_id: String, tint := Color.WHITE, metallic := 0.0, roughness := 0.72, tile := 0.22) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	var stem: String = PBR_SETS.get(tex_id, "")
	if stem != "":
		var diff := tex(stem + "_diff_1k.jpg")
		if diff:
			m.albedo_texture = diff
			m.normal_enabled = true
			m.normal_texture = tex(stem + "_nor_1k.jpg")
			m.normal_scale = 1.15
			m.roughness_texture = tex(stem + "_rough_1k.jpg")
		else:
			m.albedo_texture = ProcTex.get_tex(tex_id)
	else:
		m.albedo_texture = ProcTex.get_tex(tex_id)
	m.albedo_color = tint
	m.metallic = metallic
	m.roughness = roughness
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_triplanar_sharpness = 6.0
	m.uv1_scale = Vector3(tile, tile, tile)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	m.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	return m


static func facade(style: String) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	var path := "res://assets/pbr/facades/" + style
	var diff := tex(path + "_diff.png")
	if diff:
		m.albedo_texture = diff
		m.normal_enabled = true
		m.normal_texture = tex(path + "_nor.png")
		m.normal_scale = 0.85
		m.roughness_texture = tex(path + "_rough.png")
		m.emission_enabled = true
		m.emission = Color("f0c878")
		m.emission_texture = tex(path + "_emit.png")
		m.emission_energy_multiplier = 0.0
	else:
		return surfaced(style, Color.WHITE, 0.02, 0.68, 0.12)
	m.albedo_color = Color.WHITE
	m.metallic = 0.12 if style == "office" else 0.03
	m.roughness = 0.55
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_triplanar_sharpness = 10.0
	m.uv1_scale = Vector3(0.032, 0.032, 0.032)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return m


static func paint(color: Color, metallic := 0.72, roughness := 0.28) -> StandardMaterial3D:
	var m := mat(color, metallic, roughness)
	m.clearcoat_enabled = true
	m.clearcoat = 0.55
	m.clearcoat_roughness = 0.12
	return m


static func glass(color: Color, night_glow := Color.BLACK) -> StandardMaterial3D:
	var m := mat(color, 0.85, 0.06)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color.a = 0.72
	if night_glow != Color.BLACK:
		m.emission_enabled = true
		m.emission = night_glow
		m.emission_energy_multiplier = 0.0
	return m


static func amber() -> Color:
	return Color("f0a030")


static func courier() -> Color:
	return Color("2d6a4f")


static func cop_navy() -> Color:
	return Color("152238")
