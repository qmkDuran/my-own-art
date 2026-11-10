class_name UiStyle
extends RefCounted
## Shared colours and widget styling for all UI built in code.

const INK := Color("e8dcc0")
const DIM := Color("9a907c")
const ACCENT := Color("e8b45a")
const PANEL := Color(0.05, 0.05, 0.08, 0.88)
const BORDER := Color("6a5a40")


static func panel(color: Color = PANEL, border: Color = BORDER) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = border
	box.set_border_width_all(2)
	box.set_content_margin_all(8)
	return box


static func label(text: String, font_size: int = 16, color: Color = INK) -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", color)
	result.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	result.add_theme_constant_override("outline_size", 3)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result


static func button(text: String) -> Button:
	var result := Button.new()
	result.text = text
	result.custom_minimum_size = Vector2(220, 36)
	result.add_theme_font_size_override("font_size", 18)
	result.add_theme_stylebox_override("normal", panel(Color(0.08, 0.07, 0.1, 0.9)))
	result.add_theme_stylebox_override("hover", panel(Color(0.16, 0.13, 0.1, 0.95), ACCENT))
	result.add_theme_stylebox_override("focus", panel(Color(0.16, 0.13, 0.1, 0.95), ACCENT))
	result.add_theme_stylebox_override("pressed", panel(Color(0.22, 0.17, 0.1, 0.95), ACCENT))
	result.add_theme_stylebox_override("disabled", panel(Color(0.05, 0.05, 0.06, 0.7), Color("3a3430")))
	result.add_theme_color_override("font_color", INK)
	result.add_theme_color_override("font_disabled_color", Color("5a544a"))
	return result
