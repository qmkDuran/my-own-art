// Foliage that sways in the wind: tree crowns, tall grass, ferns and flowers. Colour comes from the vertex and
// instance colours (multimesh); the sway grows with height above the mesh origin and drifts across the woods.
shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_disabled;

uniform float sway_strength = 0.06;
uniform float sway_speed = 1.6;
uniform float sway_height = 1.0;

void vertex() {
	vec3 world = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float phase = TIME * sway_speed + world.x * 0.21 + world.z * 0.17;
	float lift = clamp(VERTEX.y / sway_height, 0.0, 1.0);
	VERTEX.x += sin(phase) * sway_strength * lift;
	VERTEX.z += cos(phase * 0.83) * sway_strength * lift;
}

void fragment() {
	ALBEDO = COLOR.rgb;
	ROUGHNESS = 1.0;
}
