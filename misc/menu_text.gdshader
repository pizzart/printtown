shader_type canvas_item;

void vertex() {
	VERTEX = vec2(640.0 - VERTEX.x, VERTEX.y);
	UV = vec2(UV.x + sin(TIME * 2.0) * 0.01 * cos(float(VERTEX.x + VERTEX.y)), UV.y + cos(TIME * 2.0) * 0.01 * sin(float(VERTEX.x - VERTEX.y)));
}

void fragment() {
	//vec4 color = texture(TEXTURE, vec2(1.0 - UV.x, UV.y));
	//COLOR.rgb = color.rgb;
}