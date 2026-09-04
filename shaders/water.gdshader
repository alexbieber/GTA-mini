shader_type spatial;
render_mode specular_schlick_ggx, cull_back;

uniform vec4 deep_color : source_color = vec4(0.04, 0.12, 0.18, 1.0);
uniform vec4 shallow_color : source_color = vec4(0.18, 0.42, 0.48, 1.0);
uniform float roughness_val = 0.08;
uniform float metallic_val = 0.55;
uniform float glow = 0.15;

void fragment() {
	vec2 uv1 = UV * 7.0 + vec2(TIME * 0.03, TIME * 0.02);
	vec2 uv2 = UV * 11.0 - vec2(TIME * 0.025, TIME * 0.04);
	float w = sin(uv1.x + uv1.y) * 0.5 + sin(uv2.x * 1.3 - uv2.y) * 0.5;
	float foam = smoothstep(0.72, 1.0, w);
	ALBEDO = mix(deep_color.rgb, shallow_color.rgb, w * 0.5 + 0.5);
	ALBEDO = mix(ALBEDO, vec3(0.85, 0.9, 0.92), foam * 0.25);
	ROUGHNESS = roughness_val + foam * 0.15;
	METALLIC = metallic_val;
	EMISSION = ALBEDO * glow;
	NORMAL = normalize(NORMAL + vec3(w * 0.08, 0.0, (1.0 - w) * 0.08));
}
