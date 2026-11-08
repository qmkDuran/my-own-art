// Palette swap: recolours three key colours into three target colours in one pass.
// Every other colour (outlines, eyes, highlights) passes through untouched.
// All three keys are matched against the original pixel, so a target that equals
// another key (e.g. a skin ramp shifted by one step) is never swapped twice.
shader_type canvas_item;

uniform vec4 key_light = vec4(0.780, 0.812, 0.800, 1.0);
uniform vec4 key_mid = vec4(0.506, 0.592, 0.588, 1.0);
uniform vec4 key_dark = vec4(0.224, 0.290, 0.314, 1.0);
uniform vec4 target_light = vec4(0.780, 0.812, 0.800, 1.0);
uniform vec4 target_mid = vec4(0.506, 0.592, 0.588, 1.0);
uniform vec4 target_dark = vec4(0.224, 0.290, 0.314, 1.0);
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
	if (matches(original.rgb, key_light)) {
		swapped = target_light.rgb;
	} else if (matches(original.rgb, key_mid)) {
		swapped = target_mid.rgb;
	} else if (matches(original.rgb, key_dark)) {
		swapped = target_dark.rgb;
	}
	COLOR = vec4(swapped, original.a) * modulate;
}
