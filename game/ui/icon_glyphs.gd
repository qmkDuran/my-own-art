class_name IconGlyphs
## Tiny line drawings for the move icons, one per kind of move: jaws (strike), a droplet (shot), a burst (area), an
## arc arrow (movement), a shield (defence), chevrons up / down (buff / debuff), an eye (sense), a sprout (terrain),
## and a curling arrow for the roll. Each is a function (canvas, centre, size, colour, width); proportions are shares
## of `size`.

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
const BURST_RAYS: int = 8
const BURST_INNER: float = 0.3
const BURST_OUTER: float = 0.85
const SHIELD_WIDTH: float = 0.7
const CHEVRON_GAP: float = 0.45
const CHEVRON_WIDE: float = 0.7
const CHEVRON_TALL: float = 0.35
const EYE_HEIGHT: float = 0.45
const PUPIL: float = 0.22
const LEAF: float = 0.45
const LEAP_FROM: float = 1.15
const LEAP_TO: float = 1.85
## The eye's lids span this share short of a half turn.
const LID: float = 0.2
const BY_CATEGORY: Dictionary = { "attack": "jaws", "movement": "leap", "defensive": "shield", "buff": "buff",
	"debuff": "debuff", "sense": "eye", "terrain": "sprout" }


static func for_move(move: Move) -> Callable:
	if move.role() == "ranged":
		return droplet
	if move.role() == "area":
		return burst
	return Callable(IconGlyphs, BY_CATEGORY[move.category()])


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


static func burst(canvas: CanvasItem, centre: Vector2, size: float, color: Color, width: float) -> void:
	for k: int in BURST_RAYS:
		var direction: Vector2 = Vector2.from_angle(TAU * k / BURST_RAYS)
		canvas.draw_line(centre + direction * size * BURST_INNER, centre + direction * size * BURST_OUTER, color, width)


static func leap(canvas: CanvasItem, centre: Vector2, size: float, color: Color, width: float) -> void:
	var hub: Vector2 = centre + Vector2(0, size * 0.5)
	canvas.draw_arc(hub, size, PI * LEAP_FROM, PI * LEAP_TO, ARC_POINTS, color, width)
	var tip: Vector2 = hub + Vector2.from_angle(PI * LEAP_TO) * size
	canvas.draw_line(tip, tip + Vector2(-ROLL_HEAD_LONG, 0) * size, color, width)
	canvas.draw_line(tip, tip + Vector2(0, ROLL_HEAD_LONG) * size, color, width)


static func shield(canvas: CanvasItem, centre: Vector2, size: float, color: Color, width: float) -> void:
	var half: float = size * SHIELD_WIDTH
	canvas.draw_polyline(PackedVector2Array([centre + Vector2(-half, -size), centre + Vector2(half, -size),
		centre + Vector2(half, 0), centre + Vector2(0, size), centre + Vector2(-half, 0),
		centre + Vector2(-half, -size)]), color, width)


static func buff(canvas: CanvasItem, centre: Vector2, size: float, color: Color, width: float) -> void:
	_chevrons(canvas, centre, size, color, width, -1.0)


static func debuff(canvas: CanvasItem, centre: Vector2, size: float, color: Color, width: float) -> void:
	_chevrons(canvas, centre, size, color, width, 1.0)


static func eye(canvas: CanvasItem, centre: Vector2, size: float, color: Color, width: float) -> void:
	canvas.draw_arc(centre + Vector2(0, size * EYE_HEIGHT), size, PI * (1.0 + LID), PI * (2.0 - LID), ARC_POINTS, color,
			width)
	canvas.draw_arc(centre - Vector2(0, size * EYE_HEIGHT), size, PI * LID, PI * (1.0 - LID), ARC_POINTS, color, width)
	canvas.draw_circle(centre, size * PUPIL, color)


static func sprout(canvas: CanvasItem, centre: Vector2, size: float, color: Color, width: float) -> void:
	canvas.draw_line(centre + Vector2(0, size), centre - Vector2(0, size * LEAF), color, width)
	var leaf: float = size * LEAF
	canvas.draw_arc(centre + Vector2(-leaf, -leaf), leaf, -PI * 0.5, PI * 0.5, ARC_POINTS, color, width)
	canvas.draw_arc(centre + Vector2(leaf, 0), leaf, PI * 0.5, PI * (1.0 + 0.5), ARC_POINTS, color, width)


## Two chevrons pointing up (direction -1) or down (+1).
static func _chevrons(canvas: CanvasItem, centre: Vector2, size: float, color: Color, width: float,
		direction: float) -> void:
	for k: int in 2:
		var middle: Vector2 = centre + Vector2(0, (k - 0.5) * size * CHEVRON_GAP * 2.0)
		var tip: Vector2 = middle + Vector2(0, direction * size * CHEVRON_TALL)
		canvas.draw_polyline(PackedVector2Array([middle + Vector2(-size * CHEVRON_WIDE, 0), tip,
			middle + Vector2(size * CHEVRON_WIDE, 0)]), color, width)
