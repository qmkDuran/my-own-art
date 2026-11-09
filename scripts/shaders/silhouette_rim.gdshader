// Silhouette rim: fills every see-through pixel that has an opaque neighbour (up, down,
// left or right) with one flat colour, so a sprite gets a 1px outer rim. Drawn by
// SilhouetteRim over the frame grown by 1px on each side; pixels outside the frame count
// as see-through, so neighbouring frames on the sheet never bleed in.
shader_type canvas_item;

uniform vec4 rim_color : source_color;
// The frame's rectangle on the sheet, in UV: (x, y, width, height).
uniform vec4 frame_region;

// The node's modulate, kept so fades and tints reach the rim too.
varying vec4 modulate;

void vertex() {
	modulate = COLOR;
}

float alpha_at(sampler2D sheet, vec2 uv) {
	bool inside = all(greaterThanEqual(uv, frame_region.xy)) && all(lessThan(uv, frame_region.xy + frame_region.zw));
	return inside ? texture(sheet, uv).a : 0.0;
}

void fragment() {
	vec2 step_x = vec2(TEXTURE_PIXEL_SIZE.x, 0.0);
	vec2 step_y = vec2(0.0, TEXTURE_PIXEL_SIZE.y);
	float neighbour = max(
		max(alpha_at(TEXTURE, UV + step_x), alpha_at(TEXTURE, UV - step_x)),
		max(alpha_at(TEXTURE, UV + step_y), alpha_at(TEXTURE, UV - step_y))
	);
	bool is_rim = alpha_at(TEXTURE, UV) < 0.5 && neighbour >= 0.5;
	COLOR = vec4(rim_color.rgb, is_rim ? 1.0 : 0.0) * modulate;
}
