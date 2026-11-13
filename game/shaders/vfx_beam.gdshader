// The heavy's beam: a glowing tube whose middle (facing the camera) burns a warm gold and whose edges cool to a
// deep orange, with bright bands racing along it (UV.y runs along the beam) and a soft flicker. fade 0..1 thins
// and dims it. Additive, colour kept below white (the soft glow rule).
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec3 core_color : source_color = vec3(1.0, 0.78, 0.38);
uniform vec3 outer_color : source_color = vec3(1.0, 0.36, 0.12);
uniform float energy = 1.1;
uniform float fade = 1.0;
uniform float scroll = 6.0;

void fragment() {
	float facing = clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0);
	float bands = 0.65 + 0.35 * sin(UV.y * 40.0 - TIME * scroll * 6.0);
	float streaks = 0.75 + 0.25 * sin(UV.x * 37.7 + UV.y * 9.0 - TIME * scroll * 3.0);
	vec3 c = mix(outer_color, core_color, smoothstep(0.35, 0.95, facing));
	float body = smoothstep(0.0, 0.45, facing);
	float ends = smoothstep(0.0, 0.03, UV.y) * smoothstep(1.0, 0.9, UV.y);
	ALBEDO = c * energy * body * bands * streaks * ends * fade;
}
