class_name WordBurst
extends Node2D
## A big pixel-font word popping over a hit, e.g. "STEAM BURST!" or "LINK FINISHER!": it
## slams in at triple size, settles at double, floats up and fades. Whole-number scales and
## whole-pixel positions only, so it stays crisp.

const POP_SCALE := 3
const SETTLED_SCALE := 2
## Seconds at the pop size before it settles.
const POP_SECONDS := 0.07
const LIFETIME := 1.0
const RISE := 10.0
const FADE_START := 0.65
## A new word that would overlap a fresh one moves up by a line until it doesn't.
const LINE_HEIGHT := 13.0
const OVERLAP_SECONDS := 0.5

## Words on screen right now, so new ones can stack above them.
static var _live: Array[WordBurst] = []

var _text: String = ""
var _color: Color = ApolloPalette.GOLD
var _start: Vector2 = Vector2.ZERO
var _age: float = 0.0


static func pop(world: Node, at: Vector2, text: String, color: Color) -> void:
	var burst := WordBurst.new()
	burst._text = text
	burst._color = color
	burst.z_index = 6
	world.add_child(burst)
	burst._start = _free_spot(at.round(), PixelFont.width_of(text) * SETTLED_SCALE)
	burst.global_position = burst._start
	_live.append(burst)


## `at`, moved up a line at a time while it would overlap a word that just popped.
static func _free_spot(at: Vector2, width: float) -> Vector2:
	for index in range(_live.size() - 1, -1, -1):
		if not is_instance_valid(_live[index]):
			_live.remove_at(index)
	var spot := at
	var moved := true
	while moved:
		moved = false
		for word in _live:
			var half_widths := (width + PixelFont.width_of(word._text) * SETTLED_SCALE) / 2.0
			var is_fresh := word._age < OVERLAP_SECONDS
			if is_fresh and absf(word._start.x - spot.x) < half_widths and absf(word._start.y - spot.y) < LINE_HEIGHT:
				spot.y = word._start.y - LINE_HEIGHT
				moved = true
	return spot


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return
	global_position = (_start + Vector2(0, -RISE * _age / LIFETIME)).round()
	var fade := clampf((LIFETIME - _age) / (LIFETIME * (1.0 - FADE_START)), 0.0, 1.0)
	modulate.a = fade
	queue_redraw()


func _draw() -> void:
	var text_scale := POP_SCALE if _age < POP_SECONDS else SETTLED_SCALE
	var width := PixelFont.width_of(_text)
	var top_left := Vector2(-floori(width / 2.0), -PixelFont.GLYPH_HEIGHT)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(text_scale, text_scale))
	PixelFont.draw_text(self, _text, top_left, _color, ApolloPalette.OUTLINE)
	draw_set_transform(Vector2.ZERO)
