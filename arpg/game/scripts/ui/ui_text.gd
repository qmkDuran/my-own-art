class_name UiText
extends RefCounted
## Centred, outlined pixel-font labels (monogram, sizes 16 and 32 only so the pixels stay crisp).

const VIEW_W: float = 960.0
const SMALL: int = 16
const LARGE: int = 32
const OUTLINE := Color("2e222f")


static func label(parent: Node, font_size: int, y: float, text: String) -> Label:
	var l := Label.new()
	var ls := LabelSettings.new()
	ls.font_size = font_size
	ls.font_color = Color.WHITE
	ls.outline_size = 4 if font_size < 24 else 6
	ls.outline_color = OUTLINE
	l.label_settings = ls
	l.text = text
	l.position = Vector2(0, y)
	l.size = Vector2(VIEW_W, 0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(l)
	return l
