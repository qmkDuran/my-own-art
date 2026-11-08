class_name HealthHeartColors
extends RefCounted
## Works out the colour of every pixel of the HUD heart (see HealthHeart) for one frame:
## red up to the health left, dark coal above it, and on top of that the heart's moments:
## - ghost: health just lost, still showing as a lighter red band until it drains away;
## - healed: the rows just gained, tinted green for a moment;
## - hit flash: the whole fill turns pale for a blink;
## - beat: (low health) the heart grows by one pixel all round.

## Pixels on the left lobe that catch the light, when filled.
const SHINE_PIXELS: Array[Vector2i] = [Vector2i(4, 3), Vector2i(5, 3), Vector2i(3, 4), Vector2i(3, 5), Vector2i(4, 4)]
## Rim pixels right of this column or below this row are in shadow (darker red).
const SHADOW_FROM := Vector2(HealthHeart.HEART_SIZE.x * 0.55, HealthHeart.HEART_SIZE.y * 0.6)
## Shares are compared with this much slack, so a full share never leaves a row unfilled.
const ROW_SLACK := 0.001

## Share of health left (0 to 1).
var share_left: float = 1.0
## Share the ghost band reaches up to (at least share_left).
var ghost_share: float = 1.0
## Share before the last heal, while the heal tint shows; -1 when it doesn't.
var healed_from_share: float = -1.0
var is_hit_flashing: bool = false
var is_beating: bool = false

var _shape: Dictionary
var _depths: Dictionary


func _init(shape: Dictionary) -> void:
	_shape = shape
	_depths = PixelShape.depths(shape)


## Every heart pixel (Vector2i) mapped to its colour, ready for PixelShape.draw_outlined.
func paint() -> Dictionary:
	var filled_from := _first_row(share_left)
	var ghost_from := _first_row(maxf(ghost_share, share_left))
	var healed_until := _first_row(healed_from_share) if healed_from_share >= 0.0 else filled_from
	var surface_row := ceili(filled_from) if share_left < 1.0 else -1
	var colors := {}
	for pixel: Vector2i in _shape:
		var is_rim: bool = _depths[pixel] == 0
		if pixel.y >= filled_from - ROW_SLACK:
			colors[pixel] = _filled_color(pixel, is_rim, surface_row, pixel.y < healed_until - ROW_SLACK)
		elif pixel.y >= ghost_from - ROW_SLACK:
			colors[pixel] = ApolloPalette.RED if is_rim else ApolloPalette.RED_LIGHT
		else:
			colors[pixel] = ApolloPalette.COAL_DARK if is_rim else ApolloPalette.COAL
	if is_beating:
		_grow_one_pixel(colors, filled_from)
	return colors


func _filled_color(pixel: Vector2i, is_rim: bool, surface_row: int, is_just_healed: bool) -> Color:
	if is_hit_flashing:
		return ApolloPalette.GREY_LIGHT if is_rim else ApolloPalette.WHITE
	if is_just_healed:
		return ApolloPalette.GREEN if is_rim else ApolloPalette.GREEN_LIGHT
	if pixel.y == surface_row or pixel in SHINE_PIXELS:
		return ApolloPalette.RED_LIGHT
	if is_rim and (pixel.x > SHADOW_FROM.x or pixel.y > SHADOW_FROM.y):
		return ApolloPalette.WINE
	return ApolloPalette.RED


## Adds a ring of rim-coloured pixels round the heart, so it reads one pixel bigger.
func _grow_one_pixel(colors: Dictionary, filled_from: float) -> void:
	for pixel in PixelShape.ring_around(_shape):
		colors[pixel] = ApolloPalette.WINE if pixel.y >= filled_from - ROW_SLACK else ApolloPalette.BRICK


## The first row that is filled for a share of the heart (the heart drains from the top).
static func _first_row(share: float) -> float:
	return HealthHeart.HEART_SIZE.y * (1.0 - share)
