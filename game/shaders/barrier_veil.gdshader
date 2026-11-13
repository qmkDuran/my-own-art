// The soft edge of the world: a faint curtain of drifting mist on an invisible wall, only visible when the player
// is within a few metres (global uniform player_position), fading up from the ground and out at the top.
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

global uniform vec3 player_position;

uniform vec3 color : source_color = vec3(0.7, 0.6, 0.95);
uniform float reach = 3.0;
uniform float strength = 0.22;
uniform float height = 2.6;

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
	float near = 1.0 - smoothstep(reach * 0.35, reach, distance(world_pos.xz, player_position.xz));
	float rise = world_pos.y - player_position.y;
	float band = smoothstep(-0.2, 0.4, rise) * (1.0 - smoothstep(height * 0.5, height, rise));
	vec2 flow = vec2(world_pos.x + world_pos.z, world_pos.y * 0.6 - TIME * 0.25);
	float wisps = value_noise(flow * 1.6) * 0.6 + value_noise(flow * 4.0 + TIME * 0.1) * 0.4;
	ALBEDO = color * near * band * strength * (0.4 + wisps);
}
