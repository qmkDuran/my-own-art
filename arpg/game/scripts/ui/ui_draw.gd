class_name UiDraw
extends RefCounted
## Drawing helpers shared by the HUD and the panels: outlined pixel text, framed boxes, tooltips. One look everywhere:
## near-black panels with a thin pale-gold frame.

const FONT_SMALL: int = 16
const INK := Color("2e222f")
const PANEL := Color(0.07, 0.06, 0.1, 0.92)
const FRAME := Color("c7b07a")
const DIM := Color("9babb2")
const GOLD := Color("f9c22b")
const WHITE := Color.WHITE


static func text(ci: CanvasItem, pos: Vector2, s: String, col: Color = WHITE, size: int = FONT_SMALL,
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1.0) -> void:
	var f: Font = ci.get_theme_default_font()
	ci.draw_string_outline(f, pos, s, align, width, size, 4, INK)
	ci.draw_string(f, pos, s, align, width, size, col)


static func text_width(ci: CanvasItem, s: String, size: int = FONT_SMALL) -> float:
	return ci.get_theme_default_font().get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


static func box(ci: CanvasItem, r: Rect2, fill: Color = PANEL, border: Color = FRAME) -> void:
	ci.draw_rect(r, fill)
	ci.draw_rect(r, border, false, 1.0)


## A tooltip near `at`, kept on screen: first line in `title_col`, the rest pale.
static func tooltip(ci: CanvasItem, at: Vector2, lines: PackedStringArray, title_col: Color = WHITE) -> void:
	if lines.is_empty():
		return
	var w: float = 0.0
	for l: String in lines:
		w = maxf(w, text_width(ci, l))
	var h: float = 14.0 * lines.size() + 8.0
	var r := Rect2(at + Vector2(14, 8), Vector2(w + 14.0, h))
	r.position.x = minf(r.position.x, 960.0 - r.size.x - 4.0)
	r.position.y = minf(r.position.y, 540.0 - r.size.y - 4.0)
	box(ci, r, Color(0.04, 0.03, 0.06, 0.96))
	for i: int in lines.size():
		text(ci, r.position + Vector2(7, 16 + 14 * i), lines[i], title_col if i == 0 else Color("dcd3c0"))


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
