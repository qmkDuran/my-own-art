// A defeated creature dissolving into light: its own texture, eaten away by noise as progress goes 0..1, with a
// soft warm glowing edge at the dissolve front.
shader_type spatial;
render_mode cull_back;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap;
uniform float progress = 0.0;
uniform vec3 edge_color : source_color = vec3(1.0, 0.6, 0.25);
uniform float edge_width = 0.08;
uniform float edge_energy = 1.4;

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
	float n = value_noise(UV * 24.0) * 0.7 + value_noise(UV * 60.0) * 0.3;
	if (n < progress) {
		discard;
	}
	float edge = 1.0 - smoothstep(progress, progress + edge_width, n);
	ALBEDO = texture(albedo_tex, UV).rgb;
	ROUGHNESS = 0.85;
	EMISSION = edge_color * edge * edge_energy * step(0.001, progress);
}
