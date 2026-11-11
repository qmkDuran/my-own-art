shader_type canvas_item;
// The colour grade over the world (under the UI): outside the lantern's pool the picture cools and loses some
// colour (the light still matters, by contrast, not by blackness); a slow haze drifts over it; a vignette closes
// the edges. Everything stays readable.

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform vec2 light_uv = vec2(0.5);          // the lantern pool's centre on screen (0..1)
uniform float light_r = 0.2;                // its radius, as a share of the screen width
uniform float aspect = 1.7778;
uniform float outside_desat = 0.3;
uniform vec3 outside_tint : source_color = vec3(0.86, 0.92, 1.06);
uniform vec3 haze : source_color = vec3(0.35, 0.38, 0.5);
uniform float haze_amount = 0.05;
uniform float vignette = 0.22;
uniform float time = 0.0;

void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	vec2 d = (SCREEN_UV - light_uv) * vec2(1.0, 1.0 / aspect);
	float outside = smoothstep(light_r * 0.85, light_r * 1.2, length(d));
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(c, mix(c, vec3(l), outside_desat) * outside_tint, outside);
	float n = sin(SCREEN_UV.x * 9.0 + time * 0.13) * sin(SCREEN_UV.y * 7.0 - time * 0.11);
	c += haze * haze_amount * (0.7 + 0.3 * n) * outside;
	vec2 v = (SCREEN_UV - 0.5) * vec2(1.0, 0.8);
	c *= 1.0 - vignette * smoothstep(0.3, 0.75, length(v) * 1.3);
	COLOR = vec4(c, 1.0);
}
