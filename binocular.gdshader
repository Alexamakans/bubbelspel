shader_type canvas_item;

instance uniform float radius = 2.0;

float circle(vec2 center, vec2 position, float r, float feather)
{
	return smoothstep(r, r + feather, length(position - center));
}

void fragment() {
  vec2 s = SCREEN_PIXEL_SIZE;
  float ar = s.y / s.x;
  vec2 uv_scaled = (UV - vec2(0.5)) / vec2(1.0, ar);
  float c = circle(vec2(0, 0), uv_scaled, radius/ar, 0.05);
	COLOR = vec4(0, 0, 0, c);
}
