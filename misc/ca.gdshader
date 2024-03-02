shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_nearest;
uniform float alpha = 1.0;
uniform float inner_radius = 0.0;
uniform float outer_radius = 1.0;

uniform float strength = 1.0;

void fragment() {
	float x = abs(UV.r-.5)*2.0;
	float y = abs(UV.g-.5)*2.0;
	float shift = (1.0 - (1.0-sqrt(x*x+y*y)/outer_radius)/(1.0-inner_radius)) * strength;
	
	vec4 output = texture(SCREEN_TEXTURE, SCREEN_UV);
	
	output.r = texture(SCREEN_TEXTURE, vec2(SCREEN_UV.x - shift, SCREEN_UV.y)).r;
	//output.g = texture(SCREEN_TEXTURE, SCREEN_UV).g;
	output.b = texture(SCREEN_TEXTURE, vec2(SCREEN_UV.x - shift, SCREEN_UV.y)).b;
	//output.g = texture(SCREEN_TEXTURE, vec2(SCREEN_UV.x - shift, SCREEN_UV.y)).g;
	
	COLOR = output;
}