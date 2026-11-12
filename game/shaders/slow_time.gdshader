// Tactical slow-time (the trainer prototype): the world drains toward a cool grey while a move is being aimed.
shader_type canvas_item;

uniform sampler2D screen : hint_screen_texture, filter_nearest;
uniform float amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 c = texture(screen, SCREEN_UV);
	float l = dot(c.rgb, vec3(0.3, 0.59, 0.11));
	COLOR = vec4(mix(c.rgb, vec3(l) * vec3(0.92, 0.96, 1.06), amount), 1.0);
}
