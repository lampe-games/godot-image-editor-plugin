shader_type canvas_item;

uniform int zoom = 1;

const int zoom_threshold_to_show_grid = 10;

void fragment()
{
  COLOR = textureLod(TEXTURE, UV, 0.0);
  if (zoom >= zoom_threshold_to_show_grid)
  {
    vec2 texel_half = TEXTURE_PIXEL_SIZE / 2.0;
    vec2 uv_chunk_within_texel = mod(UV, TEXTURE_PIXEL_SIZE);
    vec2 grid_size = TEXTURE_PIXEL_SIZE / float(zoom);
    if (uv_chunk_within_texel.x < grid_size.x || uv_chunk_within_texel.y < grid_size.y)
    {
      COLOR = vec4(1.0, 0.0, 0.0, 1.0);
    }
  }
}
