shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_nearest;
uniform float alpha = 1.0;
uniform float inner_radius = 0.0;
uniform float outer_radius = 1.0;

//uniform float strength = 1.0;
global uniform float ca_strength;
global uniform bool ca_enabled;

void fragment() {
	vec4 output = texture(SCREEN_TEXTURE, SCREEN_UV);
	
	if (ca_enabled) {
		float x = abs(UV.r-.5)*2.0;
		float y = abs(UV.g-.5)*2.0;
		float shift = (1.0 - (1.0-sqrt(x*x+y*y)/outer_radius)/(1.0-inner_radius)) * ca_strength;
		
		output.r = texture(SCREEN_TEXTURE, vec2(SCREEN_UV.x + shift, SCREEN_UV.y + shift)).r;
		//output.g = texture(SCREEN_TEXTURE, SCREEN_UV).g;
		output.b = texture(SCREEN_TEXTURE, vec2(SCREEN_UV.x + shift, SCREEN_UV.y + shift)).b;
		//output.g = texture(SCREEN_TEXTURE, vec2(SCREEN_UV.x - shift, SCREEN_UV.y)).g;
	}
	
	COLOR = output;
}