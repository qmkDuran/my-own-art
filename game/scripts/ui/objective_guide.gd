class_name ObjectiveGuide
extends Node2D
## An opt-in pointer (off by default; "Objective pointer" in the Esc menu): it sits at the screen edge when the
## objective is off screen, or bobs over it when it is on screen. The map and the tracker are the main guidance.

const EDGE: float = 26.0
const ARROW: float = 9.0

var g: Game
var _pointer := Control.new()


func setup(game: Game) -> void:
	g = game
	var layer := CanvasLayer.new()
	layer.layer = GameUi.LAYER - 1
	add_child(layer)
	_pointer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pointer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pointer.draw.connect(_draw_pointer)
	layer.add_child(_pointer)


static func on() -> bool:
	return bool(GameData.setting("guide", false))


func _process(_delta: float) -> void:
	_pointer.queue_redraw()


func _draw_pointer() -> void:
	var t: Vector2 = Objectives.target(g)
	if not on() or t == Vector2.INF:
		return
	var vs: Vector2 = _pointer.get_viewport_rect().size
	var at: Vector2 = g.get_viewport().get_canvas_transform() * t
	var inner := Rect2(Vector2.ONE * EDGE, vs - Vector2.ONE * EDGE * 2.0)
	var col: Color = Pal.c("gold")
	if inner.has_point(at):
		var bob: float = sin(Time.get_ticks_msec() / 250.0) * 3.0
		_tri(_pointer, at + Vector2(0, -34.0 + bob), Vector2.DOWN, col)
		return
	var c: Vector2 = vs / 2.0
	var d: Vector2 = (at - c).normalized()
	var k: float = minf(absf((inner.size.x / 2.0) / maxf(absf(d.x), 0.001)), absf((inner.size.y / 2.0) / maxf(absf(d.y), 0.001)))
	_tri(_pointer, c + d * k, d, col)


static func _tri(ci: CanvasItem, at: Vector2, d: Vector2, col: Color) -> void:
	var pts := PackedVector2Array([at + d * ARROW, at + d.rotated(2.4) * ARROW, at + d.rotated(-2.4) * ARROW])
	ci.draw_colored_polygon(pts, col)
	pts.append(pts[0])
	ci.draw_polyline(pts, UiDraw.INK, 2.0)
