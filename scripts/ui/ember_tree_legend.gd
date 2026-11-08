class_name EmberTreeLegend
extends Control
## A tiny key to the Ember Tree's shapes and glows, drawn with the same shapes and
## colours as the tree itself (see EmberTreeCanvas), so the two always match.
##
## Row one names the shapes; row two names the states.

const Kind := EmberTreeNode.Kind

const ROW_HEIGHT := 14.0
const SWATCH_RADIUS := 5.0
## Space between a swatch and its word, and between one entry and the next.
const SWATCH_GAP := 4.0
const ENTRY_GAP := 10.0
const FONT_SIZE := 9
const CAP_HEIGHT_RATIO := 0.72

## Each row: [word, shape, state]. Shape rows show the "available" look; state rows use coals.
const ROWS := [
	[["Skill", Kind.SKILL, "available"], ["Stat", Kind.STAT, "available"]],
	[["Ignited", Kind.STAT, "learned"], ["Can ignite", Kind.STAT, "available"], ["Locked", Kind.STAT, "locked"]],
]

var _font: Font


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = ThemeDB.fallback_font
	custom_minimum_size.y = ROW_HEIGHT * ROWS.size()


func _draw() -> void:
	for row_index in ROWS.size():
		var x := SWATCH_RADIUS
		var middle_y := ROW_HEIGHT * (row_index + 0.5)
		for entry: Array in ROWS[row_index]:
			var word: String = entry[0]
			_draw_swatch(Vector2(x, middle_y), entry[1], entry[2])
			var text_x := x + SWATCH_RADIUS + SWATCH_GAP
			draw_string(_font, Vector2(text_x, middle_y + FONT_SIZE * CAP_HEIGHT_RATIO / 2.0), word, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, EmberTreePalette.CREAM)
			x = text_x + _font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x + ENTRY_GAP + SWATCH_RADIUS


func _draw_swatch(centre: Vector2, kind: Kind, state: String) -> void:
	var fill: Color = EmberTreePalette.NODE_FILL[state]
	var edge: Color = EmberTreePalette.NODE_EDGE[state]
	if state == "learned":
		draw_circle(centre, SWATCH_RADIUS + 2.5, Color(EmberTreePalette.ORANGE, 0.3))
	if kind == Kind.STAT:
		draw_circle(centre, SWATCH_RADIUS, fill)
		draw_arc(centre, SWATCH_RADIUS, 0.0, TAU, 24, edge, 1.5)
		return
	var corners := PackedVector2Array([
		centre + Vector2(0, -SWATCH_RADIUS), centre + Vector2(SWATCH_RADIUS, 0),
		centre + Vector2(0, SWATCH_RADIUS), centre + Vector2(-SWATCH_RADIUS, 0),
	])
	draw_colored_polygon(corners, fill)
	corners.append(corners[0])
	draw_polyline(corners, edge, 1.5)
