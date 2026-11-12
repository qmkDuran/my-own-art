class_name EffectIcons
extends RefCounted
## A creature's buffs and debuffs as a row of small icons (effects.json "icon" and "color"): a green frame for a
## buff, a red one for a debuff, the time left as a draining shutter and in seconds. Drawn on the creature card and
## over both creatures in battle (CreatureTag).

const GAP: float = 2.0


## Draws the row from `at` (its top left) and returns its width.
static func draw_row(ci: CanvasItem, at: Vector2, fx: CreatureEffects, size: float, seconds: bool = true) -> float:
	var x: float = 0.0
	for id: String in fx.list:
		var d: Dictionary = CreatureEffects.data(id)
		var e: Dictionary = fx.list[id]
		var r := Rect2(at + Vector2(x, 0), Vector2(size, size))
		var buff: bool = String(d["kind"]) == "buff"
		ci.draw_rect(r, Color(UiDraw.PANEL_DEEP, 0.9))
		var col: Color = Pal.c(String(d["color"]))
		MoveIcon.glyph(ci, r.grow(-2.0), String(d["icon"]), col, col.lightened(0.3))
		var left: float = clampf(float(e["t"]) / maxf(float(e["max"]), 0.01), 0.0, 1.0)
		ci.draw_rect(Rect2(r.position, Vector2(size, size * (1.0 - left))), Color(0, 0, 0, 0.55))
		ci.draw_rect(r, Pal.c("leaf_lt") if buff else Pal.c("rose"), false, 1.0)
		if seconds:
			UiDraw.text(ci, r.position + Vector2(0, size + 8.0), "%d" % ceili(float(e["t"])), UiDraw.TEXT, UiDraw.SMALL,
				HORIZONTAL_ALIGNMENT_CENTER, size)
		x += size + GAP
	return x
