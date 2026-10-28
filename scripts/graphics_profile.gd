class_name GraphicsProfile
extends RefCounted
## Low defaults avoid realtime GI and screen-space effects on older GPUs.
enum Quality { LOW, MEDIUM, HIGH }

static func apply(environment: Environment, sun: DirectionalLight3D, quality: int) -> void:
	var advanced := RenderingServer.get_current_rendering_method() == "forward_plus"
	environment.ssao_enabled = advanced and quality >= Quality.MEDIUM
	environment.ssil_enabled = advanced and quality == Quality.HIGH
	environment.ssr_enabled = advanced and quality == Quality.HIGH
	environment.sdfgi_enabled = advanced and quality == Quality.HIGH
	environment.glow_enabled = advanced and quality >= Quality.MEDIUM
	sun.shadow_enabled = quality >= Quality.MEDIUM
	sun.directional_shadow_max_distance = 120.0 if quality == Quality.MEDIUM else 420.0

static func label(quality: int) -> String:
	return ["LOW", "MEDIUM", "HIGH"][clampi(quality, 0, 2)]
