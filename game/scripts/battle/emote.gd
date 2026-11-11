class_name Emote
extends Node2D
## A creature's feelings drawn over its head: its mood while it waits (wary sweat, sleepy Zs, a playful star,
## a hungry berry) and a burst of hearts when Trust grows or a sweat drop when it falls.

const BOB: float = 1.5
const BURST_TIME: float = 0.9

var mood: String = ""
var _clock: float = 0.0
var _burst: String = ""
var _burst_t: float = 0.0
var _berry: Texture2D = preload("res://art/ui/mood_hungry.png")


func _process(delta: float) -> void:
	_clock += delta
	if _burst != "":
		_burst_t += delta
		if _burst_t > BURST_TIME:
			_burst = ""
	queue_redraw()


func burst(kind: String) -> void:
	_burst = kind
	_burst_t = 0.0


func _px(p: Vector2, w: int, h: int, col: String) -> void:
	draw_rect(Rect2(p.round(), Vector2(w, h)), UiKit.c(col))


func _draw() -> void:
	if _burst == "hearts":
		for i: int in 3:
			_heart(Vector2(-8 + i * 8, -_burst_t * 16.0 - i * 3))
		return
	if _burst == "sweat":
		_sweat(Vector2(8, _burst_t * 4.0))
		return
	var bob: float = round(sin(_clock * 3.0) * BOB)
	match mood:
		"wary":
			_sweat(Vector2(8, bob))
		"sleepy":
			_zzz(bob)
		"playful":
			_star(Vector2(6, -2 + bob))
		"hungry":
			draw_texture(_berry, Vector2(4, -8 + bob))


func _heart(p: Vector2) -> void:
	for row: Array in [[-2, 0, 2], [-3, 1, 5], [-3, 2, 5], [-2, 3, 3], [-1, 4, 1]]:
		_px(p + Vector2(row[0], row[1]), int(row[2]) + 2, 1, "ink")
	for row: Array in [[-2, 1, 2], [1, 1, 2], [-2, 2, 5], [-1, 3, 3], [0, 4, 1]]:
		_px(p + Vector2(row[0], row[1]), int(row[2]), 1, "rose2")


func _sweat(p: Vector2) -> void:
	_px(p + Vector2(1, 0), 1, 1, "ink")
	_px(p + Vector2(0, 1), 3, 1, "ink")
	_px(p + Vector2(-1, 2), 5, 3, "ink")
	_px(p + Vector2(1, 1), 1, 1, "water3")
	_px(p + Vector2(0, 2), 3, 2, "water3")
	_px(p + Vector2(0, 2), 1, 1, "sky")


func _zzz(bob: float) -> void:
	for i: int in 3:
		var phase: float = fmod(_clock * 0.8 + i * 0.33, 1.0)
		var p := Vector2(4 + i * 5 + phase * 4, -phase * 12 + bob)
		var s: int = 2 + i
		_px(p, s + 1, 1, "plum3")
		for k: int in s - 1:
			_px(p + Vector2(s - 1 - k, 1 + k), 1, 1, "plum3")
		_px(p + Vector2(0, s), s + 1, 1, "plum3")


func _star(p: Vector2) -> void:
	_px(p + Vector2(2, 0), 1, 5, "ember4")
	_px(p + Vector2(0, 2), 5, 1, "ember4")
	_px(p + Vector2(2, 2), 1, 1, "sun")
