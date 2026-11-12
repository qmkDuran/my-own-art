// The battle transition (the trainer prototype): a black swirl closes over the screen, then opens again.
shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float aspect = 1.78;

void fragment() {
	vec2 p = (UV - 0.5) * vec2(aspect, 1.0);
	float r = length(p);
	float a = atan(p.y, p.x) / 6.2832 + 0.5;
	float swirl = fract(a * 4.0 + r * 2.5);
	float edge = progress * 1.6 - r * 0.9;
	float cover = step(swirl, edge) + step(1.15, progress * 1.6 - r * 0.5);
	COLOR = vec4(vec3(0.04, 0.04, 0.07), clamp(cover, 0.0, 1.0));
}
