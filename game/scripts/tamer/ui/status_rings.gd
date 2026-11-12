class_name StatusRings
extends RefCounted
## The one visual language for a creature's state, drawn on the ground at its feet: a gold ring with rising arrows
## while it has a buff, a purple ring with sinking arrows while it has a debuff, and a circle that fills while it
## channels a status move (gold when full).

const SQUASH: float = 0.45              ## rings lie on the ground (seen at an angle)
const RING_SIZE: float = 1.6            ## times the body radius: wide enough to show around the feet
const ARROWS: int = 3
const ARROW: float = 4.0
const RISE: float = 10.0


static func draw_for(ci: CanvasItem, c: Creature) -> void:
	var r: float = c.hit_radius() * RING_SIZE
	var t: float = Time.get_ticks_msec() / 1000.0
	if c.effects.of_kind("debuff") != "":
		_ring(ci, r + 4.0, Pal.c("violet_lt"), t, -1.0)
	if c.effects.of_kind("buff") != "":
		_ring(ci, r, Pal.c("sun"), t, 1.0)
	if c.channel_id != "":
		_fill(ci, r, c.channel_strength())


## A ring on the ground and arrows drifting up (buff) or down (debuff) around it.
static func _ring(ci: CanvasItem, r: float, col: Color, t: float, up: float) -> void:
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, SQUASH))
	ci.draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, Color(UiDraw.INK, 0.6), 4.0)
	ci.draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, col, 2.0)
	ci.draw_set_transform(Vector2.ZERO)
	for k: int in ARROWS:
		var a: float = TAU * k / ARROWS + t * 0.8
		var phase: float = fmod(t * 1.2 + k * 0.33, 1.0)
		var at := Vector2(cos(a) * r, sin(a) * r * SQUASH - phase * RISE * up - (RISE if up < 0.0 else 0.0))
		var tip := Vector2(0, -ARROW * up)
		var fade := Color(col, 1.0 - phase)
		ci.draw_colored_polygon(PackedVector2Array([at + tip, at + Vector2(-ARROW, ARROW * up * 0.4), at + Vector2(ARROW, ARROW * up * 0.4)]), fade)


## A disc that fills like a clock as the channel builds.
static func _fill(ci: CanvasItem, r: float, s: float) -> void:
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, SQUASH))
	ci.draw_circle(Vector2.ZERO, r, Color(UiDraw.INK, 0.45))
	var pts := PackedVector2Array([Vector2.ZERO])
	var steps: int = maxi(2, int(32 * s))
	for k: int in steps + 1:
		var a: float = -PI * 0.5 + TAU * s * k / steps
		pts.append(Vector2(cos(a), sin(a)) * r)
	ci.draw_colored_polygon(pts, Pal.c("sun", 0.8) if s >= 1.0 else Pal.c("glint", 0.6))
	ci.draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, Pal.c("glint"), 1.5)
	ci.draw_set_transform(Vector2.ZERO)
