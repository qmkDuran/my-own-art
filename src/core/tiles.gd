class_name Tiles
extends RefCounted
## World grid constants and conversions between tile and pixel space.

const SIZE := 32


## Converts a [x, y] tile coordinate from data files (floats allowed) to the pixel centre of that tile.
static func to_pixels(tile_pos: Variant) -> Vector2:
	if tile_pos is Array and (tile_pos as Array).size() >= 2:
		var arr: Array = tile_pos
		return Vector2((float(arr[0]) + 0.5) * SIZE, (float(arr[1]) + 0.5) * SIZE)
	return Vector2.ZERO


static func vec2(value: Variant, fallback: Vector2 = Vector2.ZERO) -> Vector2:
	if value is Array and (value as Array).size() >= 2:
		var arr: Array = value
		return Vector2(float(arr[0]), float(arr[1]))
	return fallback
