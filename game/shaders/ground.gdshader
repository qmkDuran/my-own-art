// The zone's ground, drawn per pixel from a tiny terrain map (one texel per 32 px cell). Borders between terrains
// are warped by noise so nothing looks like a grid; every colour is a palette colour, mixed by an ordered 4x4
// dither so it stays crisp pixel art. Lit by the scene's 2D lights like any sprite.
shader_type canvas_item;

uniform sampler2D map_tex : filter_nearest;
uniform vec2 map_size;
uniform float cell = 32.0;
uniform float warp = 10.0;
uniform sampler2D stream_tex : filter_linear;
uniform sampler2D path_tex : filter_linear;
uniform float path_scale = 8.0;
uniform vec4 pond;
uniform vec3 circle;
uniform float stream_half = 1.0;
uniform float stone_wear = 1.0;
uniform int stone_style = 0;            // 0 flagstones, 1 cobbles (the city), 2 silk (a moth nest)
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
const int WALL = 6;

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

vec4 path(vec2 px, float m) {
	vec4 col = dith(c_earth_dk, c_earth, fbm(px * 0.08) * 1.2 - 0.1, px);
	float h = hash(floor(px / 2.0));
	if (h > 0.985) { col = h > 0.993 ? c_earth_lt : c_stone; }
	if (m < 0.62) { col = dith(col, c_moss_dk, 0.4, px); }
	return col;
}

float path_mask(vec2 px, vec2 w) {
	vec2 size = map_size * cell;
	return texture(path_tex, (px + w * 0.6) / size).r;
}

// Signed distance (px) to the edge of the visible water: negative inside. The stream follows its curve, the pond
// its ellipse; both sit inside their blocked cells, the rest of those cells is reedy bank.
float water_edge(vec2 px, bool is_stream) {
	if (is_stream) {
		float row = px.y / cell - 0.5;
		float c = texture(stream_tex, vec2((row + 0.5) / map_size.y, 0.5)).r;
		return abs(px.x - (c + 0.5) * cell) - stream_half * cell;
	}
	vec2 q = (px - pond.xy) / pond.zw;
	return (length(q) - 1.0) * min(pond.z, pond.w);
}

vec4 bank(vec2 px) {
	vec4 col = dith(c_ink, c_moss_dk, fbm(px * 0.09) * 1.3 - 0.2, px);
	vec2 rc = floor(px / vec2(3.0, 9.0));
	if (hash(rc) > 0.72 && fract(px.y / 9.0) > 0.25) { col = hash(rc + 3.0) > 0.5 ? c_glass_dk : c_glass_dp; }
	return col;
}

vec4 water(vec2 px, float edge) {
	if (edge > 0.0) { return bank(px); }
	float n = fbm(vec2(px.x * 0.04, px.y * 0.02 - TIME * 0.15));
	vec4 col = dith(c_glass_dp, c_glass_dk, n * 1.3 - 0.15, px);
	float band = sin(px.x * 0.07 + px.y * 0.16 + TIME * 0.6 + n * 6.0);
	if (band > 0.93) { col = c_glass; }
	float h = hash(floor(px / 2.0) + floor(TIME * 0.5));
	if (h > 0.997) { col = c_glint; }
	if (edge > -2.0) { col = c_glass_lt; }
	else if (edge > -4.0) { col = c_glass; }
	return col;
}

// Flagstones that have seen weather: per-tile shade, cracks, missing tiles and moss, all wearing more toward the
// edge of the paved area (edge: 0 at its centre, 1 at its rim).
vec4 stone(vec2 px, float edge) {
	vec2 q = px / vec2(20.0, 14.0);
	q.x += floor(q.y) * 0.5;
	vec2 f = fract(q);
	vec2 id = floor(q);
	float h = hash(id);
	float wear = (edge * edge * 0.9 + fbm(px * 0.03) * 0.35) * stone_wear;
	if (h < wear * 0.32) { return dith(c_earth_dk, c_moss_dk, fbm(px * 0.1), px); }
	if (f.x < 0.07 || f.y < 0.1) { return (h > 0.6 || wear > 0.55) ? c_moss_dk : c_stone_dk; }
	vec4 col = dith(c_stone, c_stone_lt, h * 0.6 + fbm(px * 0.1) * 0.35 - 0.15 - wear * 0.3, px);
	if (hash(id + 7.0) > 0.72 && abs(f.x - f.y * (hash(id + 3.0) - 0.5) * 1.6 - 0.5) < 0.035) { col = c_stone_dk; }
	if (fbm(px * 0.06 + 11.0) > 0.66 - wear * 0.25 + (1.0 - stone_wear) * 0.3) { col = dith(col, c_moss, 0.55, px); }
	return col;
}

