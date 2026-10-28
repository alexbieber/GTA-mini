class_name ArenaLighting
extends Node
var quality := GraphicsProfile.Quality.LOW
var is_night := false
var environment := Environment.new()
var sun := DirectionalLight3D.new()

func _ready() -> void:
	var world := WorldEnvironment.new()
	var sky := Sky.new()
	var material := ProceduralSkyMaterial.new()
	material.sky_top_color = Color("6799bc")
	material.sky_horizon_color = Color("dfd5bc")
	material.ground_horizon_color = Color("b1a390")
	material.ground_bottom_color = Color("353944")
	sky.sky_material = material
	world.environment = environment
	environment.sky = sky
	environment.background_mode = Environment.BG_SKY
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("aec7d9")
	environment.ambient_light_energy = 0.55
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	add_child(world)
	sun.rotation_degrees = Vector3(-50, -25, 0)
	sun.light_color = Color("fff0d5")
	sun.light_energy = 1.1
	add_child(sun)
	set_quality(quality)

func set_quality(value: int) -> void:
	quality = clampi(value, 0, 2)
	GraphicsProfile.apply(environment, sun, quality)
	sun.directional_shadow_max_distance = 80.0 if quality == 1 else 150.0
