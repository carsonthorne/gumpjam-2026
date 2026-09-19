shader_type spatial;
render_mode blend_mix, unshaded, cull_disabled, depth_prepass_alpha;

uniform vec4 beam_color : source_color = vec4(1.0, 0.05, 0.03, 1.0);
uniform float bottom_alpha : hint_range(0.0, 1.0) = 0.42;
uniform float top_alpha : hint_range(0.0, 1.0) = 0.0;
uniform float beam_height = 3.0;

varying float local_height;

void vertex() {
	local_height = clamp((VERTEX.y / beam_height) + 0.5, 0.0, 1.0);
}

void fragment() {
	ALBEDO = beam_color.rgb;
	ALPHA = mix(bottom_alpha, top_alpha, local_height);
	ROUGHNESS = 0.4;
}
