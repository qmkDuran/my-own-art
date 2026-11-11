class_name MoveIcon
extends RefCounted
## Code-drawn move icons in a move's element colours (slash, dash, burst, bolt, fan, spin, shield, star), with the
## cooldown shown as a dark shutter and the seconds left, and the key under it.

const RAYS: int = 8
const STAR_POINTS: int = 5


static func draw_slot(ci: CanvasItem, r: Rect2, move_id: String, element: String, key: String, cd_frac: float,
		cd_left: float, locked: bool = false) -> void:
	var m: Dictionary = TamerData.move(move_id)
	UiDraw.box(ci, r, UiDraw.PANEL_DEEP, TamerData.color(element, "dark") if not locked else UiDraw.LOCKED)
	var col: Color = TamerData.color(element, "core") if not locked else UiDraw.LOCKED
	var hi: Color = TamerData.color(element, "light") if not locked else UiDraw.LOCKED
	glyph(ci, r.grow(-4.0), String(m.get("icon", "slash")), col, hi)
	if cd_frac > 0.0:
		ci.draw_rect(Rect2(r.position, Vector2(r.size.x, r.size.y * cd_frac)), Color(0, 0, 0, 0.6))
		UiDraw.text(ci, r.position + Vector2(0, r.size.y * 0.5 + 4.0), "%.0f" % ceilf(cd_left), UiDraw.TEXT, UiDraw.SMALL,
			HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	UiDraw.text(ci, r.position + Vector2(2, r.size.y + 9.0), key, UiDraw.DIM, UiDraw.SMALL)


static func glyph(ci: CanvasItem, r: Rect2, kind: String, col: Color, hi: Color) -> void:
	var c: Vector2 = r.get_center()
	var s: float = r.size.x * 0.5
	match kind:
		"slash":
			for k: int in 3:
				var o: float = (k - 1) * s * 0.45
				ci.draw_line(c + Vector2(-s * 0.7 + o, s * 0.7), c + Vector2(s * 0.5 + o, -s * 0.8), col if k != 1 else hi, 2.0)
		"dash":
			ci.draw_line(c + Vector2(-s, 0), c + Vector2(s * 0.6, 0), col, 3.0)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(s, 0), c + Vector2(s * 0.3, -s * 0.6), c + Vector2(s * 0.3, s * 0.6)]), hi)
			ci.draw_line(c + Vector2(-s, -s * 0.5), c + Vector2(-s * 0.2, -s * 0.5), col, 1.0)
		"burst":
			for k: int in RAYS:
				var d := Vector2.RIGHT.rotated(TAU * k / RAYS)
				ci.draw_line(c + d * s * 0.35, c + d * s, col, 2.0)
			ci.draw_circle(c, s * 0.35, hi)
		"bolt":
			ci.draw_line(c + Vector2(-s, s * 0.4), c + Vector2(s * 0.2, -s * 0.1), col, 3.0)
			ci.draw_circle(c + Vector2(s * 0.35, -s * 0.2), s * 0.45, col)
			ci.draw_circle(c + Vector2(s * 0.35, -s * 0.2), s * 0.22, hi)
		"fan":
			for k: int in 3:
				var d := Vector2.RIGHT.rotated(deg_to_rad(-30.0 + 30.0 * k))
				ci.draw_line(c - Vector2(s * 0.8, 0), c - Vector2(s * 0.8, 0) + d * s * 1.7, col, 2.0)
				ci.draw_circle(c - Vector2(s * 0.8, 0) + d * s * 1.7, 2.0, hi)
		"spin":
			ci.draw_arc(c, s * 0.8, 0.0, PI * 1.4, 16, col, 2.0)
			ci.draw_arc(c, s * 0.45, PI, PI * 2.4, 12, hi, 2.0)
		"shield":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.8, -s * 0.8), c + Vector2(s * 0.8, -s * 0.8),
				c + Vector2(s * 0.7, s * 0.2), c + Vector2(0, s), c + Vector2(-s * 0.7, s * 0.2)]), col)
			ci.draw_line(c + Vector2(0, -s * 0.6), c + Vector2(0, s * 0.6), hi, 2.0)
		_:
			var pts := PackedVector2Array()
			for k: int in STAR_POINTS * 2:
				var rr: float = s if k % 2 == 0 else s * 0.45
				pts.append(c + Vector2.UP.rotated(PI * k / STAR_POINTS) * rr)
			ci.draw_colored_polygon(pts, col)
			ci.draw_circle(c, s * 0.25, hi)
