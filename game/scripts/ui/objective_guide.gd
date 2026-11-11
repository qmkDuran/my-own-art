class_name ObjectiveGuide
extends Node2D
## Where to go: faint lantern motes drift along the walking path toward the current objective (a few steps
## ahead of you), and a pointer sits at the screen edge when the objective is off screen (or bobs over it when
## it is on screen). Toggle: "Objective guide" in the Esc menu.

const MOTE_EVERY: float = 0.18
const MOTE_STEP: float = 26.0
const TRAIL: float = 240.0
const MOTE_LIFE: float = 1.2
const EDGE: float = 26.0
const ARROW: float = 9.0
const PATH_EVERY: float = 0.5
const NEAR: float = 40.0

var g: Game
var _path := PackedVector2Array()
var _path_t: float = 0.0
var _mote_t: float = 0.0
var _along: float = 0.0
var _pointer := Control.new()


func setup(game: Game) -> void:
	g = game
	z_index = -12
	var layer := CanvasLayer.new()
	layer.layer = GameUi.LAYER - 1
	add_child(layer)
	_pointer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pointer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pointer.draw.connect(_draw_pointer)
	layer.add_child(_pointer)


static func on() -> bool:
	return bool(GameData.setting("guide", true))


func _process(delta: float) -> void:
	_pointer.queue_redraw()
	var t: Vector2 = Objectives.target(g)
	if not on() or t == Vector2.INF or g.player.global_position.distance_to(t) < NEAR:
		return
	_path_t -= delta
	if _path_t <= 0.0:
		_path_t = PATH_EVERY
		_path = g.nav.path(g.player.global_position, t)
		_path.insert(0, g.player.global_position)
	_mote_t -= delta
	if _mote_t <= 0.0 and _path.size() > 1:
		_mote_t = MOTE_EVERY
		_along = fmod(_along + MOTE_STEP, TRAIL)
		_mote(_point_along(_along + MOTE_STEP))


func _point_along(d: float) -> Vector2:
	for i: int in range(1, _path.size()):
		var seg: float = _path[i - 1].distance_to(_path[i])
		if d <= seg:
			return _path[i - 1].lerp(_path[i], d / maxf(seg, 0.01))
		d -= seg
	return _path[_path.size() - 1]


func _mote(at: Vector2) -> void:
	var m := Sprite2D.new()
	m.texture = LightTex.soft(16)
	m.material = Fx.glow_material()
	m.modulate = Pal.c("gold", 0.0)
	m.position = at
	add_child(m)
	var tw := m.create_tween()
	tw.tween_property(m, "modulate:a", 0.55, MOTE_LIFE * 0.3)
	tw.parallel().tween_property(m, "position:y", at.y - 8.0, MOTE_LIFE)
	tw.tween_property(m, "modulate:a", 0.0, MOTE_LIFE * 0.7)
	tw.tween_callback(m.queue_free)


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
