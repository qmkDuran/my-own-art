class_name IconGlyphs
## Tiny line drawings for the move icons: jaws (bite), a droplet (spit), a curling arrow (roll), a toothed ring
## (snare). Each is a function (canvas, centre, size, colour, width); proportions are shares of `size`.

const ARC_POINTS: int = 20
const JAW_POINTS: int = 5
const JAW_GUM: float = 0.55
const JAW_TIP: float = 0.05
const DROP_BULB_DROP: float = 0.35
const DROP_BULB: float = 0.6
const DROP_OPEN: float = 0.15
const ROLL_RADIUS: float = 0.8
const ROLL_GAP: float = 0.2
const ROLL_HEAD_LONG: float = 0.45
const ROLL_HEAD_SHORT: float = 0.05
const SNARE_TEETH: int = 8
const SNARE_RING: float = 0.7
const SNARE_TOOTH_END: float = 0.35


static func for_move(title: String) -> Callable:
	match title:
		"Bite":
			return jaws
		"Spit":
			return droplet
		"Roll":
			return roll
	return snare


static func jaws(canvas: CanvasItem, centre: Vector2, size: float, color: Color, width: float) -> void:
	for side: float in [-1.0, 1.0]:
		var gum: float = centre.y + side * size * JAW_GUM
		var tips: float = centre.y + side * size * JAW_TIP
		var points := PackedVector2Array()
		for k: int in JAW_POINTS:
			var x: float = centre.x - size + k * size * 2.0 / (JAW_POINTS - 1)
			points.append(Vector2(x, gum if k % 2 == 0 else tips))
		canvas.draw_polyline(points, color, width)


static func droplet(canvas: CanvasItem, centre: Vector2, size: float, color: Color, width: float) -> void:
	var bulb: Vector2 = centre + Vector2(0, size * DROP_BULB_DROP)
	var radius: float = size * DROP_BULB
	var left: float = PI + PI * DROP_OPEN
	var right: float = -PI * DROP_OPEN
	canvas.draw_arc(bulb, radius, right, left, ARC_POINTS, color, width)
	var top: Vector2 = centre - Vector2(0, size)
	canvas.draw_line(bulb + Vector2.from_angle(right) * radius, top, color, width)
	canvas.draw_line(bulb + Vector2.from_angle(left) * radius, top, color, width)


static func roll(canvas: CanvasItem, centre: Vector2, size: float, color: Color, width: float) -> void:
	var radius: float = size * ROLL_RADIUS
	canvas.draw_arc(centre, radius, PI * ROLL_GAP, TAU - PI * ROLL_GAP, ARC_POINTS, color, width)
	var tip: Vector2 = centre + Vector2.from_angle(PI * ROLL_GAP) * radius
	canvas.draw_line(tip, tip + Vector2(-ROLL_HEAD_LONG, -ROLL_HEAD_SHORT) * size, color, width)
	canvas.draw_line(tip, tip + Vector2(ROLL_HEAD_SHORT, ROLL_HEAD_LONG) * size, color, width)


static func snare(canvas: CanvasItem, centre: Vector2, size: float, color: Color, width: float) -> void:
	canvas.draw_arc(centre, size * SNARE_RING, 0.0, TAU, ARC_POINTS, color, width)
	for k: int in SNARE_TEETH:
		var direction: Vector2 = Vector2.from_angle(TAU * k / SNARE_TEETH)
		var outer: Vector2 = centre + direction * size * SNARE_RING
		canvas.draw_line(outer, centre + direction * size * SNARE_TOOTH_END, color, width)
