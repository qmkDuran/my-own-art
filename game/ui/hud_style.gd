class_name HudStyle
## The HUD's shared look: colours, sizes and a text helper, so every widget reads as one calm, consistent set.

const INK: Color = Color(0.96, 0.95, 0.88)
const INK_DIM: Color = Color(0.96, 0.95, 0.88, 0.6)
const PANEL: Color = Color(0.06, 0.08, 0.06, 0.62)
const PANEL_EDGE: Color = Color(0.96, 0.95, 0.88, 0.35)
const SHADOW: Color = Color(0, 0, 0, 0.75)
const LIFE_PLAYER: Color = Color(0.93, 0.55, 0.22)
const LIFE_BOT: Color = Color(0.58, 0.52, 0.92)
const LIFE_LOW: Color = Color(0.92, 0.25, 0.2)
const HIDDEN_COLOR: Color = Color(0.55, 0.85, 0.55)
const HEARD_COLOR: Color = Color(1.0, 0.75, 0.25)
const SEEN_COLOR: Color = Color(1.0, 0.32, 0.25)
const AMBUSH_COLOR: Color = Color(1.0, 0.84, 0.3)
const LOCK_COLOR: Color = Color(1.0, 0.45, 0.25)
const FONT_SMALL: int = 15
const FONT_MEDIUM: int = 20
const FONT_LARGE: int = 30
const FONT_TITLE: int = 64
const MARGIN: float = 24.0
const EDGE_WIDTH: float = 2.0
const OUTLINE: int = 4


static func text(canvas: CanvasItem, at: Vector2, words: String, size: int, color: Color,
		align: HorizontalAlignment, width: float) -> void:
	var font: Font = ThemeDB.fallback_font
	canvas.draw_string_outline(font, at, words, align, width, size, OUTLINE, SHADOW)
	canvas.draw_string(font, at, words, align, width, size, color)


static func panel(canvas: CanvasItem, area: Rect2) -> void:
	canvas.draw_rect(area, PANEL)
	canvas.draw_rect(area, PANEL_EDGE, false, EDGE_WIDTH)


## Pins a widget to a point of the screen (anchor 0..1 on each axis) with a pixel offset, so it stays put at
## any window size.
static func pin(widget: Control, anchor: Vector2, offset: Vector2, widget_size: Vector2) -> void:
	widget.anchor_left = anchor.x
	widget.anchor_right = anchor.x
	widget.anchor_top = anchor.y
	widget.anchor_bottom = anchor.y
	widget.offset_left = offset.x
	widget.offset_top = offset.y
	widget.offset_right = offset.x + widget_size.x
	widget.offset_bottom = offset.y + widget_size.y
