class_name Telegraph
extends Node2D
## A warning drawn on the ground before a heavy attack lands: a circle or a lane that fills up until it fires.
## Unlit, so it reads in the dark. Frees itself when done; `fired` is emitted at the moment of impact.

signal fired

const FILL_ALPHA: float = 0.28
const EDGE_ALPHA: float = 0.85
const LANE_W: float = 22.0

var radius: float = 40.0
var lane: Vector2 = Vector2.ZERO      ## non-zero: a lane from here to here + lane
var time: float = 1.0
var col: Color = Color("e8505a")
var _t: float = 0.0


static func circle(parent: Node, at: Vector2, r: float, seconds: float) -> Telegraph:
	var t := Telegraph.new()
	t.position = at
	t.radius = r
	t.time = seconds
	parent.add_child(t)
	return t


static func line(parent: Node, at: Vector2, to: Vector2, seconds: float) -> Telegraph:
	var t := Telegraph.new()
	t.position = at
	t.lane = to - at
	t.time = seconds
	parent.add_child(t)
	return t


func _ready() -> void:
	add_to_group("telegraphs")
	z_index = -14
	z_as_relative = false
	material = Fx.unshaded()


## Is a point inside the warned area?
func covers(p: Vector2) -> bool:
	if lane == Vector2.ZERO:
		return p.distance_to(global_position) < radius + 10.0
	var q: Vector2 = Geometry2D.get_closest_point_to_segment(p, global_position, global_position + lane)
	return p.distance_to(q) < LANE_W



func _process(delta: float) -> void:
	_t += delta
	if _t >= time:
		fired.emit()
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k: float = clampf(_t / time, 0.0, 1.0)
	if lane != Vector2.ZERO:
		var n: Vector2 = lane.normalized().orthogonal() * LANE_W * 0.5
		var pts := PackedVector2Array([n, lane + n, lane - n, -n])
		draw_colored_polygon(pts, Color(col, FILL_ALPHA * 0.6))
		var fill := PackedVector2Array([n, lane * k + n, lane * k - n, -n])
		draw_colored_polygon(fill, Color(col, FILL_ALPHA))
		draw_polyline(PackedVector2Array([n, lane + n, lane - n, -n, n]), Color(col, EDGE_ALPHA), 1.0)
		return
	draw_circle(Vector2.ZERO, radius, Color(col, FILL_ALPHA * 0.5))
	draw_circle(Vector2.ZERO, radius * k, Color(col, FILL_ALPHA))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(col, EDGE_ALPHA), 1.0)
