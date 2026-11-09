// Palette swap: recolours up to MAX_SWAPS key colours into target colours in one pass.
// Every other colour (outlines, eyes, highlights) passes through untouched.
// Used by the layered trainer (3 swaps per layer) and Emberoo's Awakened look.
// Every key is matched against the original pixel, so a target that equals another key
// (e.g. a ramp shifted down by one step) is never swapped twice.
shader_type canvas_item;

const int MAX_SWAPS = 8;

uniform vec4 keys[MAX_SWAPS];
uniform vec4 targets[MAX_SWAPS];
// How many of `keys` / `targets` are in use.
uniform int swap_count = 0;
// Largest per-channel difference that still counts as a match (about 5 of 255).
uniform float tolerance = 0.02;

// The node's modulate, kept so fades and flashes still work on swapped sprites.
varying vec4 modulate;

void vertex() {
	modulate = COLOR;
}

bool matches(vec3 colour, vec4 key) {
	vec3 difference = abs(colour - key.rgb);
	return max(difference.r, max(difference.g, difference.b)) <= tolerance;
}

void fragment() {
	vec4 original = texture(TEXTURE, UV);
	vec3 swapped = original.rgb;
	for (int index = 0; index < MAX_SWAPS; index++) {
		if (index >= swap_count) {
			break;
		}
		if (matches(original.rgb, keys[index])) {
			swapped = targets[index].rgb;
			break;
		}
	}
	COLOR = vec4(swapped, original.a) * modulate;
}
