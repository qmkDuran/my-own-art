class_name IntroCards
extends RefCounted
## The story cards before a new game. Each card types out; a press (Space, Enter, click) completes the line, the
## next press moves on. Cards never advance on their own. Holding Esc skips the whole intro.

const TYPE_SPEED: float = 38.0          ## letters per second
const SKIP_HOLD: float = 0.8            ## seconds of held Esc that skip the intro
const LINE_H: float = 26.0
const WRAP: float = 0.62

var cards: Array = []
var index: int = 0
var _shown: float = 0.0
var _esc: float = 0.0


func _init(story_cards: Array) -> void:
	cards = story_cards


func done() -> bool:
	return index >= cards.size()


func tick(delta: float) -> void:
	_shown += delta * TYPE_SPEED
	_esc = _esc + delta if Input.is_key_pressed(KEY_ESCAPE) else 0.0
	if _esc >= SKIP_HOLD:
		index = cards.size()


## A press: finish the typing, or go on to the next card.
func press() -> void:
	if done():
		return
	if _shown < String(cards[index]).length():
		_shown = String(cards[index]).length()
	else:
		index += 1
		_shown = 0.0


func skip_fraction() -> float:
	return clampf(_esc / SKIP_HOLD, 0.0, 1.0)


func draw(ci: CanvasItem, vs: Vector2) -> void:
	var text: String = String(cards[index])
	var lines: PackedStringArray = UiDraw.wrap(ci, text, vs.x * WRAP, UiDraw.TITLE)
	var left: int = int(_shown)
	var y: float = vs.y * 0.58
	for line: String in lines:
		var part: String = line.substr(0, clampi(left, 0, line.length()))
		left -= line.length() + 1
		UiDraw.text(ci, Vector2(0, y), part, UiDraw.TEXT, UiDraw.TITLE, HORIZONTAL_ALIGNMENT_CENTER, vs.x)
		y += LINE_H
	var typed: bool = _shown >= text.length()
	UiDraw.text(ci, Vector2(0, vs.y - 30.0), "Space ▸" if typed else "Space to finish", Color(UiDraw.GOLD, 0.6 + 0.4 * float(typed)),
		UiDraw.BODY, HORIZONTAL_ALIGNMENT_CENTER, vs.x)
	UiDraw.text(ci, Vector2(0, vs.y - 12.0), "%d / %d      hold Esc to skip the story" % [index + 1, cards.size()], UiDraw.DIM, UiDraw.SMALL,
		HORIZONTAL_ALIGNMENT_CENTER, vs.x)
	if _esc > 0.0:
		ci.draw_rect(Rect2(vs.x * 0.4, vs.y - 6.0, vs.x * 0.2 * skip_fraction(), 2.0), UiDraw.GOLD)
