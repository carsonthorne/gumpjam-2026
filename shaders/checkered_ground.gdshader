shader_type spatial;

uniform vec4 light_tile : source_color = vec4(0.78, 0.78, 0.70, 1.0);
uniform vec4 dark_tile : source_color = vec4(0.42, 0.43, 0.38, 1.0);
uniform float tile_size = 0.75;

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 tile = floor((world_position.xz + vec2(tile_size * 0.5)) / tile_size);
	float checker = mod(tile.x + tile.y, 2.0);
	ALBEDO = mix(light_tile.rgb, dark_tile.rgb, checker);
	ROUGHNESS = 0.85;
}
