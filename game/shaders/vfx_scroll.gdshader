// For the Blender effect meshes (swirl ring, spiral ribbon): a warm gradient that scrolls along the mesh (u runs
// along its length), soft across its width (v), and a noisy dissolve with a glowing edge as progress goes 0..1.
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;

uniform vec3 color : source_color = vec3(1.0, 0.6, 0.25);
uniform float progress = 0.0;
uniform float scroll_speed = 2.0;
uniform float energy = 1.2;
uniform float edge_width = 0.08;

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash12(i), hash12(i + vec2(1, 0)), u.x), mix(hash12(i + vec2(0, 1)), hash12(i + vec2(1, 1)), u.x), u.y);
}

void fragment() {
	float along = fract(UV.x * 1.5 - TIME * scroll_speed);
	float band = smoothstep(0.0, 0.35, along) * smoothstep(1.0, 0.6, along);
	float across = pow(1.0 - abs(UV.y - 0.5) * 2.0, 1.5);
	float tip = smoothstep(0.0, 0.15, UV.x) * smoothstep(1.0, 0.7, UV.x);
	float n = value_noise(UV * vec2(18.0, 4.0));
	float cut = progress * 1.1;
	float alive = smoothstep(cut, cut + edge_width, n);
	float edge = smoothstep(cut - edge_width, cut, n) - alive;
	float glow = (0.35 + 0.65 * band) * across * tip;
	ALBEDO = color * energy * (glow * alive + edge * 0.8);
}
