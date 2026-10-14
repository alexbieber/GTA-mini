shader_type spatial;
render_mode specular_schlick_ggx;
// Remap the licensed palette on the original generic model, never a ripped skin.
uniform sampler2D palette_texture : source_color;
uniform vec4 skin_color : source_color = vec4(0.22, 0.105, 0.055, 1.0);
uniform vec4 denim_color : source_color = vec4(0.075, 0.16, 0.29, 1.0);
uniform vec4 shirt_color : source_color = vec4(0.88, 0.88, 0.84, 1.0);
uniform float mesh_height = 1.0;
varying float arm_region;

void vertex() {
	arm_region = smoothstep(0.17, 0.23, abs(VERTEX.x) / max(mesh_height, 0.001));
}

void fragment() {
	vec3 original = texture(palette_texture, UV).rgb;
	vec3 color = original;
	if (original.r > 0.65 && original.g > 0.45 && original.b < 0.8) {
		color = skin_color.rgb;
	} else if (original.b > original.r + 0.08 && original.g > 0.35) {
		color = mix(shirt_color.rgb, skin_color.rgb, arm_region);
	} else if (original.b > original.r + 0.08) {
		color = denim_color.rgb;
	} else if (original.r > original.b + 0.1 && original.g < 0.5) {
		color = vec3(0.025, 0.02, 0.018);
	}
	ALBEDO = color;
	ROUGHNESS = 0.8;
}
