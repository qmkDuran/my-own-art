class_name TelegraphPainter
extends RefCounted
## Draws the Captain's ground telegraphs (the slam's ring with its gap, the sweep's wedge)
## so they read at a glance in a busy fight: a faint filled danger zone, a bold 2px outline
## that pulses gently, and bright end-caps marking the edges of a safe gap.
##
## Colours follow the visual hierarchy (DESIGN.md): danger cues are the brightest thing after
## the player, so outlines use the light reds and the safe gap a contrasting gold.

## How often a telegraph's outline pulses, per second (gentle, not a strobe).
const PULSE_HZ := 3.0
## Outline width, in pixels.
const OUTLINE_WIDTH := 2.0
## Widest slice of a filled wedge, so each polygon stays convex.
const MAX_SLICE := PI / 4.0
## Points per radian along arcs (about one every 4 pixels on the slam's ring).
const POINTS_PER_RADIAN := 8.0
## How far a gap's end-cap reaches inside and outside the ring, in pixels.
const CAP_REACH := 5.0
## Spacing of the dots across a gap, in pixels.
const GAP_DOT_SPACING := 6.0

const DANGER_COLOR := ApolloPalette.RED
const DANGER_BRIGHT_COLOR := ApolloPalette.RED_LIGHT
const SAFE_GAP_COLOR := ApolloPalette.GOLD


## 0..1, rising and falling PULSE_HZ times a second.
static func pulse(seconds: float) -> float:
	return 0.5 + 0.5 * sin(TAU * PULSE_HZ * seconds)


## The outline colour for a telegraph `pulse` (0..1) through its pulse, at `alpha`.
static func outline_color(pulse_amount: float, alpha: float) -> Color:
	return Color(DANGER_COLOR.lerp(DANGER_BRIGHT_COLOR, pulse_amount), alpha)


## A filled pie slice from `from_angle` to `to_angle` (radians, any width up to a full turn).
static func fill_wedge(canvas: CanvasItem, centre: Vector2, radius: float, from_angle: float, to_angle: float, color: Color) -> void:
	var slices := maxi(1, ceili((to_angle - from_angle) / MAX_SLICE))
	var slice := (to_angle - from_angle) / slices
	for index in slices:
		var start := from_angle + slice * index
		var points := PackedVector2Array([centre])
		var steps := maxi(2, ceili(slice * POINTS_PER_RADIAN))
		for step in steps + 1:
			points.append(centre + Vector2.from_angle(start + slice * step / steps) * radius)
		canvas.draw_colored_polygon(points, color)


## A ring with one gap facing `gap_angle`, `gap_width` radians wide.
static func draw_gapped_ring(canvas: CanvasItem, centre: Vector2, radius: float, gap_angle: float, gap_width: float, color: Color, width: float) -> void:
	var from := gap_angle + gap_width / 2.0
	var to := gap_angle + TAU - gap_width / 2.0
	canvas.draw_arc(centre, radius, from, to, _arc_points(to - from), color, width)


## Bright radial bars at both edges of the gap, and a dotted line across it, so the safe
## way through stands out from the red.
static func draw_gap_marks(canvas: CanvasItem, centre: Vector2, radius: float, gap_angle: float, gap_width: float, alpha: float) -> void:
	var cap_color := Color(SAFE_GAP_COLOR, alpha)
	for edge: float in [gap_angle - gap_width / 2.0, gap_angle + gap_width / 2.0]:
		var outward := Vector2.from_angle(edge)
		canvas.draw_line(centre + outward * (radius - CAP_REACH), centre + outward * (radius + CAP_REACH), cap_color, OUTLINE_WIDTH)
	var dot_count := floori(radius * gap_width / GAP_DOT_SPACING)
	var dot_color := Color(SAFE_GAP_COLOR, alpha * 0.6)
	for dot in range(1, dot_count):
		var angle := gap_angle - gap_width / 2.0 + gap_width * dot / dot_count
		canvas.draw_rect(Rect2((centre + Vector2.from_angle(angle) * radius).floor(), Vector2.ONE), dot_color)


static func _arc_points(angle: float) -> int:
	return maxi(8, ceili(angle * POINTS_PER_RADIAN))
