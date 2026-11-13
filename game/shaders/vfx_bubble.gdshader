// A protective bubble (the player's ward, an elite's shield): a soft colour fill that is strongest at the rim
// (fresnel), a honeycomb of glowing hex edges that shimmers, a ripple that rings out from where a hit landed, and
// cracks that open as the shield weakens. Additive; colour kept below white (the soft glow rule).
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec3 color : source_color = vec3(1.0, 0.68, 0.3);
uniform vec3 edge_color : source_color = vec3(1.0, 0.85, 0.45);
uniform vec3 ripple_color : source_color = vec3(1.0, 0.9, 0.55);
uniform float energy = 0.9;
uniform float fresnel_power = 2.2;
uniform float hex_scale = 7.0;
uniform float strength = 1.0;
uniform vec3 hit_dir = vec3(0.0, 1.0, 0.0);
uniform float hit_age = 10.0;
uniform float crack = 0.0;

varying vec3 local_pos;

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float hex_edge(vec2 p) {
	p.x *= 1.1547;
	p.y += mod(floor(p.x), 2.0) * 0.5;
	vec2 f = abs(fract(p) - 0.5);
	return abs(max(f.x * 1.5 + f.y, f.y * 2.0) - 1.0);
}

void vertex() {
	local_pos = VERTEX;
}

void fragment() {
	vec3 n = normalize(local_pos);
	float rim = pow(1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), fresnel_power);
	vec2 uv = vec2(atan(n.z, n.x) / 6.2832 * 2.0, acos(clamp(n.y, -1.0, 1.0)) / 3.1416) * hex_scale;
	float edge = smoothstep(0.09, 0.0, hex_edge(uv));
	float shimmer = 0.55 + 0.45 * sin(TIME * 3.0 + n.y * 7.0 + n.x * 5.0);
	float ring = abs(acos(clamp(dot(n, normalize(hit_dir)), -1.0, 1.0)) - hit_age * 5.0);
	float ripple = smoothstep(0.35, 0.0, ring) * exp(-hit_age * 3.5);
	vec2 cell = floor(uv * 1.7);
	float broken = step(1.0 - crack * 0.6, hash12(cell)) * edge;
	vec3 c = color * (0.05 + rim * 0.75);
	c += edge_color * edge * (0.08 + rim * 0.45) * shimmer;
	c += ripple_color * ripple * (0.5 + edge);
	c += edge_color * broken * 0.6;
	ALBEDO = c * energy * strength;
}
