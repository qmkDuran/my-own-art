class_name EmberTreeScreenLayout
extends RefCounted
## Where things sit on the Ember Tree screen: the stats card down the left, the side panel
## down the right, the zoom hint under the tree, and the room left for the tree between the
## bars and the cards. Everything is anchored to the screen's edges, so it fits any size.

## Space between the screen edge (or a bar) and the cards.
const PAGE_MARGIN := 12.0
const STATS_PANEL_WIDTH := 232.0
const SIDE_PANEL_WIDTH := 256.0
## Gap kept between the opening tree (Stage 1 and the branch names) and the bars and cards.
const TREE_FIT_MARGIN := 8.0


## Emberoo's stats, in the top-left corner under the header.
static func place_stats_panel(panel: Control) -> void:
	panel.position = Vector2(PAGE_MARGIN, EmberTreeFrame.HEADER_HEIGHT + PAGE_MARGIN)


## The info and skill-points cards, down the right edge between the bars.
static func place_side_panel(panel: Control) -> void:
	panel.size.x = SIDE_PANEL_WIDTH
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -(SIDE_PANEL_WIDTH + PAGE_MARGIN)
	panel.offset_right = -PAGE_MARGIN
	panel.offset_top = EmberTreeFrame.HEADER_HEIGHT + PAGE_MARGIN
	panel.offset_bottom = -(EmberTreeFrame.FOOTER_HEIGHT + PAGE_MARGIN)


## A quiet line along the bottom of the tree area, between the two lower branches.
static func place_zoom_hint(hint: Label) -> void:
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE, Control.PRESET_MODE_MINSIZE)
	hint.offset_left = PAGE_MARGIN * 2.0 + STATS_PANEL_WIDTH
	hint.offset_right = -(PAGE_MARGIN * 2.0 + SIDE_PANEL_WIDTH)
	hint.offset_bottom = -(EmberTreeFrame.FOOTER_HEIGHT + TREE_FIT_MARGIN)
	hint.offset_top = hint.offset_bottom - EmberTreeFonts.TEXT_SIZE


## The part of a `screen`-sized page the tree has to itself: between the bars and the two cards.
static func tree_area(screen: Vector2) -> Rect2:
	var left := PAGE_MARGIN * 2.0 + STATS_PANEL_WIDTH
	var right := screen.x - PAGE_MARGIN * 2.0 - SIDE_PANEL_WIDTH
	var top := EmberTreeFrame.HEADER_HEIGHT
	var bottom := screen.y - EmberTreeFrame.FOOTER_HEIGHT
	return Rect2(left, top, right - left, bottom - top).grow(-TREE_FIT_MARGIN)
