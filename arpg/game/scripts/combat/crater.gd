class_name Crater
extends Node2D
## A scorched dent in the ground where Michael lands; fades away over a few seconds.

const LIFE: float = 4.0

var radius: float = 40.0
var _t: float = 0.0


func _ready() -> void:
	z_index = -15


func _process(delta: float) -> void:
	_t += delta
	if _t > LIFE:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var a: float = 1.0 - _t / LIFE
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.5))
	draw_circle(Vector2.ZERO, radius, Color(0.08, 0.06, 0.1, 0.55 * a))
	draw_circle(Vector2.ZERO, radius * 0.6, Color(0.05, 0.04, 0.07, 0.6 * a))
	for i: int in 8:
		var ang: float = TAU * i / 8.0 + 0.3
		draw_line(Vector2(cos(ang), sin(ang)) * radius * 0.5, Vector2(cos(ang), sin(ang)) * radius * 1.15, Color(0.05, 0.04, 0.07, 0.7 * a), 2.0)