// Round cobbles: the nearest of a jittered grid of points; dark gaps where two cobbles meet.
vec4 cobbles(vec2 px) {
	vec2 g = px / 9.0;
	vec2 base = floor(g);
	float d1 = 9.0;
	float d2 = 9.0;
	vec2 id = base;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 c = base + vec2(float(x), float(y));
			float d = length(g - c - vec2(hash(c), hash(c + 5.0)));
			if (d < d1) { d2 = d1; d1 = d; id = c; } else if (d < d2) { d2 = d; }
		}
	}
	if (d2 - d1 < 0.12) { return c_stone_dk; }
	vec4 col = dith(c_stone, c_stone_lt, hash(id) * 0.7 + 0.1 - d1 * 0.4, px);
	if (fbm(px * 0.05) > 0.7) { col = dith(col, c_moss, 0.4, px); }
	return col;
}

// A moth nest's floor: concentric silk and radial strands around the arena's centre.
vec4 silk(vec2 px) {
	vec2 d = px - circle.xy;
	float r = length(d);
	float a = atan(d.y, d.x);
	vec4 col = dith(c_stone_dk, c_stone, fbm(px * 0.07) * 1.2 - 0.3, px);
	float ring = fract(r / 26.0 + fbm(px * 0.03) * 0.9);
	float spoke = fract(a / 6.2832 * 13.0 + fbm(px * 0.02 + 3.0) * 0.6);
	bool broken = fbm(px * 0.05 + 9.0) < 0.45;          // the web is torn in places
	if (!broken && (ring < 0.03 || spoke < 0.02)) { col = dith(col, c_stone_lt, 0.35, px); }
	return col;
}

// The top of a rampart seen from above: big dark blocks, a lit inner edge where it meets the street.
vec4 rampart(vec2 px, vec2 w) {
	vec2 q = px / vec2(24.0, 16.0);
	q.x += floor(q.y) * 0.5;
	vec2 f = fract(q);
	if (f.x < 0.06 || f.y < 0.1) { return c_ink; }
	vec4 col = dith(c_stone_dk, c_stone, hash(floor(q)) * 0.5, px);
	if (terr(px + vec2(0.0, 6.0)) == STONE || terr(px + vec2(0.0, -6.0)) == STONE) { col = c_stone_lt; }
	return col;
}

void fragment() {
	vec2 px = floor(UV * map_size * cell);
	vec2 w = (vec2(vnoise(px * 0.06), vnoise(px * 0.06 + 31.7)) - 0.5) * warp;
	int t = terr_w(px, w);
	ivec2 cc = clamp(ivec2(floor(px / cell)), ivec2(0), ivec2(map_size) - 1);
	int raw = int(texelFetch(map_tex, cc, 0).r * 255.0 + 0.5);
	bool is_stream = texelFetch(map_tex, cc, 0).g > 0.5;
	vec4 col = c_ink;
	if (raw == WALL) {
		col = rampart(px, w);
	} else if (raw == WATER || raw == BRIDGE) {
		col = water(px, raw == BRIDGE ? -cell : water_edge(px, is_stream));
	} else if (t == THICKET) { col = thicket(px); }
	else if (t == STONE && length(px - circle.xy) < circle.z) {
		float e = length(px - circle.xy) / circle.z;
		col = stone_style == 1 ? cobbles(px) : (stone_style == 2 ? silk(px) : stone(px, e));
	}
	else {
		float m = path_mask(px, w);
		col = (m > 0.5 && (t == MOSS || t == PATH || t == STONE)) ? path(px, m) : moss(px);
	}
	if (open_ground(t)) {
		// the forest's canopy shades the ground to its south; any forest edge darkens a little
		if (terr_w(px + vec2(0.0, -16.0), w) == THICKET) { col = dith(col, c_void, 0.45, px); }
		else if (terr_w(px + vec2(7.0, 0.0), w) == THICKET || terr_w(px + vec2(-7.0, 0.0), w) == THICKET
				|| terr_w(px + vec2(0.0, 7.0), w) == THICKET) { col = dith(col, c_void, 0.22, px); }
	}
	COLOR = col;
}
