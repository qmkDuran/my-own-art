// Demons: a white flash when struck, and a dissolve into drifting shadow with an ember edge when they fall.
shader_type canvas_item;

uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform float dissolve : hint_range(0.0, 1.0) = 0.0;
uniform vec4 edge_color : source_color = vec4(0.66, 0.52, 0.95, 1.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	vec2 px = floor(UV / TEXTURE_PIXEL_SIZE / 2.0);
	float n = hash(px) * 0.7 + (1.0 - UV.y) * 0.3;
	if (dissolve > 0.0 && n < dissolve) discard;
	if (dissolve > 0.0 && n < dissolve + 0.08) c.rgb = edge_color.rgb;
	c.rgb = mix(c.rgb, vec3(1.0), flash);
	COLOR = c;
}
