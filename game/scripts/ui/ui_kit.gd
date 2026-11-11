class_name UiKit
extends RefCounted
## The look of every menu: pixel fonts (Pixelify Sans for text, Silkscreen for small labels), palette colours
## and the panel styles. Builds the global theme once; widgets ask here instead of hard-coding colours.

const BODY_SIZE: int = 11
const SMALL_SIZE: int = 8
const RADIUS: int = 3
const PAD: int = 4
const BODY_FONT: String = "res://fonts/PixelifySans.ttf"
const SMALL_FONT: String = "res://fonts/Silkscreen.ttf"

static var _body: FontFile
static var _small: FontFile


static func body_font() -> FontFile:
	if _body == null:
		_body = _pixel_font(BODY_FONT)
	return _body


static func small_font() -> FontFile:
	if _small == null:
		_small = _pixel_font(SMALL_FONT)
	return _small


static func _pixel_font(path: String) -> FontFile:
	var f: FontFile = load(path)
	f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	f.hinting = TextServer.HINTING_NONE
	f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	f.generate_mipmaps = false
	return f


static func c(name: String) -> Color:
	return Db.color(name)


## A rounded panel: paper by default, ink border.
static func panel_style(bg: String = "paper", border: String = "ink", width: int = 1) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = c(bg)
	s.border_color = c(border)
	s.set_border_width_all(width)
	s.set_corner_radius_all(RADIUS)
	s.anti_aliasing = false
	s.set_content_margin_all(PAD)
	return s


static func build_theme() -> Theme:
	var t := Theme.new()
	t.default_font = body_font()
	t.default_font_size = BODY_SIZE
	t.set_color("font_color", "Label", c("ink"))
	for type: String in ["Label", "Button", "RichTextLabel", "LineEdit"]:
		t.set_font_size("font_size", type, BODY_SIZE)
		t.set_font("font", type, body_font())
	t.set_stylebox("panel", "PanelContainer", panel_style())
	t.set_stylebox("panel", "Panel", panel_style())
	return t


static func label(text: String, colour: String = "ink", small: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", c(colour))
	l.add_theme_font_override("font", body_font())
	l.add_theme_font_size_override("font_size", BODY_SIZE)
	if small:
		l.add_theme_font_override("font", small_font())
		l.add_theme_font_size_override("font_size", SMALL_SIZE)
	return l


static func panel(rect: Rect2, bg: String = "paper", border: String = "ink") -> Panel:
	var p := Panel.new()
	p.position = rect.position
	p.size = rect.size
	p.add_theme_stylebox_override("panel", panel_style(bg, border))
	return p


static func tex(path: String) -> Texture2D:
	return load(path) as Texture2D


static func creature_tex(id: String, view: String) -> Texture2D:
	return tex("res://art/creatures/%s_%s.png" % [id, view])


static func is_click(ev: InputEvent) -> bool:
	var mb := ev as InputEventMouseButton
	return mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT


static func text_width(text: String, small: bool = false) -> float:
	var font: FontFile = small_font() if small else body_font()
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, SMALL_SIZE if small else BODY_SIZE).x


## A label that wraps inside a fixed width.
static func wrapped(text: String, width: float, colour: String = "ink", small: bool = false) -> Label:
	var l := label(text, colour, small)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(width, 0)
	l.size = Vector2(width, 0)
	return l
