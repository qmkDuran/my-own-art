// Sprites that can flash white when hit (enemies, the Lamplighter). Lit normally otherwise.
shader_type canvas_item;

uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 0.95, 0.85, 1.0);

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	COLOR = vec4(mix(c.rgb, flash_color.rgb, flash), c.a);
}
