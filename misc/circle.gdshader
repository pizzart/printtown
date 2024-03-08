shader_type canvas_item;

uniform float size : hint_range(0.0, 1.0) = 1.0;

float circle(vec2 position, float radius, float feather)
{
	return smoothstep(radius, radius + feather, length(position));
}

void fragment() {
	float c = circle((SCREEN_UV - vec2(0.5)) * vec2((1.0 / SCREEN_PIXEL_SIZE.x) / (1.0 / SCREEN_PIXEL_SIZE.y), 1.0), size * 1.5, 0.0);
	COLOR.rgb = vec3(1.0 - c);
	COLOR.a = c;
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
