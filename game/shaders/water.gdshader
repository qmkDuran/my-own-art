// Canal and fountain water: dark, glassy and slowly moving, so the lamps and windows reflect in it (screen-space
// reflections do the mirroring). Rain roughens it with small rings.
shader_type spatial;
render_mode cull_back;

global uniform float rain;

uniform vec3 deep_color : source_color = vec3(0.02, 0.05, 0.08);
uniform float flow_speed = 0.05;
uniform float wave_scale = 0.35;
uniform float wave_strength = 0.18;

varying vec3 world_pos;

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

float waves(vec2 p) {
	vec2 drift = vec2(TIME * flow_speed, TIME * flow_speed * 0.3);
	return value_noise(p * wave_scale + drift) * 0.6 + value_noise(p * wave_scale * 2.7 - drift * 1.7) * 0.4;
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_pos.xz;
	float e = 0.05;
	float strength = wave_strength * (1.0 + rain * 1.5);
	float dx = waves(p + vec2(e, 0.0)) - waves(p - vec2(e, 0.0));
	float dz = waves(p + vec2(0.0, e)) - waves(p - vec2(0.0, e));
	vec2 slope = vec2(dx, dz) * strength / e * 0.1;
	ALBEDO = deep_color;
	ROUGHNESS = 0.02 + rain * 0.06;
	METALLIC = 0.0;
	SPECULAR = 0.7;
	NORMAL_MAP = normalize(vec3(-slope.x, -slope.y, 1.0)) * 0.5 + 0.5;
}
