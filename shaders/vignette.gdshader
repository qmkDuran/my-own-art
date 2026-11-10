shader_type canvas_item;
// Screen-edge darkening. strength 0..1, softness controls how far it reaches inward.

uniform float strength : hint_range(0.0, 1.0) = 0.5;
uniform float softness : hint_range(0.05, 1.0) = 0.55;
uniform vec4 tint : source_color = vec4(0.0, 0.0, 0.02, 1.0);
uniform float aspect = 1.7778;

void fragment() {
	vec2 uv = UV - vec2(0.5);
	uv.x *= aspect;
	float dist = length(uv) / length(vec2(0.5 * aspect, 0.5));
	float shade = smoothstep(1.0 - softness, 1.0, dist) * strength;
	COLOR = vec4(tint.rgb, shade);
}
