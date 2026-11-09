class_name SlashArc
extends Node2D
## A quick crescent swipe (a bite or a claw), drawn in code in two colours: a bright edge
## and a darker trail, gone in a few frames. Pixel-grid only (no rotation of sprites).

const LIFETIME := 0.1
const STROKES := 3
## Each stroke behind the edge is this many pixels further in.
const STROKE_GAP := 2

var _direction: Vector2 = Vector2.RIGHT
var _radius: float = 12.0
var _arc_degrees: float = 100.0
var _edge: Color = ApolloPalette.WHITE
var _trail: Color = ApolloPalette.SKY
var _age: float = 0.0


static func spawn(world: Node, at: Vector2, direction: Vector2, radius: float, edge: Color, trail: Color) -> void:
	var slash := SlashArc.new()
	slash._direction = direction.normalized()
	slash._radius = radius
	slash._edge = edge
	slash._trail = trail
	slash.z_index = 3
	world.add_child(slash)
	slash.global_position = at.round()


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var progress := _age / LIFETIME
	var half := deg_to_rad(_arc_degrees) / 2.0
	var sweep_end := lerpf(-half, half, minf(1.0, progress * 2.0))
	var centre_angle := _direction.angle()
	for stroke in STROKES:
		var radius := roundf(_radius - stroke * STROKE_GAP)
		var color := _edge if stroke == 0 else _trail
		draw_arc(Vector2.ZERO, radius, centre_angle - half, centre_angle + sweep_end, 10, Color(color, 1.0 - progress), 1.0)
