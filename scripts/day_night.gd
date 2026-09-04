class_name DayNight
extends Node

signal changed(night: bool)

var is_night := true
var city: City

var _world: WorldEnvironment
var _env: Environment
var _pano: PanoramaSkyMaterial
var _sun: DirectionalLight3D
var _fill: DirectionalLight3D
var _day_hdri: Texture2D
var _night_hdri: Texture2D


func _ready() -> void:
	add_to_group("day_night")
	_day_hdri = Palette.tex("res://assets/pbr/hdri/wide_street_01_2k.hdr")
	_night_hdri = Palette.tex("res://assets/pbr/hdri/shanghai_bund_2k.hdr")
	_world = WorldEnvironment.new()
	_env = Environment.new()
	_pano = PanoramaSkyMaterial.new()
	if _day_hdri:
		_pano.panorama = _day_hdri
	var sky := Sky.new()
	sky.sky_material = _pano
	sky.process_mode = Sky.PROCESS_MODE_REALTIME
	_env.background_mode = Environment.BG_SKY
	_env.sky = sky
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	_env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	_env.tonemap_mode = Environment.TONE_MAPPER_ACES
	_env.ssao_enabled = true
	_env.ssao_radius = 1.6
	_env.ssao_intensity = 2.4
	_env.ssil_enabled = true
	_env.ssil_intensity = 0.75
	_env.ssr_enabled = true
	_env.ssr_max_steps = 64
	_env.ssr_fade_in = 0.08
	_env.sdfgi_enabled = true
	_env.sdfgi_use_occlusion = true
	_env.sdfgi_cascades = 4
	_env.sdfgi_min_cell_size = 0.35
	_env.glow_enabled = true
	_env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	_env.adjustment_enabled = true
	_env.fog_enabled = true
	_env.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	_world.environment = _env
	add_child(_world)

	_sun = DirectionalLight3D.new()
	_sun.shadow_enabled = true
	_sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	_sun.directional_shadow_max_distance = 420.0
	_sun.light_angular_distance = 0.35
	_sun.shadow_blur = 0.8
	_sun.shadow_bias = 0.04
	add_child(_sun)

	_fill = DirectionalLight3D.new()
	_fill.shadow_enabled = false
	_fill.light_energy = 0.12
	add_child(_fill)


func bind(p_city: City) -> void:
	city = p_city
	apply(is_night)


func toggle() -> void:
	apply(not is_night)


func apply(night: bool) -> void:
	is_night = night
	if night:
		_apply_night()
	else:
		_apply_day()
	if city:
		city.apply_time(night)
		city.refresh_reflections()
	get_tree().call_group("time_sensitive", "apply_time", night)
	changed.emit(night)


func _apply_night() -> void:
	if _night_hdri:
		_pano.panorama = _night_hdri
	_pano.energy_multiplier = 0.62
	_sun.light_color = Color("9aa8c8")
	_sun.light_energy = 0.28
	_sun.rotation_degrees = Vector3(-28, 150, 0)
	_sun.shadow_opacity = 0.7
	_fill.light_color = Color("2a3a6a")
	_fill.light_energy = 0.1
	_fill.rotation_degrees = Vector3(-18, -40, 0)
	_env.ambient_light_energy = 0.55
	_env.fog_light_color = Color("10141c")
	_env.fog_density = 0.0019
	_env.fog_aerial_perspective = 0.55
	_env.fog_sky_affect = 0.28
	_env.glow_intensity = 0.58
	_env.glow_bloom = 0.08
	_env.glow_hdr_threshold = 0.7
	_env.adjustment_brightness = 0.96
	_env.adjustment_contrast = 1.12
	_env.adjustment_saturation = 0.88
	_env.tonemap_exposure = 0.84
	_env.ssao_intensity = 2.2
	_env.ssr_depth_tolerance = 0.2
	_env.sdfgi_energy = 0.62


func _apply_day() -> void:
	if _day_hdri:
		_pano.panorama = _day_hdri
	_pano.energy_multiplier = 1.15
	_sun.light_color = Color("fff1d2")
	_sun.light_energy = 1.25
	_sun.rotation_degrees = Vector3(-46, -32, 0)
	_sun.shadow_opacity = 1.0
	_fill.light_color = Color("a8c4dc")
	_fill.light_energy = 0.14
	_fill.rotation_degrees = Vector3(-16, 140, 0)
	_env.ambient_light_energy = 0.38
	_env.fog_light_color = Color("c4d4e2")
	_env.fog_density = 0.0011
	_env.fog_aerial_perspective = 0.32
	_env.fog_sky_affect = 0.16
	_env.glow_intensity = 0.28
	_env.glow_bloom = 0.03
	_env.glow_hdr_threshold = 1.05
	_env.adjustment_brightness = 1.02
	_env.adjustment_contrast = 1.1
	_env.adjustment_saturation = 1.06
	_env.tonemap_exposure = 0.94
	_env.ssao_intensity = 2.6
	_env.sdfgi_energy = 1.0
