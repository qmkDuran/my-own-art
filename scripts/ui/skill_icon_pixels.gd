class_name SkillIconPixels
extends RefCounted
## A skill icon as pixels ready to draw in a SkillSlot (centred in its inner area), and the
## recoloured versions the slot shows: greyed while the skill can't be used, and the bright
## silhouette of the "ready" glow.

## Icon colours at least this bright turn the lightest grey; at least MID_ICON_LUMINANCE the middle one.
const BRIGHT_ICON_LUMINANCE := 0.785
const MID_ICON_LUMINANCE := 0.45

## Icon pixels per texture, so images are read only once: {texture: {pixel: Color}}.
static var _cache: Dictionary = {}


## The icon's visible pixels, placed in slot coordinates and fitted inside `inner_area`.
static func of(icon: Texture2D, inner_area: Rect2i) -> Dictionary:
	if not _cache.has(icon):
		var image := icon.get_image()
		_cache[icon] = _fitted(PixelShape.from_image(image), inner_area) if image != null else {}
	return _cache[icon]


## Desaturated and dimmed: each colour becomes one of three dark Apollo greys by its brightness.
static func greyed(pixels: Dictionary) -> Dictionary:
	var grey := {}
	for pixel: Vector2i in pixels:
		var luminance: float = (pixels[pixel] as Color).get_luminance()
		if luminance >= BRIGHT_ICON_LUMINANCE:
			grey[pixel] = ApolloPalette.GREY
		elif luminance >= MID_ICON_LUMINANCE:
			grey[pixel] = ApolloPalette.STONE_LIGHT
		else:
			grey[pixel] = ApolloPalette.STONE
	return grey


## A flash silhouette: the bright colours white, the rest `flash_color`.
static func flashed(pixels: Dictionary, flash_color: Color) -> Dictionary:
	var lit := {}
	for pixel: Vector2i in pixels:
		var is_bright := (pixels[pixel] as Color).get_luminance() >= BRIGHT_ICON_LUMINANCE
		lit[pixel] = ApolloPalette.WHITE if is_bright else flash_color
	return lit


## Moves the pixels so their bounding box (not the image's, which may have empty margins)
## is centred in the inner area, and drops any pixel that would fall outside it.
static func _fitted(pixels: Dictionary, inner_area: Rect2i) -> Dictionary:
	if pixels.is_empty():
		return pixels
	var bounds := PixelShape.bounds_of(pixels)
	var centring_gap := Vector2(inner_area.size - bounds.size) / 2.0
	var shift := inner_area.position + Vector2i(centring_gap.floor()) - bounds.position
	var fitted := {}
	for pixel: Vector2i in pixels:
		var placed := pixel + shift
		if inner_area.has_point(placed):
			fitted[placed] = pixels[pixel]
	return fitted
