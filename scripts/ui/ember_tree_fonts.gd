class_name EmberTreeFonts
extends RefCounted
## The Ember Tree screen's font sizes and fonts, all from the shared UI theme.
##
## The theme's font is Monogram, a pixel font drawn on a 16 px grid, so it only looks crisp
## at whole multiples of 16. Text in the zoomable tree is scaled by the zoom, so it uses a
## smoothed copy of the same font instead (crisp pixels can't survive a 0.6× zoom).

const UI_THEME_PATH := "res://scenes/ui/theme/ui_theme.tres"
## Monogram's native size: one font pixel per screen-canvas pixel.
const TEXT_SIZE := 16
## Twice the native size, for titles and big numbers.
const LARGE_SIZE := 32
## Capital letters are this tall for each pixel of font size (7 of Monogram's 16).
const CAP_HEIGHT_RATIO := 7.0 / 16.0

static var _theme: Theme
static var _smooth_font: Font


## The shared UI theme (pixel font, sizes); set it on a screen's root Control.
static func ui_theme() -> Theme:
	if _theme == null:
		_theme = load(UI_THEME_PATH)
	return _theme


## The crisp pixel font, for text drawn straight onto the screen canvas.
static func pixel() -> Font:
	return ui_theme().default_font


## A smoothed copy of the pixel font, for words drawn inside the zoomable tree.
static func smooth() -> Font:
	if _smooth_font == null:
		var copy := (pixel() as FontFile).duplicate() as FontFile
		copy.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
		_smooth_font = copy
	return _smooth_font
