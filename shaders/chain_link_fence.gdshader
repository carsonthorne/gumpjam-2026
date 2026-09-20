shader_type spatial;
render_mode blend_mix, cull_disabled, depth_prepass_alpha;

uniform vec4 wire_color : source_color = vec4(0.72, 0.78, 0.78, 0.72);
uniform float panel_width = 4.0;
uniform float panel_height = 2.65;
uniform float horizontal_spacing = 0.15;
uniform float horizontal_wire_width : hint_range(0.002, 0.05) = 0.008;
uniform float vertical_wire_width : hint_range(0.002, 0.05) = 0.01;
uniform float edge_softness : hint_range(0.001, 0.03) = 0.006;

varying vec3 local_position;

void vertex() {
	local_position = VERTEX;
}

void fragment() {
	vec2 panel_position = local_position.xy + vec2(panel_width, panel_height) * 0.5;
	float distance_to_horizontal = abs(fract((panel_position.y / horizontal_spacing) + 0.5) - 0.5) * horizontal_spacing;
	float left_internal_rod_x = panel_width / 3.0;
	float right_internal_rod_x = panel_width * 2.0 / 3.0;
	float distance_to_vertical = min(abs(panel_position.x - left_internal_rod_x), abs(panel_position.x - right_internal_rod_x));
	float horizontal_wire = 1.0 - smoothstep(horizontal_wire_width, horizontal_wire_width + edge_softness, distance_to_horizontal);
	float vertical_wire = 1.0 - smoothstep(vertical_wire_width, vertical_wire_width + edge_softness, distance_to_vertical);
	float wire_mask = max(horizontal_wire, vertical_wire * 0.7);

	ALBEDO = wire_color.rgb;
	ALPHA = wire_color.a * wire_mask;
	ROUGHNESS = 0.35;
	METALLIC = 0.25;
}
