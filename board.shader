shader_type canvas_item;

const int rect_size = 5;

void fragment() {
  // ivec2 pixel = ivec2(SCREEN_UV / SCREEN_PIXEL_SIZE);
  // // if (pixel.x / 5 / 2 == 0) {
  // if (pixel.x > 50) {
  //   COLOR = vec4(1.0);
  // } else {
  //   COLOR = vec4(vec3(0.0), 1.0);
  // }
  // if (mod(UV.x, SCREEN_PIXEL_SIZE.x * 20.0) < SCREEN_PIXEL_SIZE.x * 10.0) {
  //   COLOR.rgb = vec3(1.0,0.0,0.0);
  // }
  if (mod(UV.x, 0.1) < 0.05) {
    COLOR.rgb = vec3(0.58,0.59,0.62);
  } else {
    COLOR.rgb = vec3(0.32,0.33,0.38);
  }
  // COLOR.rgb = vec3(1.0,0.0,0.0);
}
