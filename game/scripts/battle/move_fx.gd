class_name MoveFx
extends Node2D
## A short element effect for an attack, drawn in palette pixels: Bloom leaves whirl across, Cinder flames burst
## on the target, Tide droplets arc and splash, Gale winds spiral, Stone rocks drop with dust.

const TIME: float = 0.5
const PARTICLES: int = 10

var element: String = "bloom"
var from: Vector2 = Vector2.ZERO
var to: Vector2 = Vector2.ZERO
var _t: float = 0.0
var _seed: Array[float] = []


func setup(elem: String, start: Vector2, target: Vector2) -> MoveFx:
	element = elem
	from = start
	to = target
	for i: int in PARTICLES:
		_seed.append(Game.rng.randf())
	z_index = 20
	return self


func play() -> void:
	if Game.fast:
		queue_free()
		return
	var tw: Tween = create_tween()
	tw.tween_property(self, "_t", 1.0, TIME)
	await tw.finished
	queue_free()


func _process(_delta: float) -> void:
	queue_redraw()


func _px(p: Vector2, w: int, h: int, col: String) -> void:
	draw_rect(Rect2(p.round() - Vector2(w / 2, h / 2), Vector2(w, h)), UiKit.c(col))


func _draw() -> void:
	match element:
		"bloom":
			_leaves()
		"cinder":
			_flames()
		"tide":
			_drops()
		"gale":
			_winds()
		_:
			_rocks()


func _leaves() -> void:
	for i: int in PARTICLES:
		var t: float = clampf(_t * 1.4 - _seed[i] * 0.4, 0.0, 1.0)
		var p: Vector2 = from.lerp(to, t) + Vector2(sin(t * 9.0 + i) * 8.0, -sin(t * PI) * 18.0)
		_px(p, 4, 3, "leaf4" if i % 2 else "leaf3")
		_px(p + Vector2(1, 1), 3, 1, "leaf1")


func _flames() -> void:
	for i: int in PARTICLES:
		var a: float = _seed[i] * TAU
		var r: float = _t * 22.0
		var p: Vector2 = to + Vector2(cos(a) * r, sin(a) * r * 0.6 - _t * 14.0)
		_px(p, 3, 4, "ember3" if _t < 0.5 else "ember2")
		_px(p + Vector2(0, -2), 1, 2, "sun")
	if _t < 0.4:
		draw_arc(to, 6.0 + _t * 30.0, 0, TAU, 24, UiKit.c("ember4"), 2.0, false)


func _drops() -> void:
	for i: int in PARTICLES:
		var t: float = clampf(_t * 1.3 - _seed[i] * 0.3, 0.0, 1.0)
		var p: Vector2 = from.lerp(to + Vector2((_seed[i] - 0.5) * 20, 0), t) + Vector2(0, -sin(t * PI) * 26.0)
		_px(p, 2, 3, "water3")
		_px(p + Vector2(0, -1), 1, 1, "sky")
	if _t > 0.6:
		draw_arc(to + Vector2(0, 10), (_t - 0.6) * 60.0, PI, TAU, 20, UiKit.c("water4"), 1.0, false)


func _winds() -> void:
	for k: int in 3:
		var a0: float = _t * TAU * 1.5 + k * TAU / 3
		draw_arc(to + Vector2(0, -k * 6 + 6), 10.0 + k * 5, a0, a0 + 2.0, 12, UiKit.c("teal3"), 1.0, false)
		draw_arc(to + Vector2(0, -k * 6 + 6), 10.0 + k * 5, a0 + PI, a0 + PI + 1.2, 10, UiKit.c("cream"), 1.0, false)


func _rocks() -> void:
	for i: int in 4:
		var t: float = clampf(_t * 1.6 - _seed[i] * 0.5, 0.0, 1.0)
		var land: Vector2 = to + Vector2((i - 1.5) * 9.0, 6.0)
		var p: Vector2 = land + Vector2(0, -40.0 * (1.0 - t))
		_px(p, 5, 4, "stone2")
		_px(p + Vector2(-1, -1), 2, 1, "stone3")
		if t >= 1.0:
			_px(land + Vector2(-5 - _t * 6, 4), 2, 1, "sand2")
			_px(land + Vector2(5 + _t * 6, 4), 2, 1, "sand2")
