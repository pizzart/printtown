shader_type canvas_item;

uniform float shrink: hint_range(0.0, 10.0, 0.01) = 1.0;
uniform float fade: hint_range(0.0, 10.0, 0.01) = 1.0;
uniform vec4 gradient_middle : source_color = vec4(1.0);
uniform vec4 gradient_out : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	float dist = length(vec2(0.0, (UV.y - 0.5) * shrink)) * fade;
	COLOR.rgb = vec3(mix(gradient_middle, gradient_out, pow(dist * 0.1, 0.3)).rgb);
}