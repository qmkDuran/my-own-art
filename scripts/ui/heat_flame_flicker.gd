class_name HeatFlameFlicker
extends RefCounted
## The lit flame's gentle flicker (see HeatFlame): every 0.12 to 0.2 seconds it switches to
## another of three shapes. While the flame is partly lit, a pixel or two lick up above the
## fire's surface; when it is fully lit, a tip loses its top pixel for a moment.

const SHORTEST_SECONDS := 0.12
const LONGEST_SECONDS := 0.2
## For each shape: the columns where a lick of fire rises one pixel above the surface.
const LICK_COLUMNS: Array = [[], [8, 16], [12, 19]]
## For each shape: the tip pixels that go out while the flame is fully lit.
const TIPS_OUT: Array = [[], [Vector2i(12, 0)], [Vector2i(21, 4), Vector2i(4, 7)]]

var _shape_index: int = 0
var _seconds_to_next: float = 0.0


## Moves the flicker on. Returns true when it switched shape (the flame must redraw).
func advance(delta: float) -> bool:
	_seconds_to_next -= delta
	if _seconds_to_next > 0.0:
		return false
	_seconds_to_next = randf_range(SHORTEST_SECONDS, LONGEST_SECONDS)
	_shape_index = (_shape_index + randi_range(1, LICK_COLUMNS.size() - 1)) % LICK_COLUMNS.size()
	return true


## Changes the flame's pixel colours to the current flicker shape. `surface_row` is the top
## lit row (-1 when the flame is fully lit).
func apply(colors: Dictionary, surface_row: int) -> void:
	if surface_row < 0:
		for tip: Vector2i in TIPS_OUT[_shape_index]:
			colors.erase(tip)
		return
	for column: int in LICK_COLUMNS[_shape_index]:
		var lick := Vector2i(column, surface_row - 1)
		if colors.has(lick):
			colors[lick] = ApolloPalette.ORANGE
