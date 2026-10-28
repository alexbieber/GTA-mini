shader_type spatial;
render_mode specular_schlick_ggx;
// Remap the licensed palette on the original generic model, never a ripped skin.
uniform sampler2D palette_texture : source_color;
uniform vec4 skin_color : source_color = vec4(0.22, 0.105, 0.055, 1.0);
uniform vec4 denim_color : source_color = vec4(0.075, 0.16, 0.29, 1.0);
uniform vec4 shirt_color : source_color = vec4(0.88, 0.88, 0.84, 1.0);
uniform float mesh_height = 1.0;
uniform vec3 character_origin = vec3(0.0);
uniform vec3 character_right = vec3(1.0, 0.0, 0.0);
uniform float character_height = 1.55;
varying float arm_region;
varying float body_level;

void vertex() {
	vec3 relative = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz - character_origin;
	body_level = relative.y / max(character_height, 0.01);
	arm_region = smoothstep(0.055, 0.085, abs(dot(relative, character_right)) / max(character_height, 0.01));
}

void fragment() {
	vec3 color = skin_color.rgb;
	if (body_level < 0.08) color = vec3(0.025, 0.025, 0.025);
	else if (body_level < 0.49) color = mix(denim_color.rgb, skin_color.rgb, arm_region);
	else if (body_level < 0.79) color = mix(shirt_color.rgb, skin_color.rgb, arm_region);
	else if (body_level > 0.94) color = vec3(0.025, 0.02, 0.018);
	ALBEDO = color;
	ROUGHNESS = 0.8;
}
