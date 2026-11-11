class_name HudMessages
extends Control
## Words on screen: notices (short, top), story captions (one line above the hotbar), dialogue (speaker + line,
## click or F to go on), lore notes (a small panel), and the end-of-slice card. Dialogue, notes and the card are
## modal: they take the next click.

const NOTICE_TIME: float = 2.6
const MAX_NOTICES: int = 4
const CAPTION_TIME: float = 5.0
const NOTICE_Y: float = 96.0
const BOX_W: float = 470.0
const NOTE_W: float = 380.0
const FADE: float = 0.5
const PLATE_PAD: float = 8.0
const PLATE_ALPHA: float = 0.78

var hud: Hud
var _notices: Array = []          ## [text, time left]
var _caption: String = ""
var _caption_t: float = 0.0
var _dialogue: Array = []
var _on_done: Callable
var _note_title: String = ""
var _note: Array = []
var end_card: bool = false


func setup(h: Hud) -> void:
	hud = h
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## A notice; the same words again while one is showing count up ("+1 Ash x3") instead of stacking.
func notice(s: String) -> void:
	for n: Array in _notices:
		if String(n[2]) == s:
			n[3] = int(n[3]) + 1
			n[0] = "%s  x%d" % [s, int(n[3])]
			n[1] = NOTICE_TIME
			return
	_notices.append([s, NOTICE_TIME, s, 1])
	if _notices.size() > MAX_NOTICES:
		_notices.pop_front()


func caption(s: String) -> void:
	_caption = s
	_caption_t = CAPTION_TIME


func dialogue(lines: Array, on_done: Callable = Callable()) -> void:
	_dialogue = lines.duplicate()
	_on_done = on_done
	Audio.sfx("ui_open", -6.0)


func note(title: String, lines: Array) -> void:
	_note_title = title
	_note = lines
	Audio.sfx("ui_open", -6.0)


func show_end_card() -> void:
	end_card = true


func modal() -> bool:
	return not _dialogue.is_empty() or not _note.is_empty() or end_card


## Advance the open dialogue / close the note. Returns true if something was open.
func advance() -> bool:
	if not _dialogue.is_empty():
		_dialogue.pop_front()
		Audio.sfx("ui_click", -8.0)
		if _dialogue.is_empty() and _on_done.is_valid():
			_on_done.call()
		return true
	if not _note.is_empty():
		_note = []
		return true
	if end_card:
		end_card = false
		return true
	return false


func _process(delta: float) -> void:
	_caption_t -= delta
	for n: Array in _notices:
		n[1] = float(n[1]) - delta
	_notices = _notices.filter(func(n: Array) -> bool: return float(n[1]) > 0.0)
	queue_redraw()


func _draw() -> void:
	var vs: Vector2 = get_viewport_rect().size
	var cluster: Rect2 = Hud.layout(vs)["cluster"]
	for i: int in _notices.size():
		var a: float = clampf(float(_notices[i][1]) / FADE, 0.0, 1.0)
		_plate_text(String(_notices[i][0]), NOTICE_Y + i * 16.0, UiDraw.GOLD, a, vs)
	if caption_visible():
		_plate_text(_caption, cluster.position.y - 14.0, UiDraw.TEXT, clampf(_caption_t / FADE, 0.0, 1.0), vs)
	if not _dialogue.is_empty():
		_draw_dialogue(vs, cluster)
	if not _note.is_empty():
		_draw_note(vs)
	if end_card:
		_draw_end(vs)


func caption_visible() -> bool:
	return _caption_t > 0.0 and _dialogue.is_empty()


## The caption's plate on screen (for fading what stands behind it); empty when no caption shows.
func caption_rect() -> Rect2:
	if not caption_visible():
		return Rect2()
	var vs: Vector2 = get_viewport_rect().size
	return _plate_rect(_caption, Hud.layout(vs)["cluster"].position.y - 14.0, vs)


func _plate_rect(text: String, baseline: float, vs: Vector2) -> Rect2:
	var w: float = UiDraw.text_width(self, text) + PLATE_PAD * 2.0
	return Rect2(roundf((vs.x - w) / 2.0), baseline - 11.0, w, 15.0)


## Words on a dark plate, so they read over any ground or prop.
func _plate_text(text: String, baseline: float, col: Color, a: float, vs: Vector2) -> void:
	var r: Rect2 = _plate_rect(text, baseline, vs)
	draw_rect(r, Color(UiDraw.PANEL_DEEP, PLATE_ALPHA * a))
	draw_rect(r, Color(UiDraw.FRAME, 0.4 * a), false, 1.0)
	UiDraw.text(self, Vector2(0, baseline), text, Color(col, a), UiDraw.BODY, HORIZONTAL_ALIGNMENT_CENTER, vs.x)


func _draw_dialogue(vs: Vector2, cluster: Rect2) -> void:
	var line: Array = _dialogue[0]
	var text_lines: PackedStringArray = UiDraw.wrap(self, String(line[1]), BOX_W - 20.0)
	var h: float = 34.0 + UiDraw.LINE * text_lines.size()
	var r := Rect2(roundf((vs.x - BOX_W) / 2.0), cluster.position.y - h - 8.0, BOX_W, h)
	UiDraw.box(self, r, UiDraw.PANEL_DEEP)
	UiDraw.text(self, r.position + Vector2(10, 15), String(line[0]), UiDraw.GOLD)
	for i: int in text_lines.size():
		UiDraw.text(self, r.position + Vector2(10, 29 + UiDraw.LINE * i), text_lines[i])
	UiDraw.text(self, r.position + Vector2(0, 15), "click / F  ", UiDraw.DIM, UiDraw.SMALL, HORIZONTAL_ALIGNMENT_RIGHT, r.size.x)


func _draw_note(vs: Vector2) -> void:
	var rows: Array = []
	for l: String in _note:
		rows.append_array(UiDraw.wrap(self, l, NOTE_W - 20.0))
	var h: float = 44.0 + UiDraw.LINE * rows.size()
	var r := Rect2(roundf((vs.x - NOTE_W) / 2.0), roundf(vs.y * 0.28), NOTE_W, h)
	UiDraw.box(self, r, Color(0.09, 0.075, 0.06, 0.97))
	UiDraw.text(self, r.position + Vector2(0, 17), _note_title, UiDraw.GOLD, UiDraw.BODY, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	for i: int in rows.size():
		UiDraw.text(self, r.position + Vector2(10, 34 + UiDraw.LINE * i), rows[i], Color("dccfb0"))
	UiDraw.text(self, r.position + Vector2(0, h - 4), "click to close  ", UiDraw.DIM, UiDraw.SMALL, HORIZONTAL_ALIGNMENT_RIGHT, r.size.x)


func _draw_end(vs: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, vs), Color(0, 0, 0, 0.7))
	var p: Player = hud.g.player
	var lines: Array[String] = [String(GameData.story["captions"]["act_end"]), "",
		"Level %d   Mastery: %s" % [p.prog.level, p.prog.mastery.capitalize() if p.prog.mastery != "" else "none yet"],
		"Thank you for playing. Click to keep exploring."]
	UiDraw.text(self, Vector2(0, vs.y * 0.38), "LANTERNFALL", UiDraw.GOLD, UiDraw.TITLE, HORIZONTAL_ALIGNMENT_CENTER, vs.x)
	for i: int in lines.size():
		UiDraw.text(self, Vector2(0, vs.y * 0.38 + 28.0 + i * 14.0), lines[i], UiDraw.TEXT, UiDraw.BODY, HORIZONTAL_ALIGNMENT_CENTER, vs.x)
