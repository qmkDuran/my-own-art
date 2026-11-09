class_name EmberooFlameMarker
extends RefCounted
## Tells Emberoo's flame pixels apart from his gloves, so an Awakening can turn the flames
## on his ears and tail tip blue while the gloves stay red.
##
## Both are drawn in the same red (with gold highlights), so a palette swap alone can't
## tell them apart. Once per sheet, at load, this finds each patch of red and gold pixels
## and marks the red of the ear-tip and tail-tip patches with FLAME_RED_MARK: a key one
## step off the glove red, invisible on its own. AwakeningPalette always swaps the mark
## back to red (or to blue once Awakened), so what is drawn stays pure Apollo.
## The art files are never changed; the marked copies live only in memory.

const GLOVE_RED := ApolloPalette.RED_LIGHT
const HIGHLIGHT := ApolloPalette.GOLD
## The glove red, one step bluer: only ever used as a key for AwakeningPalette's swap.
const FLAME_RED_MARK := Color(GLOVE_RED.r, GLOVE_RED.g, GLOVE_RED.b + 1.0 / 255.0)
const FRAME_SIZE := CreatureAnimator.FRAME_SIZE
## Ear tips: a small patch (at most this many pixels, this many red) in the top rows,
## left of where a raised fist sits.
const EAR_LOWEST_ROW := 5
const EAR_RIGHTMOST_START := 11
## Tail tip: a small patch in the bottom rows that reaches the frame's left or right edge.
const TAIL_HIGHEST_ROW := 10
const EDGE_COLUMNS := 3
const TIP_MOST_PIXELS := 4
const TIP_MOST_RED := 2
const NEIGHBOURS: Array[Vector2i] = [
	Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, 0),
	Vector2i(1, 0), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1),
]

## Sheet -> its marked copy, shared by every Emberoo sprite (the game's and the Ember Tree's).
static var _marked_sheets: Dictionary[Texture2D, Texture2D] = {}


## Points every frame of `sprite_frames` at the marked copy of its sheet.
static func mark_frames(sprite_frames: SpriteFrames) -> void:
	for animation_name in sprite_frames.get_animation_names():
		for index in sprite_frames.get_frame_count(animation_name):
			var frame := sprite_frames.get_frame_texture(animation_name, index) as AtlasTexture
			if frame != null:
				frame.atlas = marked_sheet(frame.atlas)


static func marked_sheet(sheet: Texture2D) -> Texture2D:
	if _marked_sheets.values().has(sheet):
		return sheet  # already marked
	if not _marked_sheets.has(sheet):
		var image := sheet.get_image()
		image.convert(Image.FORMAT_RGBA8)
		@warning_ignore("integer_division")
		for frame_index in image.get_width() / FRAME_SIZE.x:
			_mark_frame(image, Vector2i(frame_index * FRAME_SIZE.x, 0))
		_marked_sheets[sheet] = ImageTexture.create_from_image(image)
	return _marked_sheets[sheet]


static func _mark_frame(image: Image, corner: Vector2i) -> void:
	for patch in _fire_patches(image, corner):
		if _is_flame_tip(image, patch, corner):
			for pixel in patch:
				if _is_color(image, pixel, GLOVE_RED):
					image.set_pixelv(pixel, FLAME_RED_MARK)


## Every patch of touching red and gold pixels in one frame (as sheet positions).
static func _fire_patches(image: Image, corner: Vector2i) -> Array[Array]:
	var patches: Array[Array] = []
	var seen: Dictionary[Vector2i, bool] = {}
	for y in FRAME_SIZE.y:
		for x in FRAME_SIZE.x:
			var start := corner + Vector2i(x, y)
			if seen.has(start) or not _is_fire(image, start):
				continue
			var patch: Array[Vector2i] = []
			var waiting: Array[Vector2i] = [start]
			seen[start] = true
			while not waiting.is_empty():
				var pixel: Vector2i = waiting.pop_back()
				patch.append(pixel)
				for step in NEIGHBOURS:
					var next := pixel + step
					if not seen.has(next) and _is_inside(next, corner) and _is_fire(image, next):
						seen[next] = true
						waiting.append(next)
			patches.append(patch)
	return patches


## Ear tips and tail tips are small patches with little red; gloves are bigger and redder.
static func _is_flame_tip(image: Image, patch: Array, corner: Vector2i) -> bool:
	var red_count := 0
	var top := FRAME_SIZE.y
	var bottom := 0
	var left := FRAME_SIZE.x
	var right := 0
	for pixel: Vector2i in patch:
		var local := pixel - corner
		top = mini(top, local.y)
		bottom = maxi(bottom, local.y)
		left = mini(left, local.x)
		right = maxi(right, local.x)
		if _is_color(image, pixel, GLOVE_RED):
			red_count += 1
	if patch.size() > TIP_MOST_PIXELS or red_count > TIP_MOST_RED:
		return false
	var is_ear := bottom <= EAR_LOWEST_ROW and left <= EAR_RIGHTMOST_START
	var touches_side := left < EDGE_COLUMNS or right >= FRAME_SIZE.x - EDGE_COLUMNS
	var is_tail := top >= TAIL_HIGHEST_ROW and touches_side
	return is_ear or is_tail


static func _is_fire(image: Image, pixel: Vector2i) -> bool:
	return _is_color(image, pixel, GLOVE_RED) or _is_color(image, pixel, HIGHLIGHT)


static func _is_color(image: Image, pixel: Vector2i, color: Color) -> bool:
	var found := image.get_pixelv(pixel)
	return found.a > 0.0 and found.to_rgba32() | 0xff == color.to_rgba32() | 0xff


static func _is_inside(pixel: Vector2i, corner: Vector2i) -> bool:
	var local := pixel - corner
	return local.x >= 0 and local.y >= 0 and local.x < FRAME_SIZE.x and local.y < FRAME_SIZE.y
