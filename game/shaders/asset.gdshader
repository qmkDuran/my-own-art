// Material for the Meshy town assets: keeps their hand-painted colour, makes warm-lit painted windows and lantern
// glass glow (pixels in a warm hue window that are bright and saturated), and darkens and polishes upward-facing
// surfaces when the town is wet. Enemies flash a soft warm colour when hit, and creatures can get a rim light
// (per-instance flash and rim uniforms) so their silhouettes read against the dark woods.
shader_type spatial;
render_mode cull_back;

global uniform float wetness;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic;
uniform float glow = 0.0;
uniform float hue_min = 0.06;
uniform float hue_max = 0.17;
uniform float saturation_min = 0.45;
uniform float value_min = 0.72;
uniform float softness = 0.12;
uniform float base_roughness = 0.85;
instance uniform float flash = 0.0;
instance uniform vec3 flash_color : source_color = vec3(1.0, 0.7, 0.4);
instance uniform float rim = 0.0;
instance uniform vec3 rim_color : source_color = vec3(0.6, 0.7, 1.0);

varying float up;

vec3 rgb_to_hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + 1e-10)), d / (q.x + 1e-10), q.x);
}

void vertex() {
	up = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz).y;
}

void fragment() {
	vec3 c = texture(albedo_tex, UV).rgb;
	vec3 hsv = rgb_to_hsv(c);
	float in_hue = smoothstep(hue_min - softness * 0.3, hue_min, hsv.x) * (1.0 - smoothstep(hue_max, hue_max + softness * 0.3, hsv.x));
	float bright = smoothstep(value_min - softness, value_min, hsv.z) * smoothstep(saturation_min - softness, saturation_min, hsv.y);
	float mask = in_hue * bright;
	float wet = wetness * smoothstep(0.5, 0.9, up);
	ALBEDO = c * mix(1.0, 0.6, wet);
	ROUGHNESS = mix(base_roughness, 0.3, wet);
	SPECULAR = 0.4;
	float edge = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	EMISSION = c * c * mask * glow + flash_color * flash * (0.35 + 0.65 * edge) + rim_color * rim * edge;
}
