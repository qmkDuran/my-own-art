// A soft teardrop flame for the flame wisp: the mesh (a sphere) is drawn out into a tail behind the direction of
// flight (+z) and tapers; colour runs from warm amber in the middle through orange to a deep red, fading edge
// (seen from any side), with a gentle flicker. Additive, colour kept below white (the soft glow rule).
shader_type spatial;
render_mode unshaded, blend_add, cull_back, depth_draw_never;

uniform vec3 core_color : source_color = vec3(1.0, 0.6, 0.2);
uniform vec3 mid_color : source_color = vec3(1.0, 0.45, 0.12);
uniform vec3 edge_color : source_color = vec3(0.6, 0.1, 0.03);
uniform float tail = 2.6;
uniform float energy = 0.9;
uniform float flicker = 0.15;

void vertex() {
	if (VERTEX.z > 0.0) {
		float back = VERTEX.z * tail;
		float taper = 1.0 - clamp(back / (tail * 0.5 + 0.001), 0.0, 1.0) * 0.85;
		VERTEX = vec3(VERTEX.x * taper, VERTEX.y * taper + sin(TIME * 9.0 + back * 6.0) * 0.04 * back, back);
	}
}

void fragment() {
	float facing = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	vec3 colour = mix(edge_color, mid_color, smoothstep(0.0, 0.5, facing));
	colour = mix(colour, core_color, smoothstep(0.5, 1.0, facing));
	float pulse = 1.0 + sin(TIME * 23.0) * flicker * 0.6 + sin(TIME * 37.0) * flicker * 0.4;
	ALBEDO = colour * energy * pulse * smoothstep(0.0, 0.35, facing);
}
