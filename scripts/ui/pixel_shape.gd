class_name PixelShape
extends RefCounted
## Helpers for drawing the HUD's pixel art: shapes are sets of pixels, read from text maps
## (rows of characters) or from images, and drawn with draw_rect one pixel at a time.
##
## A "shape" is a Dictionary whose keys are Vector2i pixels (the values say what each pixel is:
## a character from the map, or a Color).

const SIDES: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]


## The pixels of a text map, each mapped to its character. '.' is empty.
static func from_rows(rows: Array) -> Dictionary:
	var shape := {}
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			if row[x] != ".":
				shape[Vector2i(x, y)] = row[x]
	return shape


## The visible pixels of an image, each mapped to its colour.
static func from_image(source: Image) -> Dictionary:
	var image := source
	if image.is_compressed():
		image = source.duplicate()
		image.decompress()
	var shape := {}
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			if color.a > 0.5:
				shape[Vector2i(x, y)] = Color(color, 1.0)
	return shape


## How many steps each pixel is from the shape's edge: 0 on the rim, 1 just inside, and so on.
static func depths(shape: Dictionary) -> Dictionary:
	var depth_of := {}
	var remaining := shape.duplicate()
	var depth := 0
	while not remaining.is_empty():
		var rim: Array[Vector2i] = []
		for pixel: Vector2i in remaining:
			if _touches_outside(pixel, remaining):
				rim.append(pixel)
		for pixel in rim:
			depth_of[pixel] = depth
			remaining.erase(pixel)
		depth += 1
	return depth_of


## The pixels just outside the shape (left, right, above or below one of its pixels).
static func ring_around(shape: Dictionary) -> Array[Vector2i]:
	var ring := {}
	for pixel: Vector2i in shape:
		for side in SIDES:
			if not shape.has(pixel + side):
				ring[pixel + side] = true
	var pixels: Array[Vector2i] = []
	pixels.assign(ring.keys())
	return pixels


## Draws pixels (Vector2i -> Color) with a one-pixel outline around them, like the game's sprites.
static func draw_outlined(canvas: CanvasItem, pixels: Dictionary, origin: Vector2, outline: Color) -> void:
	for pixel in ring_around(pixels):
		draw_pixel(canvas, origin + Vector2(pixel), outline)
	for pixel: Vector2i in pixels:
		draw_pixel(canvas, origin + Vector2(pixel), pixels[pixel])


static func draw_pixel(canvas: CanvasItem, at: Vector2, color: Color) -> void:
	canvas.draw_rect(Rect2(at, Vector2.ONE), color)


static func _touches_outside(pixel: Vector2i, shape: Dictionary) -> bool:
	for side in SIDES:
		if not shape.has(pixel + side):
			return true
	return false
