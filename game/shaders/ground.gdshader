// The zone's ground, drawn per pixel from a tiny terrain map (one texel per 32 px cell). Borders between terrains
// are warped by noise so nothing looks like a grid; every colour is a palette colour, mixed by an ordered 4x4
// dither so it stays crisp pixel art. Lit by the scene's 2D lights like any sprite.
shader_type canvas_item;

uniform sampler2D map_tex : filter_nearest;
uniform vec2 map_size;
uniform float cell = 32.0;
uniform float warp = 10.0;
uniform vec4 c_void : source_color;
uniform vec4 c_ink : source_color;
uniform vec4 c_moss_dk : source_color;
uniform vec4 c_moss : source_color;
uniform vec4 c_moss_lt : source_color;
uniform vec4 c_earth_dk : source_color;
uniform vec4 c_earth : source_color;
uniform vec4 c_earth_lt : source_color;
uniform vec4 c_stone_dk : source_color;
uniform vec4 c_stone : source_color;
uniform vec4 c_stone_lt : source_color;
uniform vec4 c_glass_dp : source_color;
uniform vec4 c_glass_dk : source_color;
uniform vec4 c_glass : source_color;
uniform vec4 c_glass_lt : source_color;
uniform vec4 c_glint : source_color;

const int THICKET = 0;
const int MOSS = 1;
const int PATH = 2;
const int WATER = 3;
const int BRIDGE = 4;
const int STONE = 5;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p) { return vnoise(p) * 0.6 + vnoise(p * 2.03) * 0.3 + vnoise(p * 4.1) * 0.1; }

float bayer2(vec2 a) { a = floor(a); return fract(dot(a, vec2(0.5, a.y * 0.75))); }
float bayer4(vec2 a) { return bayer2(0.5 * a) * 0.25 + bayer2(a); }

vec4 dith(vec4 a, vec4 b, float t, vec2 px) { return t > bayer4(px) ? b : a; }

int terr(vec2 px) {
	ivec2 c = clamp(ivec2(floor(px / cell)), ivec2(0), ivec2(map_size) - 1);
	return int(texelFetch(map_tex, c, 0).r * 255.0 + 0.5);
}

// w: the pixel's border warp, computed once in fragment() and reused for its neighbour lookups.
int terr_w(vec2 px, vec2 w) {
	return terr(px + w);
}

bool open_ground(int t) { return t == MOSS || t == PATH || t == STONE; }

vec4 thicket(vec2 px) {
	vec4 col = dith(c_ink, c_moss_dk, smoothstep(0.3, 0.7, fbm(px * 0.05)), px);
	if (fbm(px * 0.13 + 7.0) > 0.64) { col = dith(col, c_glass_dp, 0.6, px); }
	float h = hash(floor(px / 3.0));
	if (h > 0.997) { col = mix(col, c_glint, 0.5 + 0.5 * sin(TIME * 1.7 + h * 60.0)); }
	return col;
}

vec4 moss(vec2 px) {
	vec4 col = dith(c_moss_dk, c_moss, fbm(px * 0.035) * 1.4 - 0.25, px);
	vec2 tc = floor(px / 6.0);
	vec2 tf = fract(px / 6.0);
	if (hash(tc) > 0.88 && tf.y > 0.45 && abs(tf.x - 0.5 + (tf.y - 1.0) * 0.3) < 0.18) { col = c_moss_lt; }
	if (hash(floor(px)) > 0.9985) { col = c_glass; }
	return col;
}

vec4 path(vec2 px, vec2 w) {
	vec4 col = dith(c_earth_dk, c_earth, fbm(px * 0.08) * 1.2 - 0.1, px);
	float h = hash(floor(px / 2.0));
	if (h > 0.985) { col = h > 0.993 ? c_earth_lt : c_stone; }
	int n = 0;
	n += terr_w(px + vec2(0.0, 5.0), w) == PATH ? 0 : 1;
	n += terr_w(px + vec2(0.0, -5.0), w) == PATH ? 0 : 1;
	n += terr_w(px + vec2(5.0, 0.0), w) == PATH ? 0 : 1;
	n += terr_w(px + vec2(-5.0, 0.0), w) == PATH ? 0 : 1;
	if (n > 0) { col = dith(col, c_moss_dk, 0.35, px); }
	return col;
}

vec4 water(vec2 px, vec2 w) {
	float n = fbm(vec2(px.x * 0.04, px.y * 0.02 - TIME * 0.15));
	vec4 col = dith(c_glass_dp, c_glass_dk, n * 1.3 - 0.15, px);
	float band = sin(px.x * 0.07 + px.y * 0.16 + TIME * 0.6 + n * 6.0);
	if (band > 0.93) { col = c_glass; }
	float h = hash(floor(px / 2.0) + floor(TIME * 0.5));
	if (h > 0.997) { col = c_glint; }
	if (terr_w(px + vec2(0.0, -4.0), w) != WATER && terr_w(px + vec2(0.0, -4.0), w) != BRIDGE) { col = c_glass_lt; }
	else if (terr_w(px + vec2(3.0, 0.0), w) != WATER || terr_w(px + vec2(-3.0, 0.0), w) != WATER) { col = c_glass; }
	return col;
}

vec4 stone(vec2 px) {
	vec2 q = px / vec2(20.0, 14.0);
	q.x += floor(q.y) * 0.5;
	vec2 f = fract(q);
	vec2 id = floor(q);
	if (f.x < 0.07 || f.y < 0.1) { return hash(id) > 0.7 ? c_moss_dk : c_stone_dk; }
	return dith(c_stone, c_stone_lt, hash(id) * 0.5 + fbm(px * 0.1) * 0.4 - 0.1, px);
}

void fragment() {
	vec2 px = floor(UV * map_size * cell);
	vec2 w = (vec2(vnoise(px * 0.06), vnoise(px * 0.06 + 31.7)) - 0.5) * warp;
	int t = terr_w(px, w);
	vec4 col = c_ink;
	if (t == THICKET) { col = thicket(px); }
	else if (t == MOSS) { col = moss(px); }
	else if (t == PATH) { col = path(px, w); }
	else if (t == WATER || t == BRIDGE) { col = water(px, w); }
	else if (t == STONE) { col = stone(px); }
	if (open_ground(t)) {
		// the forest's canopy shades the ground to its south; any forest edge darkens a little
		if (terr_w(px + vec2(0.0, -16.0), w) == THICKET) { col = dith(col, c_void, 0.45, px); }
		else if (terr_w(px + vec2(7.0, 0.0), w) == THICKET || terr_w(px + vec2(-7.0, 0.0), w) == THICKET
				|| terr_w(px + vec2(0.0, 7.0), w) == THICKET) { col = dith(col, c_void, 0.22, px); }
	}
	COLOR = col;
}
