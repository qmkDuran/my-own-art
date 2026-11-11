class_name Sparkles
extends Node2D
## Little four-point sparkles that twinkle and rise over a set of points, then free themselves.

const LIFE: float = 1.4
const RISE: float = 10.0
const COLOURS: Array[String] = ["cream", "sun", "leaf5", "water4"]

var _points: Array[Vector2] = []
var _delays: Array[float] = []
var _age: float = 0.0
var _colours: Array[String] = COLOURS


func setup(points: Array[Vector2], colours: Array[String] = COLOURS) -> Sparkles:
	_points = points
	_colours = colours
	for p: Vector2 in points:
		_delays.append(Game.rng.randf() * 0.6)
	z_index = 50
	return self


func _process(delta: float) -> void:
	_age += delta
	queue_redraw()
	if _age > LIFE + 0.6:
		queue_free()


func _draw() -> void:
	for i: int in _points.size():
		var t: float = (_age - _delays[i]) / LIFE
		if t < 0.0 or t > 1.0:
			continue
		var p: Vector2 = (_points[i] + Vector2(0, -RISE * t)).round()
		var arm: int = 2 if t < 0.5 else 1
		var col: Color = UiKit.c(_colours[i % _colours.size()])
		draw_rect(Rect2(p.x - arm, p.y, arm * 2 + 1, 1), col)
		draw_rect(Rect2(p.x, p.y - arm, 1, arm * 2 + 1), col)
