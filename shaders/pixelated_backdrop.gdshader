shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D backdrop_texture : source_color, filter_nearest, repeat_disable;
uniform float pixel_block_size : hint_range(1.0, 16.0, 1.0) = 6.0;

void fragment() {
	vec2 texture_size = vec2(textureSize(backdrop_texture, 0));
	vec2 pixel_grid = max(texture_size / pixel_block_size, vec2(1.0));
	vec2 pixelated_uv = (floor(UV * pixel_grid) + vec2(0.5)) / pixel_grid;
	vec3 backdrop_color = texture(backdrop_texture, pixelated_uv).rgb;

	ALBEDO = backdrop_color;
}
