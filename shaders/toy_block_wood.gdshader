shader_type spatial;

uniform vec4 light_wood : source_color = vec4(0.86, 0.67, 0.43, 1.0);
uniform vec4 dark_wood : source_color = vec4(0.58, 0.36, 0.18, 1.0);
uniform vec4 border_color : source_color = vec4(0.78, 0.06, 0.04, 1.0);
uniform float grain_scale = 18.0;
uniform float grain_strength = 0.22;
uniform float border_thickness = 0.09;

void fragment() {
	float stripe = sin((UV.y + UV.x * 0.2) * grain_scale * 6.28318);
	float grain = smoothstep(0.15, 1.0, stripe * 0.5 + 0.5);
	vec3 color = mix(light_wood.rgb, dark_wood.rgb, grain * grain_strength);
	float edge_distance = min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y));
	color = mix(border_color.rgb, color, step(border_thickness, edge_distance));
	ALBEDO = color;
	ROUGHNESS = 0.82;
}
