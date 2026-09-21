shader_type spatial;

uniform vec4 panel_color : source_color = vec4(0.48, 0.54, 0.53, 1.0);
uniform vec4 panel_shadow : source_color = vec4(0.20, 0.24, 0.24, 1.0);
uniform vec4 trim_color : source_color = vec4(0.16, 0.18, 0.19, 1.0);
uniform vec4 highlight_color : source_color = vec4(0.78, 0.82, 0.78, 1.0);

void fragment() {
	vec2 uv = UV;
	vec3 color = panel_color.rgb;

	float border_distance = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
	float outer_trim = step(border_distance, 0.115);
	float inner_trim = step(abs(uv.x - 0.5), 0.035) + step(abs(uv.y - 0.5), 0.035);
	float corner_plate = step(uv.x, 0.22) * step(uv.y, 0.22);
	corner_plate += step(1.0 - uv.x, 0.22) * step(uv.y, 0.22);
	corner_plate += step(uv.x, 0.22) * step(1.0 - uv.y, 0.22);
	corner_plate += step(1.0 - uv.x, 0.22) * step(1.0 - uv.y, 0.22);

	float ribs = sin(uv.y * 86.0);
	float rib_light = smoothstep(0.42, 1.0, ribs * 0.5 + 0.5);
	float rib_dark = 1.0 - smoothstep(-1.0, -0.28, ribs);
	color = mix(panel_shadow.rgb, color, rib_light * 0.68);
	color = mix(color, panel_shadow.rgb, rib_dark * 0.18);

	float panel_mask = step(0.15, border_distance) * (1.0 - step(abs(uv.x - 0.5), 0.055)) * (1.0 - step(abs(uv.y - 0.5), 0.055));
	float grime = fract(sin(dot(floor(uv * 32.0), vec2(12.9898, 78.233))) * 43758.5453);
	color = mix(color, panel_shadow.rgb, panel_mask * step(0.86, grime) * 0.24);

	float trim_mask = clamp(outer_trim + inner_trim + corner_plate, 0.0, 1.0);
	color = mix(color, trim_color.rgb, trim_mask);

	float bevel_highlight = step(border_distance, 0.13) * step(0.105, border_distance);
	float center_highlight = step(abs(uv.x - 0.5), 0.055) * step(0.035, abs(uv.x - 0.5));
	center_highlight += step(abs(uv.y - 0.5), 0.055) * step(0.035, abs(uv.y - 0.5));
	color = mix(color, highlight_color.rgb, clamp(bevel_highlight + center_highlight, 0.0, 1.0) * 0.35);

	ALBEDO = color;
	METALLIC = 0.72;
	ROUGHNESS = 0.48;
}
