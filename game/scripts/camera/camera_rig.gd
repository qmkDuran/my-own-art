class_name CameraRig
extends Camera2D
## Follow camera with integer pixel scales only, so pixel art stays crisp.
## The window shows the 960x540 game view at 2x; a "screen scale" n draws every art pixel as n x n screen pixels:
##   1 = overview (1920x1080 art px visible), 2 = normal, 3 = close.  Camera zoom = screen scale / WINDOW_SCALE.
## Steps go through a quick soft fade instead of a blurry in-between zoom. Clamped to the map bounds.

const VIEW := Vector2(960, 540)
const WINDOW_SCALE: float = 2.0
const SCALES: Array[int] = [1, 2, 3]
const NORMAL: int = 2
const FADE_OUT: float = 0.08
const FADE_IN: float = 0.14
const FADE_ALPHA: float = 0.55

var bounds := Rect2(Vector2.ZERO, VIEW)
var target: Node2D
var _scale: int = NORMAL
var _veil: ColorRect
var _busy: bool = false


func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	_veil = ColorRect.new()
	_veil.color = Color(1, 1, 1, 0)
	_veil.size = VIEW
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_veil)
	set_screen_scale(_scale)
	position = bounds.get_center()
	make_current()


## The smallest scale at which the whole view still lies inside the map (one-screen maps: normal).
func min_scale() -> int:
	var need: float = maxf(VIEW.x * WINDOW_SCALE / bounds.size.x, VIEW.y * WINDOW_SCALE / bounds.size.y)
	return maxi(SCALES[0], ceili(need - 0.001))


func screen_scale() -> int:
	return _scale


func set_screen_scale(n: int) -> void:
	_scale = n
	zoom = Vector2.ONE * (n / WINDOW_SCALE)
	if target != null:
		position = clamp_to_bounds(target.global_position)


## Step to the next allowed scale (+1 closer, -1 further) through a quick fade; returns false if already at the end.
func step(direction: int) -> bool:
	var allowed: Array[int] = []
	for s: int in SCALES:
		if s >= min_scale():
			allowed.append(s)
	var i: int = clampi(allowed.find(_scale) + direction, 0, allowed.size() - 1)
	return go_to(allowed[i])


func go_to(n: int) -> bool:
	if n == _scale or _busy:
		return false
	_busy = true
	var tw := create_tween()
	tw.tween_property(_veil, "color:a", FADE_ALPHA, FADE_OUT)
	tw.tween_callback(set_screen_scale.bind(n))
	tw.tween_property(_veil, "color:a", 0.0, FADE_IN)
	tw.tween_callback(func() -> void: _busy = false)
	return true


func cycle() -> void:
	var n: int = _scale + 1
	go_to(n if n <= SCALES[-1] else min_scale())


func _process(_delta: float) -> void:
	if target != null:
		position = clamp_to_bounds(target.global_position)


func clamp_to_bounds(p: Vector2) -> Vector2:
	var half: Vector2 = VIEW / zoom / 2.0
	var x: float = bounds.get_center().x if half.x * 2.0 >= bounds.size.x else clampf(p.x, bounds.position.x + half.x, bounds.end.x - half.x)
	var y: float = bounds.get_center().y if half.y * 2.0 >= bounds.size.y else clampf(p.y, bounds.position.y + half.y, bounds.end.y - half.y)
	return Vector2(x, y).round()


## A slow camera tour (recording aid): visit each stop at a fixed screen scale, then call `done`.
func tour(stops: Array[Vector2], scale_n: int, move: float, hold: float, done: Callable) -> void:
	target = null
	_scale = scale_n
	zoom = Vector2.ONE * (scale_n / WINDOW_SCALE)
	position = stops[0]
	var tw := create_tween()
	for stop: Vector2 in stops:
		tw.tween_property(self, "position", stop, move).set_trans(Tween.TRANS_SINE)
		tw.tween_interval(hold)
	tw.tween_callback(done)
