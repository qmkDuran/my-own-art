class_name ShockRing
extends GroundRing
## The Captain's slam shockwave (see GroundRing): a thick ring with one gap in it, the gap's
## edges marked in gold like the slam's telegraph. Standing in the gap is safe.

## Straight segments the ring is drawn with.
const ARC_POINTS := 48
## The band's alpha at full strength.
const BAND_ALPHA := 0.85

## Direction (radians) the gap faces, and its width.
var gap_angle: float = 0.0
var gap_width: float = deg_to_rad(50.0)


## Adds a ring to `world` at `at` (world coordinates), its gap facing `gap_facing`, and sets it rolling.
static func spawn(world: Node, at: Vector2, gap_facing: float) -> ShockRing:
	var ring := ShockRing.new()
	ring.gap_angle = gap_facing
	GroundRing.place(ring, world, at)
	return ring


func _init() -> void:
	slowing_power = 1.6


func _is_safe_at(from_centre: Vector2) -> bool:
	return absf(angle_difference(from_centre.angle(), gap_angle)) <= gap_width / 2.0


func _draw_ring(radius: float, fade: float) -> void:
	var from := gap_angle + gap_width / 2.0
	var to := gap_angle + TAU - gap_width / 2.0
	draw_arc(Vector2.ZERO, radius, from, to, ARC_POINTS, Color(color, BAND_ALPHA * fade), band_width)
	draw_arc(Vector2.ZERO, radius + band_width / 2.0, from, to, ARC_POINTS, Color(edge_color, fade), 1.0)
	TelegraphPainter.draw_gap_marks(self, Vector2.ZERO, radius, gap_angle, gap_width, fade)
