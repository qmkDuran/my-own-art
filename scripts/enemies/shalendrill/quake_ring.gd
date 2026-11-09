class_name QuakeRing
extends GroundRing
## A ring of cracking ground rolling out from the Shalendrill's slam (see GroundRing). Unlike
## the Captain's ShockRing it has no gap: the only way through is a dodge (invulnerable
## mid-leap) or staying beyond its reach. Bits of broken ground fly up along it.

## Straight segments the ring is drawn with.
const ARC_POINTS := 64
## The band's alpha at full strength.
const BAND_ALPHA := 0.8
## Rubble specks along the band, one every this many radians.
const RUBBLE_STEP := 0.21
## How fast the rubble pattern turns as the ring grows, in radians per pixel of radius.
const RUBBLE_DRIFT := 0.05
const RUBBLE_SIZE := Vector2(2, 1)

var rubble_color: Color = ApolloPalette.STONE_LIGHT


## Adds a ring to `world` at `at` (world coordinates) and sets it rolling.
static func spawn(world: Node, at: Vector2) -> QuakeRing:
	var ring := QuakeRing.new()
	GroundRing.place(ring, world, at)
	return ring


func _init() -> void:
	max_radius = 104.0
	travel_time = 1.0
	band_width = 6.0
	push_speed = 160.0
	push_time = 0.2


func _is_safe_at(_from_centre: Vector2) -> bool:
	return false


func _draw_ring(radius: float, fade: float) -> void:
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, ARC_POINTS, Color(color, BAND_ALPHA * fade), band_width)
	draw_arc(Vector2.ZERO, radius + band_width / 2.0, 0.0, TAU, ARC_POINTS, Color(edge_color, fade), 1.0)
	var angle := fmod(radius * RUBBLE_DRIFT, RUBBLE_STEP)
	while angle < TAU:
		var spot := (Vector2.from_angle(angle) * (radius - 1.0)).floor()
		draw_rect(Rect2(spot, RUBBLE_SIZE), Color(rubble_color, fade))
		angle += RUBBLE_STEP
