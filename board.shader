shader_type canvas_item;

const int rect_size = 40;
const float rect_size_2xf = float(rect_size * 2);
const vec4 dark_rect_color = vec4(0.32, 0.33, 0.38, 1.0);
const vec4 light_rect_color = vec4(0.58, 0.59, 0.62, 1.0);

void fragment()
{
  int rect_id = int(SCREEN_UV.y / SCREEN_PIXEL_SIZE.x / rect_size_2xf);
  if (rect_id % 2 == 0 &&
      mod(SCREEN_UV.x, SCREEN_PIXEL_SIZE.x * rect_size_2xf) <
          SCREEN_PIXEL_SIZE.x * float(rect_size))
  {
    COLOR = light_rect_color;
  }
  else if (
      rect_id % 2 == 1 &&
      mod(SCREEN_UV.x, SCREEN_PIXEL_SIZE.x * rect_size_2xf) >=
          SCREEN_PIXEL_SIZE.x * float(rect_size))
  {
    COLOR = light_rect_color;
  }
  else
  {
    COLOR = dark_rect_color;
  }
}
