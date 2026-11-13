// The night sky: a deep blue gradient with a warm glow over the rooftops, twinkling stars, a soft moon with a halo
// in the direction of the moonlight (the first directional light), and thin drifting clouds that thicken in rain.
shader_type sky;

global uniform float rain;

uniform vec3 top_color : source_color;
uniform vec3 horizon_color : source_color;
uniform vec3 glow_color : source_color;
uniform float glow_height = 0.12;
uniform float star_density = 0.002;
uniform float star_brightness = 3.0;
uniform float moon_size = 0.035;
uniform vec3 moon_color : source_color;
uniform float moon_energy = 8.0;
uniform float halo = 0.6;
uniform vec3 cloud_color : source_color;
uniform float cloud_cover = 0.35;
uniform float rain_cloud_cover = 0.85;

float hash13(vec3 p3) {
	p3 = fract(p3 * 0.1031);
	p3 += dot(p3, p3.zyx + 31.32);
	return fract((p3.x + p3.y) * p3.z);
}

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

float fbm(vec2 p) {
	return value_noise(p) * 0.5 + value_noise(p * 2.03) * 0.3 + value_noise(p * 4.1) * 0.2;
}

float stars(vec3 dir) {
	vec3 p = dir * 260.0;
	vec3 cell = floor(p);
	float h = hash13(cell);
	if (h > star_density * 60.0) return 0.0;
	vec3 center = cell + 0.5 + (vec3(hash13(cell + 1.7), hash13(cell + 3.1), hash13(cell + 5.3)) - 0.5) * 0.6;
	float d = length(p - center);
	float twinkle = 0.65 + 0.35 * sin(TIME * (1.0 + h * 40.0) + h * 100.0);
	return smoothstep(0.35, 0.0, d) * twinkle * (0.3 + 0.7 * hash13(cell + 9.0));
}

void sky() {
	vec3 dir = EYEDIR;
	float y = max(dir.y, 0.0);
	vec3 color = mix(horizon_color, top_color, pow(y, 0.6));
	color += glow_color * exp(-y / glow_height);
	float cover = mix(cloud_cover, rain_cloud_cover, rain);
	vec2 cloud_uv = dir.xz / (dir.y + 0.15) * 1.4 + vec2(TIME * 0.004, 0.0);
	float clouds = smoothstep(1.0 - cover, 1.0, fbm(cloud_uv)) * smoothstep(0.0, 0.2, dir.y);
	vec3 moon_dir = -LIGHT0_DIRECTION;
	float moon_dot = dot(dir, moon_dir);
	float moon_disc = smoothstep(cos(moon_size), cos(moon_size * 0.85), moon_dot);
	float moon_halo = pow(max(moon_dot, 0.0), 120.0) * halo + pow(max(moon_dot, 0.0), 12.0) * halo * 0.15;
	float star = stars(dir) * star_brightness * (1.0 - clouds) * (1.0 - rain * 0.8) * smoothstep(0.02, 0.2, dir.y);
	color += vec3(star);
	color += moon_color * (moon_disc * moon_energy + moon_halo) * (1.0 - clouds * 0.7);
	color = mix(color, cloud_color + moon_color * moon_halo * 0.4, clouds * 0.85);
	if (dir.y < 0.0) color = mix(horizon_color, horizon_color * 0.3, smoothstep(0.0, -0.3, dir.y));
	COLOR = color;
}
