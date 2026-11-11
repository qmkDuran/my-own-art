class_name UiDraw
extends RefCounted
## One look for every panel, tooltip and label: near-black ink panels with a thin brass frame and lit corner rivets,
## Pixelify Sans (OFL) for titles and body, Silkscreen (OFL) for small labels and numbers, whole-pixel sizes, no
## antialiasing, a dark outline on all text. Every text size in the game comes from these constants.

const TITLE: int = 20
const BODY: int = 10
const SMALL: int = 8
const LINE: float = 12.0
const PAD: float = 7.0
const INK := Color("15131f")
const PANEL := Color(0.06, 0.055, 0.09, 0.95)
const PANEL_DEEP := Color(0.035, 0.03, 0.055, 0.97)
const FRAME := Color("8a6a46")
const FRAME_LIT := Color("f7b043")
const DIM := Color("9a97b8")
const TEXT := Color("e8e4d8")
const GOLD := Color("ffd77a")
const UP := Color("8fdc6a")
const DOWN := Color("e8505a")
const LOCKED := Color("55507a")

static var _small: Font
static var _title: Font
static var _body: Font


static func font_for(ci: CanvasItem, size: int) -> Font:
	if size <= SMALL:
		if _small == null:
			_small = load("res://fonts/Silkscreen.ttf") as Font
		return _small
	if size >= TITLE:
		if _title == null:
			_title = load("res://fonts/title.tres") as Font
		return _title
	if ci is Control:
		return (ci as Control).get_theme_default_font()
	if _body == null:                         # world-space drawing (tags over creatures) has no theme
		_body = load("res://fonts/body.tres") as Font
	return _body


static func text(ci: CanvasItem, pos: Vector2, s: String, col: Color = TEXT, size: int = BODY,
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1.0) -> void:
	var f: Font = font_for(ci, size)
	if align != HORIZONTAL_ALIGNMENT_LEFT and width > 0.0:
		var w: float = f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		pos.x += roundf((width - w) / (2.0 if align == HORIZONTAL_ALIGNMENT_CENTER else 1.0))
	pos = pos.round()
	ci.draw_string_outline(f, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 2 if size <= BODY else 4, INK)
	ci.draw_string(f, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


static func text_width(ci: CanvasItem, s: String, size: int = BODY) -> float:
	return font_for(ci, size).get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


static func label_settings(size: int, col: Color) -> LabelSettings:
	var ls := LabelSettings.new()
	ls.font = load("res://fonts/Silkscreen.ttf") if size <= SMALL else (load("res://fonts/title.tres") if size >= TITLE else load("res://fonts/body.tres"))
	ls.font_size = size
	ls.font_color = col
	ls.outline_size = 2 if size <= BODY else 4
	ls.outline_color = INK
	return ls


## A framed panel: ink fill, brass frame, lit rivets in the corners.
static func box(ci: CanvasItem, r: Rect2, fill: Color = PANEL, border: Color = FRAME) -> void:
	r = Rect2(r.position.round(), r.size.round())
	ci.draw_rect(r.grow(1.0), INK)
	ci.draw_rect(r, fill)
	ci.draw_rect(r, border, false, 1.0)
	for c: Vector2 in [r.position, Vector2(r.end.x - 2, r.position.y), Vector2(r.position.x, r.end.y - 2), r.end - Vector2(2, 2)]:
		ci.draw_rect(Rect2(c, Vector2(2, 2)), FRAME_LIT)


## A panel title bar with a centred title.
static func title_bar(ci: CanvasItem, r: Rect2, title: String) -> void:
	ci.draw_rect(Rect2(r.position + Vector2(1, 1), Vector2(r.size.x - 2, 22)), Color(0.12, 0.08, 0.06, 0.9))
	ci.draw_line(r.position + Vector2(1, 23), r.position + Vector2(r.size.x - 1, 23), FRAME)
	text(ci, r.position + Vector2(0, 18), title, GOLD, TITLE, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)


## Size of a tooltip for these rows (first row is the title).
static func tooltip_size(ci: CanvasItem, rows: Array) -> Vector2:
	var w: float = 0.0
	for i: int in rows.size():
		var l: Variant = rows[i]
		w = maxf(w, text_width(ci, String(l[0]) if l is Array else String(l), BODY))
	return Vector2(w + PAD * 2.0, LINE * rows.size() + PAD * 2.0 - 2.0)


## A tooltip near `at`, kept fully on screen. Rows: strings or [text, colour]; an empty string is a spacer line.
static func tooltip(ci: CanvasItem, at: Vector2, rows: Array, title_col: Color = TEXT) -> Rect2:
	if rows.is_empty():
		return Rect2()
	var vs: Vector2 = ci.get_viewport_rect().size
	var sz: Vector2 = tooltip_size(ci, rows)
	var r := Rect2(at + Vector2(14, 10), sz)
	if r.end.x > vs.x - 4.0:
		r.position.x = at.x - sz.x - 10.0
	return tooltip_at(ci, r.position, rows, title_col)


## A tooltip with its top-left corner at `pos` (kept on screen).
static func tooltip_at(ci: CanvasItem, pos: Vector2, rows: Array, title_col: Color = TEXT) -> Rect2:
	var vs: Vector2 = ci.get_viewport_rect().size
	var sz: Vector2 = tooltip_size(ci, rows)
	var r := Rect2(pos, sz)
	r.position.x = clampf(r.position.x, 4.0, vs.x - sz.x - 4.0)
	r.position.y = clampf(r.position.y, 4.0, vs.y - sz.y - 4.0)
	box(ci, r, PANEL_DEEP)
	for i: int in rows.size():
		var l: Variant = rows[i]
		var col: Color = title_col if i == 0 else TEXT
		var t: String = ""
		if l is Array:
			t = String(l[0])
			col = l[1]
		else:
			t = str(l)
		text(ci, r.position + Vector2(PAD, PAD + 8.0 + LINE * i), t, col)
	return r


## Words wrapped to lines of at most `width` pixels.
static func wrap(ci: CanvasItem, s: String, width: float, size: int = BODY) -> PackedStringArray:
	var out := PackedStringArray()
	var line: String = ""
	for word: String in s.split(" "):
		var t: String = word if line == "" else line + " " + word
		if text_width(ci, t, size) > width and line != "":
			out.append(line)
			line = word
		else:
			line = t
	if line != "":
		out.append(line)
	return out
