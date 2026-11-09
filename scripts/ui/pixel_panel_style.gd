@tool
class_name PixelPanelStyle
extends StyleBox
## The one panel look every card, button and toast in the game shares: a pixel-art frame
## with depth, drawn in whole "frame pixels" (`unit` canvas pixels each, one game pixel on
## the 2× UI canvas and on the HUD's half-size cards):
##
## - a hard drop shadow one frame pixel down and right,
## - a dark outline with its corner pixels cut off (a one-step rounded corner, never a
##   sharp right angle),
## - a bevel inside it: lit (`border_color`) on the top and left, shaded
##   (`border_dark_color`) on the bottom and right; `is_inset` swaps the two, so a pressed
##   button looks pushed in,
## - the fill.
##
## Property names follow StyleBoxFlat's (`bg_color`, `border_color`) so code that tweaks a
## duplicate of a style reads the same. All colours come from ApolloPalette.

## Canvas pixels per frame pixel.
@export var unit: int = 2
@export var bg_color: Color = ApolloPalette.OUTLINE
## The lit bevel, on the top and left.
@export var border_color: Color = ApolloPalette.STONE_LIGHT
## The shaded bevel, on the bottom and right.
@export var border_dark_color: Color = ApolloPalette.SLATE
@export var outline_color: Color = ApolloPalette.OUTLINE
## Fully transparent for no shadow (e.g. a badge sitting inside a card).
@export var shadow_color: Color = PixelShape.DROP_SHADOW
## Pushed in: shaded on the top and left, lit on the bottom and right.
@export var is_inset: bool = false


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	var u := float(unit)
	if shadow_color.a > 0.0:
		_draw_shadow(to_canvas_item, rect, u)
	# Every part is its own strip, never drawn over another, so a see-through fill (or a
	# card fading in) never shows the frame's colours through it.
	_draw_ring(to_canvas_item, rect, u, outline_color, outline_color)
	var bevel := rect.grow(-u)
	var lit := border_dark_color if is_inset else border_color
	var shaded := border_color if is_inset else border_dark_color
	_draw_ring(to_canvas_item, bevel, u, lit, shaded)
	# The bevel's corners belong to the rounded outline (the outline's own corners stay empty).
	for corner: Vector2 in [bevel.position, Vector2(bevel.end.x - u, bevel.position.y),
			Vector2(bevel.position.x, bevel.end.y - u), bevel.end - Vector2(u, u)]:
		_add_rect(to_canvas_item, Rect2(corner, Vector2(u, u)), outline_color)
	_add_rect(to_canvas_item, bevel.grow(-u), bg_color)


## A ring `u` thick inside `rect`, without its corners: `top_left` on the top and left sides,
## `bottom_right` on the bottom and right.
static func _draw_ring(to_canvas_item: RID, rect: Rect2, u: float, top_left: Color, bottom_right: Color) -> void:
	var long_x := rect.size.x - 2.0 * u
	var long_y := rect.size.y - 2.0 * u
	_add_rect(to_canvas_item, Rect2(rect.position.x + u, rect.position.y, long_x, u), top_left)
	_add_rect(to_canvas_item, Rect2(rect.position.x, rect.position.y + u, u, long_y), top_left)
	_add_rect(to_canvas_item, Rect2(rect.position.x + u, rect.end.y - u, long_x, u), bottom_right)
	_add_rect(to_canvas_item, Rect2(rect.end.x - u, rect.position.y + u, u, long_y), bottom_right)


## A hard shadow one frame pixel down and right, only where the panel doesn't cover it
## (so a see-through fill never shows a darker band).
func _draw_shadow(to_canvas_item: RID, rect: Rect2, u: float) -> void:
	_add_rect(to_canvas_item, Rect2(rect.position.x + u, rect.end.y, rect.size.x - u, u), shadow_color)
	_add_rect(to_canvas_item, Rect2(rect.end.x, rect.position.y + u, u, rect.size.y - u), shadow_color)
	# The corners are cut, so the shadow fills the notches the outline left.
	_add_rect(to_canvas_item, Rect2(rect.end.x - u, rect.end.y - u, u, u), shadow_color)


static func _add_rect(to_canvas_item: RID, rect: Rect2, color: Color) -> void:
	if rect.size.x > 0.0 and rect.size.y > 0.0:
		RenderingServer.canvas_item_add_rect(to_canvas_item, rect, color)
