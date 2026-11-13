class_name UiStyle
## The shared look of the HUD and panels: warm parchment text with a soft shadow, rounded dark panels, and
## coloured bars. One place, so every screen matches.

const TEXT: Color = Color(1.0, 0.94, 0.82)
const SHADOW: Color = Color(0.0, 0.0, 0.0, 0.7)
const PANEL: Color = Color(0.08, 0.07, 0.12, 0.82)
const PANEL_EDGE: Color = Color(0.95, 0.72, 0.4, 0.8)
const CORNER: int = 10
const EDGE: int = 2
const PADDING: int = 12


static func label(text: String, size: int) -> Label:
	var out := Label.new()
	out.text = text
	out.add_theme_font_size_override("font_size", size)
	out.add_theme_color_override("font_color", TEXT)
	out.add_theme_color_override("font_shadow_color", SHADOW)
	return out


static func panel_box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = PANEL
	box.border_color = PANEL_EDGE
	box.set_border_width_all(EDGE)
	box.set_corner_radius_all(CORNER)
	box.set_content_margin_all(PADDING)
	return box


static func bar(colour: Color, height: int) -> ProgressBar:
	var out := ProgressBar.new()
	out.show_percentage = false
	out.custom_minimum_size.y = height
	var fill := StyleBoxFlat.new()
	fill.bg_color = colour
	fill.set_corner_radius_all(CORNER)
	var back := StyleBoxFlat.new()
	back.bg_color = PANEL
	back.set_corner_radius_all(CORNER)
	out.add_theme_stylebox_override("fill", fill)
	out.add_theme_stylebox_override("background", back)
	return out
