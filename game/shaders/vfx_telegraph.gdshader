// An enemy attack's warning on the ground: a soft magenta-violet rim around the danger area, a fill that grows
// from the centre (a circle) or from the caster's end (a line) as the attack winds up, gentle pulsing stripes, and
// a bright edge on the fill front. When it lands, flash fades in and out. Additive, colour kept out of white.
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec3 rim_color : source_color = vec3(1.0, 0.35, 0.6);
uniform vec3 fill_color : source_color = vec3(0.75, 0.25, 0.9);
uniform int shape = 0; // 0 circle, 1 line (UV.y runs from the caster (0) to the far end (1))
uniform float progress = 0.0;
uniform float flash = 0.0;
uniform float energy = 1.0;
uniform float rim_width = 0.05;

void fragment() {
	float edge;
	float along;
	if (shape == 0) {
		float d = length(UV - 0.5) * 2.0;
		edge = 1.0 - d;
		along = d;
	} else {
		edge = min(min(UV.x, 1.0 - UV.x) * 2.0, min(UV.y, 1.0 - UV.y) * 8.0);
		along = UV.y;
	}
	float inside = step(0.0, edge);
	float rim = smoothstep(rim_width * 2.0, 0.0, edge) * inside;
	float filled = step(along, progress) * inside;
	float front = smoothstep(0.06, 0.0, abs(along - progress)) * inside * step(progress, 0.999);
	float stripes = 0.5 + 0.5 * sin((along * 18.0 - TIME * 6.0));
	vec3 c = rim_color * rim * (0.7 + 0.3 * stripes);
	c += fill_color * filled * (0.13 + 0.07 * stripes);
	c += rim_color * front * 0.8;
	c += fill_color * inside * 0.04;
	c += rim_color * inside * flash * 0.9;
	ALBEDO = c * energy;
}
