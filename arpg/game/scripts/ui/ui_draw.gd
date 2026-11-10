class_name UiDraw
extends RefCounted
## Drawing helpers shared by the HUD and the panels: outlined pixel text, framed boxes, tooltips. One look everywhere:
## near-black panels with a thin pale-gold frame.

## Type hierarchy (whole-pixel sizes, no antialiasing): Pixelify Sans (OFL) for titles and body text, Silkscreen
## (OFL) for small labels and numbers. Both fonts are on a pixel grid at these sizes (2x/3x on screen at 1080p).
const TITLE: int = 20
const BODY: int = 10
const SMALL: int = 8
const LINE: float = 12.0
const INK := Color("2e222f")
const PANEL := Color(0.07, 0.06, 0.1, 0.94)
const FRAME := Color("c7b07a")
const DIM := Color("9babb2")
const GOLD := Color("f9c22b")
const WHITE := Color.WHITE
const UP := Color("91db69")
const DOWN := Color("e83b3b")

static var _small: Font
static var _title: Font


static func font_for(ci: CanvasItem, size: int) -> Font:
	if size <= SMALL:
		if _small == null:
			_small = load("res://fonts/Silkscreen.ttf") as Font
		return _small
	if size >= TITLE:
		if _title == null:
			_title = load("res://fonts/title.tres") as Font
		return _title
	return ci.get_theme_default_font()


static func text(ci: CanvasItem, pos: Vector2, s: String, col: Color = WHITE, size: int = BODY,
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1.0) -> void:
	var f: Font = font_for(ci, size)
	if align != HORIZONTAL_ALIGNMENT_LEFT and width > 0.0:   # place by measured width (whole pixels, spaces kept)
		var w: float = f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		pos.x += roundf((width - w) / (2.0 if align == HORIZONTAL_ALIGNMENT_CENTER else 1.0))
	pos = pos.round()
	ci.draw_string_outline(f, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 2 if size <= BODY else 4, INK)
	ci.draw_string(f, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


static func text_width(ci: CanvasItem, s: String, size: int = BODY) -> float:
	return font_for(ci, size).get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


## Label settings for world/overlay labels in the same hierarchy.
static func label_settings(size: int, col: Color) -> LabelSettings:
	var ls := LabelSettings.new()
	ls.font = load("res://fonts/Silkscreen.ttf") if size <= SMALL else (load("res://fonts/title.tres") if size >= TITLE else load("res://fonts/body.tres"))
	ls.font_size = size
	ls.font_color = col
	ls.outline_size = 2 if size <= BODY else 4
	ls.outline_color = INK
	return ls


static func box(ci: CanvasItem, r: Rect2, fill: Color = PANEL, border: Color = FRAME) -> void:
	ci.draw_rect(r, fill)
	ci.draw_rect(r, border, false, 1.0)


## A tooltip near `at`, kept on screen. Rows are strings or [text, colour]; the first row is the title.
static func tooltip(ci: CanvasItem, at: Vector2, rows: Variant, title_col: Color = WHITE) -> void:
	var lines: Array = Array(rows)
	if lines.is_empty():
		return
	var w: float = 0.0
	for l: Variant in lines:
		w = maxf(w, text_width(ci, l[0] if l is Array else String(l)))
	var vs: Vector2 = ci.get_viewport_rect().size
	var h: float = LINE * lines.size() + 8.0
	var r := Rect2(at + Vector2(14, 8), Vector2(w + 14.0, h))
	r.position.x = clampf(r.position.x, 4.0, vs.x - r.size.x - 4.0)
	r.position.y = clampf(r.position.y, 4.0, vs.y - r.size.y - 4.0)
	box(ci, r, Color(0.04, 0.03, 0.06, 0.97))
	for i: int in lines.size():
		var l: Variant = lines[i]
		var col: Color = title_col if i == 0 else Color("dcd3c0")
		var t: String = ""
		if l is Array:
			t = String(l[0])
			col = l[1]
		else:
			t = str(l)
		text(ci, r.position + Vector2(7, 13 + LINE * i), t, col)


## A verse (by key in verses.json) and its reference, wrapped to lines of about `chars` characters.
static func verse_lines(k: String, chars: int = 60) -> PackedStringArray:
	var out := PackedStringArray()
	var line: String = ""
	for word: String in Scripture.text(k).split(" "):
		if line.length() + word.length() + 1 > chars:
			out.append(line)
			line = word
		else:
			line = word if line == "" else line + " " + word
	out.append(line)
	out.append("- " + Scripture.ref(k) + " (NIV)")
	return out
