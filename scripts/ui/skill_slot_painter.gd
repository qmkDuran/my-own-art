class_name SkillSlotPainter
extends RefCounted
## Draws the fixed parts of a SkillSlot: its stone frame and two-tone inside, the glint of a
## "used" flash, the dotted cooldown veil and the seconds left. The slot decides what to draw
## and when; the icon, the Heat badge and the flashes' border are drawn by their own helpers.

const INNER := SkillSlot.INNER
const SLOT_SIZE := SkillSlot.SLOT_SIZE
## Top of the cooldown seconds (centred in the slot both ways, clear of the Heat badge below).
const SECONDS_TOP := 8


## The stone frame (with a gold top edge while usable), then a two-tone inside.
static func draw_frame(slot: Control, is_usable: bool) -> void:
	PixelShape.draw_stone_frame(slot, SLOT_SIZE)
	if is_usable:
		slot.draw_rect(Rect2(0, 0, SLOT_SIZE - 1, 1), HudPalette.READY_EDGE)
	var inner := Rect2(INNER)
	var top_half := Rect2(inner.position, Vector2(inner.size.x, floorf(inner.size.y / 2.0)))
	slot.draw_rect(inner, HudPalette.WELL)
	slot.draw_rect(top_half, HudPalette.WELL_TOP)


## First frame of the "used" flash: a bright line along the inside top and left edges.
static func draw_inner_glint(slot: Control) -> void:
	slot.draw_rect(Rect2(INNER.position.x, INNER.position.y, INNER.size.x, 1), HudPalette.WELL_GLINT)
	slot.draw_rect(Rect2(INNER.position.x, INNER.position.y, 1, INNER.size.y), HudPalette.WELL_GLINT)


## A dotted veil over the share still recovering (`fraction_left`), with a sky-blue line on
## its edge. The dots line up with the screen's pixel grid wherever the slot sits.
static func draw_cooldown_veil(slot: Control, fraction_left: float) -> void:
	var veil_rows := roundi(INNER.size.y * fraction_left)
	var edge_row := mini(INNER.position.y + veil_rows, INNER.end.y - 1)
	var parity := roundi(slot.global_position.x + slot.global_position.y)
	for y in range(INNER.position.y, edge_row):
		for x in range(INNER.position.x, INNER.end.x):
			if (x + y + parity) % 2 == 0:
				PixelShape.draw_pixel(slot, Vector2(x, y), ApolloPalette.NIGHT)
	slot.draw_rect(Rect2(INNER.position.x, edge_row, INNER.size.x, 1), ApolloPalette.SKY)


static func draw_seconds_left(slot: Control, seconds_left: float) -> void:
	var seconds := str(ceili(seconds_left))
	var left := floori((SLOT_SIZE - PixelFont.width_of(seconds)) / 2.0)
	PixelFont.draw_text(slot, seconds, Vector2(left, SECONDS_TOP), ApolloPalette.WHITE, ApolloPalette.OUTLINE)
