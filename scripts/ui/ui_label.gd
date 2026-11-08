class_name UiLabel
extends RefCounted
## Makes the plain text labels every screen uses: one font size, one colour, and they
## never catch the mouse.


static func make(font_size: int, color: Color, text: String = "") -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
