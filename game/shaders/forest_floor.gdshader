// The Gloomwood's floor: dark moss and earth in soft drifting patches, with scattered fallen leaves and a few pale
// grass tufts, all in noise (no textures). The path is drawn on top by vfx-free dirt strips (path_dirt).
shader_type spatial;
render_mode cull_back;

uniform vec3 moss : source_color = vec3(0.12, 0.19, 0.11);
uniform vec3 earth : source_color = vec3(0.21, 0.16, 0.12);
uniform vec3 leaves : source_color = vec3(0.3, 0.14, 0.06);
uniform vec3 grass : source_color = vec3(0.18, 0.28, 0.14);

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

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_pos.xz;
	float patches = value_noise(p * 0.12) * 0.6 + value_noise(p * 0.5) * 0.4;
	vec3 c = mix(moss, earth, smoothstep(0.35, 0.7, patches));
	float leaf = step(0.82, value_noise(p * 3.1)) * value_noise(p * 0.3);
	c = mix(c, leaves, leaf * 0.7);
	float tuft = step(0.86, value_noise(p * 5.3 + 7.0));
	c = mix(c, grass, tuft * 0.6);
	ALBEDO = c;
	ROUGHNESS = 0.95;
	SPECULAR = 0.2;
}
