class_name HudTrainerPicture
extends RefCounted
## One view of the HUD trainer, ready to draw: its pixels, a dark outline and a gold one around
## that, placed so the feet's centre sits on the node's position.

var pixels: Dictionary
var dark_ring: Array[Vector2i]
var gold_ring: Array[Vector2i]
## Top-left of the picture, from the node (the feet's centre).
var offset: Vector2
## The highest row with a pixel (the top of the head).
var top_row: int


static func from_texture(texture: Texture2D, is_squashed: bool) -> HudTrainerPicture:
	var image := texture.get_image()
	if image == null:
		return null
	if is_squashed:
		image = image.duplicate()
		image.decompress()
		image.resize(maxi(1, ceili(image.get_width() / 2.0)), image.get_height(), Image.INTERPOLATE_NEAREST)
	var picture := HudTrainerPicture.new()
	picture.pixels = PixelShape.from_image(image)
	picture.dark_ring = PixelShape.ring_around(picture.pixels)
	var body := picture.pixels.duplicate()
	for pixel in picture.dark_ring:
		body[pixel] = true
	picture.gold_ring = PixelShape.ring_around(body)
	picture._place_feet()
	return picture


func draw(canvas: CanvasItem, origin: Vector2) -> void:
	for pixel in gold_ring:
		PixelShape.draw_pixel(canvas, origin + Vector2(pixel), ApolloPalette.GOLD)
	for pixel in dark_ring:
		PixelShape.draw_pixel(canvas, origin + Vector2(pixel), ApolloPalette.OUTLINE)
	for pixel: Vector2i in pixels:
		PixelShape.draw_pixel(canvas, origin + Vector2(pixel), pixels[pixel])


## Centres the used columns on the node and puts the lowest row on it.
func _place_feet() -> void:
	var left := 1 << 30
	var right := -(1 << 30)
	var bottom := -(1 << 30)
	top_row = 1 << 30
	for pixel: Vector2i in pixels:
		left = mini(left, pixel.x)
		right = maxi(right, pixel.x)
		bottom = maxi(bottom, pixel.y)
		top_row = mini(top_row, pixel.y)
	offset = Vector2(-floori((left + right + 1) / 2.0), -bottom)
