class_name PixelShape
extends RefCounted
## Helpers for drawing pixel art in code (the HUD, pickups, the tonic): shapes are sets of
## pixels, read from text maps (rows of characters) or from images, and drawn with draw_rect
## one pixel at a time.
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


## A text-map shape recoloured: each pixel gets the colour its character maps to.
static func colored(shape: Dictionary, colors: Dictionary) -> Dictionary:
	var pixels := {}
	for pixel: Vector2i in shape:
		pixels[pixel] = colors[shape[pixel]]
	return pixels


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


## The smallest rectangle holding every pixel of a non-empty shape.
static func bounds_of(shape: Dictionary) -> Rect2i:
	var bounds := Rect2i()
	var is_first := true
	for pixel: Vector2i in shape:
		if is_first:
			bounds = Rect2i(pixel, Vector2i.ONE)
			is_first = false
		else:
			bounds = bounds.expand(pixel).expand(pixel + Vector2i.ONE)
	return bounds


## Draws pixels (Vector2i -> Color) with a one-pixel outline around them, like the game's sprites.
static func draw_outlined(canvas: CanvasItem, pixels: Dictionary, origin: Vector2, outline: Color) -> void:
	for pixel in ring_around(pixels):
		draw_pixel(canvas, origin + Vector2(pixel), outline)
	for pixel: Vector2i in pixels:
		draw_pixel(canvas, origin + Vector2(pixel), pixels[pixel])


## Draws a text map as it is (no added outline), each character in its colour from `colors`.
static func draw_map(canvas: CanvasItem, rows: Array, colors: Dictionary, top_left: Vector2) -> void:
	var pixels := colored(from_rows(rows), colors)
	for pixel: Vector2i in pixels:
		draw_pixel(canvas, top_left + Vector2(pixel), pixels[pixel])


## The HUD's square stone frame, `side` pixels across: a dark outline, stone lit on the top
## and left, and a dark line inside it. Used by the skill slots and the minimap.
static func draw_stone_frame(canvas: CanvasItem, side: int) -> void:
	canvas.draw_rect(Rect2(-1, -1, side + 2, side + 2), ApolloPalette.OUTLINE)
	canvas.draw_rect(Rect2(0, 0, side, side), ApolloPalette.STONE)
	canvas.draw_rect(Rect2(0, 0, side - 1, 1), ApolloPalette.STONE_LIGHT)
	canvas.draw_rect(Rect2(0, 0, 1, side - 1), ApolloPalette.STONE_LIGHT)
	canvas.draw_rect(Rect2(1, 1, side - 2, side - 2), ApolloPalette.OUTLINE)


static func draw_pixel(canvas: CanvasItem, at: Vector2, color: Color) -> void:
	canvas.draw_rect(Rect2(at, Vector2.ONE), color)


static func _touches_outside(pixel: Vector2i, shape: Dictionary) -> bool:
	for side in SIDES:
		if not shape.has(pixel + side):
			return true
	return false
