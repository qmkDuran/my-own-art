// Procedural storybook stone for the code-made parts of the town: rounded cobbles (with wet puddles and rain
// ripples on the street), bricks for walls and steps, plain plaster for fillers. Wetness comes from the global
// shader uniforms "wetness" (0 dry .. 1 soaked) and "rain" (0 or 1, fades).
shader_type spatial;
render_mode cull_back;

global uniform float wetness;
global uniform float rain;

uniform int pattern = 0; // 0 cobbles, 1 bricks, 2 plaster
uniform vec3 base_color : source_color = vec3(0.42, 0.4, 0.42);
uniform vec3 alt_color : source_color = vec3(0.5, 0.45, 0.4);
uniform vec3 mortar_color : source_color = vec3(0.13, 0.12, 0.13);
uniform float cell_scale = 3.4;
uniform float brick_scale = 3.0;
uniform float puddle_scale = 0.16;
uniform float puddle_amount = 1.0;
uniform float bump_strength = 0.9;

varying vec3 world_pos;
varying vec3 world_normal;

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

vec2 hash22(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.103, 0.0973));
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.xx + p3.yz) * p3.zy);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash12(i), hash12(i + vec2(1, 0)), u.x), mix(hash12(i + vec2(0, 1)), hash12(i + vec2(1, 1)), u.x), u.y);
}

float fbm(vec2 p) {
	return value_noise(p) * 0.55 + value_noise(p * 2.1) * 0.3 + value_noise(p * 4.3) * 0.15;
}

// Cobbles: x = distance to the cell edge (0 at mortar), y = random id of the cell.
vec2 cobbles(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	float best = 8.0;
	float second = 8.0;
	vec2 best_id = vec2(0.0);
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 o = vec2(float(x), float(y));
			vec2 r = o + 0.15 + 0.7 * hash22(cell + o) - f;
			float d = dot(r, r);
			if (d < best) { second = best; best = d; best_id = cell + o; }
			else if (d < second) { second = d; }
		}
	}
	return vec2(sqrt(second) - sqrt(best), hash12(best_id));
}

vec2 bricks(vec2 p) {
	p *= vec2(1.0, 2.0);
	float row = floor(p.y);
	p.x += mod(row, 2.0) * 0.5;
	vec2 f = fract(p);
	vec2 edge = min(f, 1.0 - f) * vec2(1.0, 0.5);
	return vec2(min(edge.x, edge.y) * 2.0, hash12(floor(p)));
}

vec2 surface_coords() {
	vec3 n = abs(world_normal);
	if (n.y > 0.6) return world_pos.xz;
	if (n.x > n.z) return world_pos.zy;
	return world_pos.xy;
}

vec2 pattern_at(vec2 p) {
	if (pattern == 0) return cobbles(p * cell_scale);
	if (pattern == 1) return bricks(p * brick_scale * vec2(0.5, 1.0));
	return vec2(1.0, fbm(p * 3.0));
}

float stone_height(vec2 p) {
	return smoothstep(0.0, 0.22, pattern_at(p).x);
}

float puddle_mask(vec2 p, float up) {
	float n = fbm(p * puddle_scale) * 0.75 + fbm(p * puddle_scale * 4.0) * 0.25;
	float level = mix(0.78, 0.56, wetness) - (puddle_amount - 1.0) * 0.1;
	return smoothstep(level, level + 0.04, n) * step(0.9, up) * float(pattern == 0);
}

vec2 ripple(vec2 p) {
	vec2 cell = floor(p * 1.6);
	vec2 f = fract(p * 1.6) - 0.5 - (hash22(cell) - 0.5) * 0.4;
	float t = fract(TIME * 0.9 + hash12(cell));
	float d = length(f);
	float ring = sin((d - t * 0.5) * 60.0) * smoothstep(0.5, 0.0, abs(d - t * 0.5) * 8.0) * (1.0 - t);
	return normalize(f + 0.0001) * ring;
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec2 p = surface_coords();
	vec2 cell = pattern_at(p);
	float h = smoothstep(0.0, 0.22, cell.x);
	vec3 stone = mix(base_color, alt_color, cell.y) * (0.82 + 0.3 * fbm(p * 5.0));
	vec3 color = mix(mortar_color, stone, h);
	float up = world_normal.y;
	float wet = wetness * mix(0.6, 1.0, step(0.9, up));
	float puddle = puddle_mask(p, up);
	color *= mix(1.0, 0.55, wet);
	color = mix(color, color * 0.35, puddle);
	ALBEDO = color;
	ROUGHNESS = mix(mix(0.92, 0.32, wet), 0.03, puddle) + (1.0 - h) * 0.1 * (1.0 - puddle);
	SPECULAR = 0.5;
	if (pattern == 0) {
		float e = 0.03;
		float dx = stone_height(p + vec2(e, 0.0)) - stone_height(p - vec2(e, 0.0));
		float dz = stone_height(p + vec2(0.0, e)) - stone_height(p - vec2(0.0, e));
		vec2 slope = vec2(dx, dz) * bump_strength * (1.0 - puddle);
		slope += ripple(p) * rain * puddle * 0.6;
		NORMAL_MAP = normalize(vec3(-slope.x, -slope.y, 1.0)) * 0.5 + 0.5;
	}
}
