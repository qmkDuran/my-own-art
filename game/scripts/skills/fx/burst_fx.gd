class_name BurstFx
extends Node2D
## Flare's burst: a ring of sunfire racing outward with rays, or (Lancet) a fan of light toward the cursor.
## Additive and unlit; the ground and enemies around it are lit by a flash light at the same time.

const TIME: float = 0.32
const RAYS: int = 18
const CONE_RAYS: int = 9

var radius: float
var dir: Vector2 = Vector2.ZERO      ## non-zero: a cone of `arc` radians
var arc: float = 0.0
var _t: float = 0.0


static func spawn(parent: Node, at: Vector2, r: float, cone_dir: Vector2 = Vector2.ZERO, cone_arc: float = 0.0) -> BurstFx:
	var b := BurstFx.new()
	b.position = at
	b.radius = r
	b.dir = cone_dir
	b.arc = cone_arc
	b.material = Fx.glow_material()
	b.z_index = Fx.FX_Z
	parent.add_child(b)
	return b


func _process(delta: float) -> void:
	_t += delta
	if _t > TIME:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var k: float = _t / TIME
	var e: float = 1.0 - pow(1.0 - k, 3.0)
	var fade: float = 1.0 - k
	var r: float = radius * e
	if dir == Vector2.ZERO:
		draw_circle(Vector2.ZERO, r, Color(Pal.c("amber"), 0.18 * fade))
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 64, Color(Pal.c("flame"), 0.5 * fade), 6.0)
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 64, Color(Pal.c("sun"), fade), 2.0)
		for i: int in RAYS:
			var a: float = TAU * i / RAYS + k * 0.4
			draw_line(Vector2.RIGHT.rotated(a) * r * 0.35, Vector2.RIGHT.rotated(a) * r, Color(Pal.c("gold"), 0.5 * fade), 1.0)
		return
	var a0: float = dir.angle() - arc * 0.5
	var pts := PackedVector2Array([Vector2.ZERO])
	for i: int in CONE_RAYS + 1:
		pts.append(Vector2.RIGHT.rotated(a0 + arc * i / CONE_RAYS) * r)
	draw_colored_polygon(pts, Color(Pal.c("amber"), 0.28 * fade))
	for i: int in CONE_RAYS + 1:
		draw_line(Vector2.ZERO, Vector2.RIGHT.rotated(a0 + arc * i / CONE_RAYS) * r, Color(Pal.c("sun"), 0.7 * fade), 1.0)
	draw_arc(Vector2.ZERO, r, a0, a0 + arc, 24, Color(Pal.c("sun"), fade), 3.0)
