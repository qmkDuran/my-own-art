class_name AshGuardShimmer
extends Node2D
## Ash Guard's look: a curved wall of stone-grey ash in front of the guard, with orange
## embers flickering through it, drawn in code pixel by pixel.
##
## A child of the guarding creature, so it moves with him. It sits in front of the sprite
## when he faces the camera, behind it when he faces away. Free it when the guard drops.

## Coolest to hottest; the ash is mostly grey, the cracks glow.
const ASH_COLORS: Array[Color] = [ApolloPalette.STONE, ApolloPalette.STONE_LIGHT, ApolloPalette.GREY]
const EMBER_COLORS: Array[Color] = [ApolloPalette.ORANGE_DARK, ApolloPalette.ORANGE, ApolloPalette.GOLD]
## Height of the gloves above the feet, where the wall is centred (negative is up).
const GLOVE_HEIGHT := -7.0
## How far in front of the body the wall stands, and how far it curves round each side.
const DISTANCE := 7.0
const HALF_ARC := deg_to_rad(55.0)
## How tall the wall is, in pixels.
const WALL_HEIGHT := 9
## Share of the wall's pixels that glow orange at any moment.
const EMBER_SHARE := 0.22
## Times per second the flicker picks new pixels to glow.
const FLICKER_RATE := 14.0
## How long the wall takes to rise when the guard goes up.
const RISE_TIME := 0.08

var _facing := Vector2.RIGHT
var _elapsed: float = 0.0


## Turns the wall to stand in `direction` (a unit vector) from the guard.
func face(direction: Vector2) -> void:
	_facing = direction.normalized() if direction != Vector2.ZERO else Vector2.RIGHT
	z_index = 1 if _facing.y >= 0.0 else -1
	position = Vector2(0, GLOVE_HEIGHT)


func _process(delta: float) -> void:
	_elapsed += delta
	queue_redraw()


func _draw() -> void:
	var rise := clampf(_elapsed / RISE_TIME, 0.0, 1.0)
	var flicker_step := floori(_elapsed * FLICKER_RATE)
	var shown_height := maxi(1, roundi(WALL_HEIGHT * rise))
	var columns := _column_positions()
	for column_index in columns.size():
		for row in shown_height:
			var cell := (columns[column_index] + Vector2(0, row - shown_height / 2.0)).floor()
			draw_rect(Rect2(cell, Vector2.ONE), _color_at(column_index, row, flicker_step))


## One pixel column per step along the arc in front of the guard.
func _column_positions() -> PackedVector2Array:
	var columns := PackedVector2Array()
	var steps := ceili(DISTANCE * HALF_ARC * 2.0)
	var last := Vector2.INF
	for step in steps + 1:
		var angle := _facing.angle() - HALF_ARC + HALF_ARC * 2.0 * step / steps
		var column := (Vector2.from_angle(angle) * DISTANCE).round()
		if column != last:
			columns.append(column)
			last = column
	return columns


## Mostly ash, darker at the wall's edges; a changing few pixels glow as embers.
func _color_at(column_index: int, row: int, flicker_step: int) -> Color:
	var noise := _hash_noise(column_index, row, flicker_step)
	if noise < EMBER_SHARE:
		return EMBER_COLORS[floori(noise / EMBER_SHARE * EMBER_COLORS.size())]
	var edge := row == 0 or row == WALL_HEIGHT - 1
	return ASH_COLORS[0] if edge else ASH_COLORS[1 + (column_index + row) % 2]


## A steady pseudo-random 0..1 per pixel and flicker step, so the glow jumps, not crawls.
static func _hash_noise(x: int, y: int, step: int) -> float:
	var mixed := absi(hash(Vector3i(x, y, step)))
	return float(mixed % 1000) / 1000.0
