// The Sunrise's lantern sun: a sphere that burns gold in its middle and cools through orange to a deep red rim,
// its surface slowly boiling (drifting noise) and pulsing. Additive, colour kept below white (the soft glow rule).
shader_type spatial;
render_mode unshaded, blend_add, cull_back, depth_draw_never, shadows_disabled;

uniform vec3 core_color : source_color = vec3(1.0, 0.72, 0.3);
uniform vec3 mid_color : source_color = vec3(1.0, 0.48, 0.16);
uniform vec3 edge_color : source_color = vec3(0.85, 0.2, 0.08);
uniform float energy = 1.0;

varying vec3 local_pos;

float hash13(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.zyx + 31.32);
	return fract((p.x + p.y) * p.z);
}

float noise3(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = mix(mix(hash13(i), hash13(i + vec3(1, 0, 0)), f.x), mix(hash13(i + vec3(0, 1, 0)), hash13(i + vec3(1, 1, 0)), f.x), f.y);
	float b = mix(mix(hash13(i + vec3(0, 0, 1)), hash13(i + vec3(1, 0, 1)), f.x), mix(hash13(i + vec3(0, 1, 1)), hash13(i + vec3(1, 1, 1)), f.x), f.y);
	return mix(a, b, f.z);
}

void vertex() {
	local_pos = VERTEX;
}

void fragment() {
	float facing = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	vec3 p = normalize(local_pos) * 3.0;
	float boil = noise3(p + vec3(0.0, TIME * 0.6, TIME * 0.3)) * 0.6 + noise3(p * 2.3 - TIME * 0.8) * 0.4;
	vec3 c = mix(edge_color, mid_color, smoothstep(0.05, 0.5, facing));
	c = mix(c, core_color, smoothstep(0.5, 1.0, facing) * (0.6 + 0.4 * boil));
	float pulse = 0.9 + 0.1 * sin(TIME * 5.0);
	ALBEDO = c * energy * (0.7 + 0.45 * boil) * pulse * smoothstep(0.0, 0.25, facing);
}
