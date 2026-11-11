shader_type canvas_item;
// A HUD orb: liquid in a glass ball. Pixel-quantised to the HUD's scale so it keeps the pixel look.
// Liquid: a vertical gradient (deep at the bottom, bright just under the surface), a soft radial glow with no edge,
// a bright meniscus on the wavy surface, a few slow rising bubbles; above it, the ghost of what was just lost; then
// a curved glass highlight and a faint inner rim shadow.

uniform float fill = 1.0;
uniform float ghost = 1.0;            // the level a moment ago (damage taken trails behind)
uniform float time = 0.0;
uniform float pixel = 54.0;           // pixels across the orb (quantise to these)
uniform vec4 deep : source_color;
uniform vec4 mid : source_color;
uniform vec4 bright : source_color;
uniform vec4 glass : source_color = vec4(0.05, 0.04, 0.07, 1.0);

float h(float n) { return fract(sin(n * 91.7) * 43758.5); }

void fragment() {
	vec2 uv = (floor(UV * pixel) + 0.5) / pixel;
	vec2 d = uv - 0.5;
	float r = length(d) * 2.0;
	if (r > 1.0) { discard; }
	float y = 1.0 - uv.y;                                      // 0 at the bottom, 1 at the top
	float wave = sin(time * 2.2 + uv.x * 14.0) * 0.012 + sin(time * 1.3 - uv.x * 9.0) * 0.008;
	float surface = fill + wave;
	vec3 col = glass.rgb;
	if (y < ghost + wave && y >= surface) {
		col = mix(glass.rgb, bright.rgb, 0.28);                // the ghost of the life just lost
	}
	if (y < surface) {
		float k = clamp(y / max(surface, 0.001), 0.0, 1.0);
		col = mix(deep.rgb, mid.rgb, smoothstep(0.0, 0.75, k));
		col = mix(col, bright.rgb, smoothstep(0.7, 1.0, k) * 0.6);
		float glow = 1.0 - smoothstep(0.0, 0.85, length(d - vec2(0.0, 0.08)) * 2.0);
		col += bright.rgb * glow * 0.22;
		if (surface - y < 1.6 / pixel) { col = mix(col, vec3(1.0, 0.96, 0.86), 0.55); }   // the meniscus
		for (int b = 0; b < 4; b++) {                                 // slow rising bubbles
			float fb = float(b);
			float bx = 0.28 + 0.44 * h(fb + 1.0);
			float by = fract(time * (0.05 + 0.03 * h(fb + 7.0)) + h(fb + 3.0)) * surface;
			if (length(uv - vec2(bx + sin(time + fb) * 0.02, 1.0 - by)) < 0.028) { col = mix(col, bright.rgb, 0.6); }
		}
	}
	col *= 1.0 - smoothstep(0.78, 1.0, r) * 0.45;                // inner rim shadow
	float hl = smoothstep(0.08, 0.0, abs(length(d - vec2(0.06, 0.06)) * 2.0 - 0.78)) * step(d.x, -0.08) * step(d.y, -0.04);
	col = mix(col, vec3(1.0), hl * 0.35);                          // the curved glass highlight
	COLOR = vec4(col, 1.0);
}
