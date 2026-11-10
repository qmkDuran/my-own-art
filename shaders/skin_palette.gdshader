shader_type canvas_item;
// Palette swap for skin. Art paints skin with the KEY ramp (data/heroes.json "skin_key" and
// SkinPalette.FACTORS); each key colour is replaced by the matching colour of the chosen tone.

uniform vec4 key_colors[7] : source_color;
uniform vec4 target_colors[7] : source_color;
uniform float tolerance = 0.025;

varying vec4 modulate;

void vertex() {
	modulate = COLOR;
}

void fragment() {
	vec4 texel = texture(TEXTURE, UV);
	for (int i = 0; i < 7; i++) {
		if (distance(texel.rgb, key_colors[i].rgb) < tolerance) {
			texel.rgb = target_colors[i].rgb;
			break;
		}
	}
	COLOR = texel * modulate;
}
