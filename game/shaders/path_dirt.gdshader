// A woodland path: packed earth with small stones, its edges fading softly into the moss (UV.x runs across it).
shader_type spatial;
render_mode cull_back, depth_draw_opaque;

uniform vec3 dirt : source_color = vec3(0.24, 0.19, 0.14);
uniform vec3 stone : source_color = vec3(0.33, 0.3, 0.28);
uniform float edge = 0.3;

varying vec3 world_pos;

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float across = 1.0 - abs(UV.x - 0.5) * 2.0;
	float ragged = hash12(floor(world_pos.xz * 4.0)) * 0.25;
	float pebble = step(0.93, hash12(floor(world_pos.xz * 9.0)));
	ALBEDO = mix(dirt, stone, pebble * 0.7) * (0.85 + 0.3 * hash12(floor(world_pos.xz * 2.0)));
	ALPHA = smoothstep(0.0, edge, across - ragged);
	ROUGHNESS = 0.9;
}
