// A soft expanding ring on the ground (the pure-Godot impact shockwave): progress 0..1 grows the ring and fades it.
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;

uniform vec3 color : source_color = vec3(1.0, 0.6, 0.25);
uniform float progress = 0.0;
uniform float thickness = 0.12;
uniform float energy = 1.2;

void fragment() {
	float d = length(UV - 0.5) * 2.0;
	float radius = 0.15 + progress * 0.8;
	float ring = smoothstep(thickness, 0.0, abs(d - radius));
	float fade = pow(clamp(1.0 - progress, 0.0, 1.0), 1.5);
	ALBEDO = color * ring * fade * energy;
}
