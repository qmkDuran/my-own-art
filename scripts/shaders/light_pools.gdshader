// Light pools on the world's ground and props (see LightPools): the ground near the player
// keeps its full brightness and dims gently towards the screen's edges, and a few small
// tinted pools glow around fires, lit conduits and machine cores.
// Only the world's tile layers use it: the hero, enemies, effects, loot and the HUD are never
// dimmed. The light is worked out once per world pixel, so pixel art stays crisp.
shader_type canvas_item;

const int MAX_SOURCES = 16;

// The player's position, in world pixels: the middle of the pool.
uniform vec2 pool_centre;
// Half the view, in world pixels: the pool is screen-shaped.
uniform vec2 pool_half_size = vec2(320.0, 180.0);
// Full brightness out to this share of the half view, then a smooth fall...
uniform float pool_inner = 0.3;
// ...to `edge_brightness` at this share (the screen's corners are at about 1.41).
uniform float pool_outer = 1.3;
// Brightness at the edge of the pool (1.0 = no pool at all).
uniform float edge_brightness = 1.0;

// Each source: xy = position (world pixels), z = radius (world pixels), w = strength (0-1).
uniform vec4 sources[MAX_SOURCES];
// Each source's light colour (rgb).
uniform vec4 source_tints[MAX_SOURCES];
uniform int source_count = 0;
// How much a source's coloured light adds on top of the ground's own colour, and a faint
// glow so it shows on near-black ground too.
uniform float light_amount = 0.6;
uniform float glow_amount = 0.04;

varying vec2 world_position;
varying vec4 modulate;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	modulate = COLOR;
}

void fragment() {
	vec4 colour = texture(TEXTURE, UV) * modulate;
	vec2 pixel = floor(world_position) + 0.5;
	float reach = length((pixel - pool_centre) / pool_half_size);
	float light = mix(1.0, edge_brightness, smoothstep(pool_inner, pool_outer, reach));
	vec3 coloured_light = vec3(0.0);
	for (int i = 0; i < source_count; i++) {
		float falloff = 1.0 - smoothstep(0.0, 1.0, length(pixel - sources[i].xy) / sources[i].z);
		float amount = falloff * falloff * sources[i].w;
		light += (1.0 - light) * amount;
		coloured_light += source_tints[i].rgb * amount;
	}
	colour.rgb = colour.rgb * (vec3(light) + coloured_light * light_amount) + coloured_light * glow_amount * colour.a;
	COLOR = colour;
}
