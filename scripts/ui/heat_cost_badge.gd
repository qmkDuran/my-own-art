class_name HeatCostBadge
extends RefCounted
## The tiny Heat-cost badge in a skill slot's bottom-right corner: a 3×4 flame and the cost.
## The digits are gold while there is enough Heat, red while there isn't.

## 3×4 flame. 'r' red rim, 'o' orange, 'g' gold heart.
const FLAME := [".r.", ".rr", "ror", "rgr"]
const FLAME_COLORS := {"r": ApolloPalette.RED_LIGHT, "o": ApolloPalette.ORANGE, "g": ApolloPalette.GOLD}
const FLAME_SIZE := Vector2i(3, 4)
## Empty pixels between the flame and the number.
const FLAME_GAP := 1

static var _flame_pixels: Dictionary = PixelShape.colored(PixelShape.from_rows(FLAME), FLAME_COLORS)


## Draws the badge so its last pixel sits at `bottom_right` (inclusive). Nothing for a free skill.
static func draw(canvas: CanvasItem, heat_cost: int, has_enough_heat: bool, bottom_right: Vector2i) -> void:
	if heat_cost <= 0:
		return
	var digits := str(heat_cost)
	var digits_left := bottom_right.x + 1 - PixelFont.width_of(digits)
	var digits_top := bottom_right.y + 1 - PixelFont.GLYPH_HEIGHT
	var flame_top_left := Vector2(digits_left - FLAME_GAP - FLAME_SIZE.x, bottom_right.y + 1 - FLAME_SIZE.y)
	PixelShape.draw_outlined(canvas, _flame_pixels, flame_top_left, ApolloPalette.OUTLINE)
	var color := ApolloPalette.GOLD if has_enough_heat else ApolloPalette.RED_LIGHT
	PixelFont.draw_text(canvas, digits, Vector2(digits_left, digits_top), color, ApolloPalette.OUTLINE)
