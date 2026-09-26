shader_type canvas_item;

uniform float pixel_block_size : hint_range(1.0, 16.0, 1.0) = 6.0;

void fragment() {
	vec2 texture_size = 1.0 / TEXTURE_PIXEL_SIZE;
	vec2 pixel_grid = max(texture_size / pixel_block_size, vec2(1.0));
	vec2 pixelated_uv = (floor(UV * pixel_grid) + vec2(0.5)) / pixel_grid;

	COLOR = texture(TEXTURE, pixelated_uv);
}
