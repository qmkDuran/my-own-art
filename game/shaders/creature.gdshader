// Creatures of the trainer prototype: a hit flash (white, then a hot tint) and an outline that marks the one you
// steer (hybrid control). The outline samples the four neighbours' alpha, so it hugs the real silhouette.
shader_type canvas_item;

uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float outline : hint_range(0.0, 1.0) = 0.0;
uniform vec4 outline_color : source_color = vec4(1.0, 0.84, 0.48, 1.0);

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	vec3 rgb = mix(c.rgb, flash_color.rgb, flash);
	float around = 0.0;
	around = max(around, texture(TEXTURE, UV + vec2(TEXTURE_PIXEL_SIZE.x, 0.0)).a);
	around = max(around, texture(TEXTURE, UV - vec2(TEXTURE_PIXEL_SIZE.x, 0.0)).a);
	around = max(around, texture(TEXTURE, UV + vec2(0.0, TEXTURE_PIXEL_SIZE.y)).a);
	around = max(around, texture(TEXTURE, UV - vec2(0.0, TEXTURE_PIXEL_SIZE.y)).a);
	float ring = outline * around * (1.0 - step(0.5, c.a));
	COLOR = mix(vec4(rgb, c.a), outline_color, ring);
}
