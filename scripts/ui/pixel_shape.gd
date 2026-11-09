class_name PixelShape
extends RefCounted
## Helpers for drawing pixel art in code (the HUD, pickups, the tonic): shapes are sets of
## pixels, read from text maps (rows of characters) or from images, and drawn with draw_rect
## one pixel at a time.
##
## A "shape" is a Dictionary whose keys are Vector2i pixels (the values say what each pixel is:
## a character from the map, or a Color).

const SIDES: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
## The HUD's hard drop shadow colour (the same as PixelPanelStyle's).
const DROP_SHADOW := Color(ApolloPalette.OUTLINE, 0.6)


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


## Like draw_outlined, over a hard drop shadow one pixel down and right (the HUD's depth:
## the same shadow as its frames and cards).
static func draw_outlined_with_shadow(canvas: CanvasItem, pixels: Dictionary, origin: Vector2, outline: Color) -> void:
	var ring := ring_around(pixels)
	var covered := {}
	for pixel: Vector2i in pixels:
		covered[pixel] = true
	for pixel in ring:
		covered[pixel] = true
	for pixel: Vector2i in covered:
		if not covered.has(pixel + Vector2i.ONE):
			draw_pixel(canvas, origin + Vector2(pixel + Vector2i.ONE), DROP_SHADOW)
	draw_outlined(canvas, pixels, origin, outline)


## Draws a text map as it is (no added outline), each character in its colour from `colors`.
static func draw_map(canvas: CanvasItem, rows: Array, colors: Dictionary, top_left: Vector2) -> void:
	var pixels := colored(from_rows(rows), colors)
	for pixel: Vector2i in pixels:
		draw_pixel(canvas, top_left + Vector2(pixel), pixels[pixel])


## The HUD's square stone frame, `side` pixels across, in the same build as every panel
## (PixelPanelStyle): a drop shadow down and right, a dark outline with its corners cut,
## stone lit on the top and left and shaded on the bottom and right, and a dark line inside
## it. Used by the skill slots and the minimap.
static func draw_stone_frame(canvas: CanvasItem, side: int) -> void:
	draw_drop_shadow(canvas, Rect2(-1, -1, side + 2, side + 2))
	draw_rounded_outline(canvas, Rect2(-1, -1, side + 2, side + 2), ApolloPalette.OUTLINE)
	canvas.draw_rect(Rect2(0, 0, side, side), ApolloPalette.SLATE)
	canvas.draw_rect(Rect2(0, 0, side - 1, side - 1), ApolloPalette.STONE_LIGHT)
	canvas.draw_rect(Rect2(1, 1, side - 2, side - 2), ApolloPalette.OUTLINE)


## A rectangle in `color` without its four corner pixels (a one-step rounded corner).
static func draw_rounded_outline(canvas: CanvasItem, rect: Rect2, color: Color) -> void:
	canvas.draw_rect(Rect2(rect.position.x + 1, rect.position.y, rect.size.x - 2, rect.size.y), color)
	canvas.draw_rect(Rect2(rect.position.x, rect.position.y + 1, rect.size.x, rect.size.y - 2), color)


## A one-pixel ring just inside `rect`, without its corner pixels (e.g. a hover highlight
## over a frame's outline).
static func draw_rounded_ring(canvas: CanvasItem, rect: Rect2, color: Color) -> void:
	canvas.draw_rect(Rect2(rect.position.x + 1, rect.position.y, rect.size.x - 2, 1), color)
	canvas.draw_rect(Rect2(rect.position.x + 1, rect.end.y - 1, rect.size.x - 2, 1), color)
	canvas.draw_rect(Rect2(rect.position.x, rect.position.y + 1, 1, rect.size.y - 2), color)
	canvas.draw_rect(Rect2(rect.end.x - 1, rect.position.y + 1, 1, rect.size.y - 2), color)


## The HUD's hard drop shadow: one pixel down and right of `rect`, corners cut like the outline.
static func draw_drop_shadow(canvas: CanvasItem, rect: Rect2) -> void:
	canvas.draw_rect(Rect2(rect.position.x + 1, rect.end.y, rect.size.x - 1, 1), DROP_SHADOW)
	canvas.draw_rect(Rect2(rect.end.x, rect.position.y + 1, 1, rect.size.y - 1), DROP_SHADOW)
	canvas.draw_rect(Rect2(rect.end.x - 1, rect.end.y - 1, 1, 1), DROP_SHADOW)


static func draw_pixel(canvas: CanvasItem, at: Vector2, color: Color) -> void:
	canvas.draw_rect(Rect2(at, Vector2.ONE), color)


static func _touches_outside(pixel: Vector2i, shape: Dictionary) -> bool:
	for side in SIDES:
		if not shape.has(pixel + side):
			return true
	return false
