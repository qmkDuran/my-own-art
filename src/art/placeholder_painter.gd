class_name PlaceholderPainter
extends RefCounted
## Paints simple placeholder pixel art from a spec dictionary (the "placeholder" field in
## data/art.json). Real art replaces these by adding a PNG at the entry's "path".
##
## Shapes: character, hair (a hair-only layer in the character frame layout), dog, portrait, tile, block, tree, lamp_post, pile, flat, icon, shadow, missing.

const OUTLINE := Color("14121c")


static func paint(spec: Dictionary, seed_text: String = "") -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(seed_text)
	match String(spec.get("shape", "block")):
		"character":
			return _character_sheet(spec)
		"hair":
			return _hair_sheet(spec)
		"dog":
			return _dog_sheet(spec)
		"portrait":
			return _portrait(spec)
		"tile":
			return _tile(spec, rng)
		"tree":
			return _tree(spec)
		"lamp_post":
			return _lamp_post(spec)
		"pile":
			return _pile(spec, rng)
		"flat":
			return _flat(spec)
		"icon":
			return _icon(spec)
		"shadow":
			return _shadow(spec)
		"missing":
			var image := _blank(Vector2i(32, 32))
			image.fill(Color.MAGENTA)
			return image
	return _block(spec)


# --- Characters ----------------------------------------------------------------

## Sheet of 4 walk frames (columns) x 3 directions (rows: down, up, side), 32x64 per frame.
static func _character_sheet(spec: Dictionary) -> Image:
	var frame := Vector2i(32, 64)
	var image := _blank(Vector2i(frame.x * 4, frame.y * 3))
	for row in 3:
		for column in 4:
			_character_frame(image, Vector2i(column * frame.x, row * frame.y), row, column, spec)
	_outline(image)
	return image


static func _character_frame(image: Image, origin: Vector2i, direction: int, frame: int, spec: Dictionary) -> void:
	var skin := _color(spec, "skin", "c89070")
	var hair := _color(spec, "hair", "3a2a20")
	var shirt := _color(spec, "shirt", "5070a0")
	var pants := _color(spec, "pants", "303848")
	var shoes := _color(spec, "shoes", "201818")
	var style := String(spec.get("hair_style", "short"))
	var bob := 1 if frame % 2 == 1 else 0
	var o := origin + Vector2i(0, bob)
	var stride: int = [0, 3, 0, -3][frame]
	# Legs and shoes.
	if direction == 2:
		_rect(image, o + Vector2i(13 + stride / 2, 46), Vector2i(5, 15), pants.darkened(0.15))
		_rect(image, o + Vector2i(14 - stride / 2, 46), Vector2i(5, 15), pants)
		_rect(image, o + Vector2i(14 - stride / 2, 59), Vector2i(7, 3), shoes)
	else:
		var left_lift := 2 if frame == 1 else 0
		var right_lift := 2 if frame == 3 else 0
		_rect(image, o + Vector2i(10, 46), Vector2i(5, 15 - left_lift), pants)
		_rect(image, o + Vector2i(17, 46), Vector2i(5, 15 - right_lift), pants)
		_rect(image, o + Vector2i(10, 59 - left_lift), Vector2i(5, 3), shoes)
		_rect(image, o + Vector2i(17, 59 - right_lift), Vector2i(5, 3), shoes)
	# Torso, arms, hands.
	var torso_x := 11 if direction == 2 else 9
	var torso_w := 11 if direction == 2 else 14
	_rect(image, o + Vector2i(torso_x, 27), Vector2i(torso_w, 20), shirt)
	_rect(image, o + Vector2i(torso_x, 41), Vector2i(torso_w, 6), shirt.darkened(0.15))
	if direction == 2:
		_rect(image, o + Vector2i(14 + stride / 2, 29), Vector2i(4, 14), shirt.darkened(0.2))
		_rect(image, o + Vector2i(14 + stride / 2, 43), Vector2i(4, 3), skin)
	else:
		_rect(image, o + Vector2i(6, 28), Vector2i(3, 15), shirt.darkened(0.2))
		_rect(image, o + Vector2i(23, 28), Vector2i(3, 15), shirt.darkened(0.2))
		_rect(image, o + Vector2i(6, 43), Vector2i(3, 3), skin)
		_rect(image, o + Vector2i(23, 43), Vector2i(3, 3), skin)
	# Neck and head.
	_rect(image, o + Vector2i(14, 24), Vector2i(4, 4), skin.darkened(0.1))
	_ellipse(image, Rect2i(o + Vector2i(9, 7), Vector2i(14, 18)), skin)
	_hair(image, o, direction, style, hair, spec)
	if direction == 0:
		_rect(image, o + Vector2i(12, 16), Vector2i(2, 2), OUTLINE)
		_rect(image, o + Vector2i(18, 16), Vector2i(2, 2), OUTLINE)
		_rect(image, o + Vector2i(14, 21), Vector2i(4, 1), skin.darkened(0.3))
	elif direction == 2:
		_rect(image, o + Vector2i(19, 16), Vector2i(2, 2), OUTLINE)
		_rect(image, o + Vector2i(22, 18), Vector2i(1, 2), skin.darkened(0.2))


## A hair layer: same 4x3 frame layout (and walk bob) as _character_sheet, hair pixels only.
static func _hair_sheet(spec: Dictionary) -> Image:
	var frame := Vector2i(32, 64)
	var image := _blank(Vector2i(frame.x * 4, frame.y * 3))
	var hair := _color(spec, "hair", "3a2a20")
	var style := String(spec.get("hair_style", "short"))
	for row in 3:
		for column in 4:
			var bob := 1 if column % 2 == 1 else 0
			_hair(image, Vector2i(column * frame.x, row * frame.y + bob), row, style, hair, spec)
	_outline(image)
	return image


static func _hair(image: Image, o: Vector2i, direction: int, style: String, hair: Color, spec: Dictionary) -> void:
	match style:
		"none":
			return
		"buzz":
			_ellipse(image, Rect2i(o + Vector2i(9, 6), Vector2i(14, 7)), hair)
			if direction == 1:
				_rect(image, o + Vector2i(9, 9), Vector2i(14, 9), hair)
			elif direction == 2:
				_rect(image, o + Vector2i(9, 9), Vector2i(5, 6), hair)
			return
		"curly":
			for bump: Vector2i in [Vector2i(7, 5), Vector2i(12, 3), Vector2i(17, 3), Vector2i(21, 6), Vector2i(7, 10), Vector2i(21, 10)]:
				_ellipse(image, Rect2i(o + bump, Vector2i(7, 7)), hair)
			if direction == 1:
				_rect(image, o + Vector2i(8, 8), Vector2i(16, 13), hair)
			elif direction == 2:
				_rect(image, o + Vector2i(8, 8), Vector2i(8, 12), hair)
			return
		"bob":
			_ellipse(image, Rect2i(o + Vector2i(8, 4), Vector2i(16, 10)), hair)
			if direction == 1:
				_rect(image, o + Vector2i(8, 8), Vector2i(16, 16), hair)
			elif direction == 2:
				_rect(image, o + Vector2i(8, 8), Vector2i(9, 16), hair)
			else:
				_rect(image, o + Vector2i(8, 8), Vector2i(3, 15), hair)
				_rect(image, o + Vector2i(21, 8), Vector2i(3, 15), hair)
			return
		"hood":
			var hood := _color(spec, "hood", "2a2a30")
			_ellipse(image, Rect2i(o + Vector2i(8, 5), Vector2i(16, 21)), hood)
			if direction == 0:
				_ellipse(image, Rect2i(o + Vector2i(11, 11), Vector2i(10, 13)), _color(spec, "skin", "c89070"))
				_rect(image, o + Vector2i(12, 16), Vector2i(2, 2), OUTLINE)
				_rect(image, o + Vector2i(18, 16), Vector2i(2, 2), OUTLINE)
			elif direction == 2:
				_rect(image, o + Vector2i(17, 11), Vector2i(6, 12), _color(spec, "skin", "c89070"))
				_rect(image, o + Vector2i(19, 16), Vector2i(2, 2), OUTLINE)
			return
		"cap":
			_rect(image, o + Vector2i(9, 6), Vector2i(14, 6), hair)
			if direction == 0:
				_rect(image, o + Vector2i(9, 11), Vector2i(14, 2), hair.darkened(0.3))
			elif direction == 2:
				_rect(image, o + Vector2i(18, 11), Vector2i(7, 2), hair.darkened(0.3))
			return
	_ellipse(image, Rect2i(o + Vector2i(8, 5), Vector2i(16, 9)), hair)
	if direction == 1:
		_rect(image, o + Vector2i(9, 8), Vector2i(14, 14), hair)
	elif direction == 2:
		_rect(image, o + Vector2i(9, 8), Vector2i(7, 10), hair)
	else:
		_rect(image, o + Vector2i(9, 8), Vector2i(2, 6), hair)
		_rect(image, o + Vector2i(21, 8), Vector2i(2, 6), hair)
	if style == "long":
		var back_x := 8 if direction != 2 else 8
		var back_w := 16 if direction == 1 else (8 if direction == 2 else 3)
		_rect(image, o + Vector2i(back_x, 12), Vector2i(back_w, 18), hair)
		if direction == 0:
			_rect(image, o + Vector2i(21, 12), Vector2i(3, 18), hair)
	elif style == "bun":
		_ellipse(image, Rect2i(o + Vector2i(12, 1), Vector2i(8, 7)), hair)


## Sheet of 4 frames x 3 rows, 48x32 per frame; all rows show the side view.
static func _dog_sheet(spec: Dictionary) -> Image:
	var frame := Vector2i(48, 32)
	var fur := _color(spec, "fur", "8a6a48")
	var image := _blank(Vector2i(frame.x * 4, frame.y * 3))
	for row in 3:
		for column in 4:
			var o := Vector2i(column * frame.x, row * frame.y)
			var step: int = [0, 2, 0, -2][column]
			_rect(image, o + Vector2i(12 + step, 20), Vector2i(3, 10), fur.darkened(0.25))
			_rect(image, o + Vector2i(17 - step, 20), Vector2i(3, 10), fur.darkened(0.1))
			_rect(image, o + Vector2i(30 - step, 20), Vector2i(3, 10), fur.darkened(0.25))
			_rect(image, o + Vector2i(35 + step, 20), Vector2i(3, 10), fur.darkened(0.1))
			_ellipse(image, Rect2i(o + Vector2i(9, 10), Vector2i(31, 14)), fur)
			_rect(image, o + Vector2i(4, 9 + abs(step) / 2), Vector2i(7, 3), fur.darkened(0.1))
			_ellipse(image, Rect2i(o + Vector2i(34, 4), Vector2i(12, 11)), fur)
			_rect(image, o + Vector2i(42, 9), Vector2i(5, 4), fur.lightened(0.1))
			_rect(image, o + Vector2i(35, 2), Vector2i(3, 5), fur.darkened(0.3))
			_rect(image, o + Vector2i(40, 7), Vector2i(2, 2), OUTLINE)
			_rect(image, o + Vector2i(46, 9), Vector2i(2, 2), OUTLINE)
	_outline(image)
	return image


static func _portrait(spec: Dictionary) -> Image:
	var image := _blank(Vector2i(128, 128))
	image.fill(_color(spec, "bg", "2a2838"))
	var skin := _color(spec, "skin", "c89070")
	var hair := _color(spec, "hair", "3a2a20")
	var style := String(spec.get("hair_style", "short"))
	var mood := String(spec.get("mood", ""))
	if style == "long":
		_rect(image, Vector2i(30, 30), Vector2i(68, 74), hair.darkened(0.15))
	_ellipse(image, Rect2i(18, 96, 92, 64), _color(spec, "shirt", "5070a0"))
	_rect(image, Vector2i(54, 84), Vector2i(20, 18), skin.darkened(0.12))
	_ellipse(image, Rect2i(36, 24, 56, 70), skin)
	match style:
		"hood":
			var hood := _color(spec, "hood", "2a2a30")
			_ellipse(image, Rect2i(26, 12, 76, 60), hood)
			_ellipse(image, Rect2i(40, 34, 48, 56), skin)
		"cap":
			_rect(image, Vector2i(34, 18), Vector2i(60, 20), hair)
			_rect(image, Vector2i(34, 36), Vector2i(72, 6), hair.darkened(0.3))
		"none":
			pass
		_:
			_ellipse(image, Rect2i(32, 14, 64, 34), hair)
			_rect(image, Vector2i(34, 30), Vector2i(8, 26), hair)
			_rect(image, Vector2i(86, 30), Vector2i(8, 26), hair)
			if style == "bun":
				_ellipse(image, Rect2i(50, 2, 28, 22), hair)
	_face(image, mood, skin)
	_frame(image, _color(spec, "frame", "8a7a5a"))
	return image


static func _face(image: Image, mood: String, skin: Color) -> void:
	var eye_h := 8 if mood == "afraid" else 5
	_rect(image, Vector2i(48, 54), Vector2i(8, eye_h), OUTLINE)
	_rect(image, Vector2i(72, 54), Vector2i(8, eye_h), OUTLINE)
	var brow := OUTLINE.lightened(0.15)
	if mood == "sad" or mood == "afraid":
		_rect(image, Vector2i(46, 46), Vector2i(10, 2), brow)
		_rect(image, Vector2i(72, 46), Vector2i(10, 2), brow)
		_rect(image, Vector2i(52, 44), Vector2i(4, 2), brow)
		_rect(image, Vector2i(72, 44), Vector2i(4, 2), brow)
	elif mood == "angry":
		_rect(image, Vector2i(48, 46), Vector2i(10, 2), brow)
		_rect(image, Vector2i(70, 46), Vector2i(10, 2), brow)
		_rect(image, Vector2i(56, 48), Vector2i(4, 2), brow)
		_rect(image, Vector2i(68, 48), Vector2i(4, 2), brow)
	else:
		_rect(image, Vector2i(46, 46), Vector2i(12, 2), brow)
		_rect(image, Vector2i(70, 46), Vector2i(12, 2), brow)
	_rect(image, Vector2i(62, 60), Vector2i(4, 12), skin.darkened(0.15))
	var mouth := skin.darkened(0.45)
	match mood:
		"happy":
			_rect(image, Vector2i(54, 78), Vector2i(20, 3), mouth)
			_rect(image, Vector2i(52, 76), Vector2i(3, 3), mouth)
			_rect(image, Vector2i(73, 76), Vector2i(3, 3), mouth)
		"afraid":
			_ellipse(image, Rect2i(58, 74, 12, 10), mouth)
		"sad":
			_rect(image, Vector2i(56, 79), Vector2i(16, 3), mouth)
			_rect(image, Vector2i(53, 81), Vector2i(3, 3), mouth)
			_rect(image, Vector2i(72, 81), Vector2i(3, 3), mouth)
		_:
			_rect(image, Vector2i(55, 78), Vector2i(18, 3), mouth)


# --- World ---------------------------------------------------------------------

static func _tile(spec: Dictionary, rng: RandomNumberGenerator) -> Image:
	var image := _blank(Vector2i(32, 32))
	var base := _color(spec, "color", "606060")
	var accent := _color(spec, "accent", base.darkened(0.25).to_html())
	image.fill(base)
	match String(spec.get("pattern", "solid")):
		"planks":
			for y in [7, 15, 23, 31]:
				_rect(image, Vector2i(0, y), Vector2i(32, 1), accent)
			for joint in [Vector2i(10, 0), Vector2i(26, 8), Vector2i(4, 16), Vector2i(18, 24)]:
				_rect(image, joint, Vector2i(1, 7), accent)
		"checker":
			_rect(image, Vector2i(0, 0), Vector2i(16, 16), accent)
			_rect(image, Vector2i(16, 16), Vector2i(16, 16), accent)
		"grid":
			_rect(image, Vector2i(0, 0), Vector2i(32, 1), accent)
			_rect(image, Vector2i(0, 16), Vector2i(32, 1), accent)
			_rect(image, Vector2i(0, 0), Vector2i(1, 32), accent)
			_rect(image, Vector2i(16, 0), Vector2i(1, 32), accent)
		"siding":
			for y in range(0, 32, 6):
				_rect(image, Vector2i(0, y), Vector2i(32, 1), accent)
		"brick":
			for y in range(0, 32, 8):
				_rect(image, Vector2i(0, y), Vector2i(32, 1), accent)
				var offset := 0 if (y / 8) % 2 == 0 else 8
				for x in range(offset, 32, 16):
					_rect(image, Vector2i(x, y), Vector2i(1, 8), accent)
		"shingles":
			for y in range(0, 32, 8):
				_rect(image, Vector2i(0, y + 7), Vector2i(32, 1), accent)
				for x in range(4 if (y / 8) % 2 == 0 else 12, 32, 16):
					_rect(image, Vector2i(x, y), Vector2i(1, 8), accent)
		"noise":
			_speckle(image, rng, accent, int(spec.get("density", 40)))
		"dash":
			_speckle(image, rng, accent, 20)
			_rect(image, Vector2i(4, 14), Vector2i(20, 4), _color(spec, "line", "d8b040"))
		"wall_face":
			_rect(image, Vector2i(0, 0), Vector2i(32, 3), accent.lightened(0.2))
			_rect(image, Vector2i(0, 27), Vector2i(32, 5), accent)
		"wall_top":
			_rect(image, Vector2i(0, 0), Vector2i(32, 2), base.lightened(0.15))
		"curb":
			_rect(image, Vector2i(0, 0), Vector2i(32, 5), base.lightened(0.25))
			_speckle(image, rng, accent, 12)
	return image


## A 3/4 view box: a lighter top face above a darker front face. Optional "details" draw extra rects.
static func _block(spec: Dictionary) -> Image:
	var size := _size(spec, Vector2i(32, 32))
	var image := _blank(size)
	var front := _color(spec, "color", "7a6a58")
	var top_height := int(spec.get("top", size.y / 3))
	_rect(image, Vector2i(0, 0), Vector2i(size.x, top_height), _color(spec, "top_color", front.lightened(0.25).to_html()))
	_rect(image, Vector2i(0, top_height), Vector2i(size.x, size.y - top_height), front)
	_rect(image, Vector2i(0, top_height), Vector2i(size.x, 1), front.lightened(0.1))
	_details(image, spec)
	_border(image, OUTLINE)
	return image


static func _flat(spec: Dictionary) -> Image:
	var size := _size(spec, Vector2i(32, 32))
	var image := _blank(size)
	image.fill(_color(spec, "color", "704040"))
	_details(image, spec)
	if spec.get("border", true):
		_border(image, _color(spec, "border_color", "14121c"))
	return image


static func _tree(spec: Dictionary) -> Image:
	var size := _size(spec, Vector2i(64, 96))
	var image := _blank(size)
	var leaves := _color(spec, "color", "2f5a34")
	_rect(image, Vector2i(size.x / 2 - 4, size.y - 34), Vector2i(8, 34), _color(spec, "trunk", "4a3420"))
	_ellipse(image, Rect2i(0, 0, size.x, size.y - 26), leaves)
	_ellipse(image, Rect2i(8, 6, size.x - 24, size.y / 2 - 10), leaves.lightened(0.12))
	_outline(image)
	return image


static func _lamp_post(spec: Dictionary) -> Image:
	var size := _size(spec, Vector2i(32, 112))
	var image := _blank(size)
	var pole := _color(spec, "color", "3a3c44")
	_rect(image, Vector2i(size.x / 2 - 2, 10), Vector2i(4, size.y - 10), pole)
	_rect(image, Vector2i(size.x / 2 - 6, size.y - 6), Vector2i(12, 6), pole.darkened(0.2))
	_rect(image, Vector2i(size.x / 2 - 2, 8), Vector2i(14, 4), pole)
	_rect(image, Vector2i(size.x / 2 + 6, 10), Vector2i(10, 5), _color(spec, "lamp", "ffe0a0"))
	_outline(image)
	return image


## A heap of clothes left behind (the vanishing). Colours from "colors".
static func _pile(spec: Dictionary, rng: RandomNumberGenerator) -> Image:
	var size := _size(spec, Vector2i(32, 20))
	var image := _blank(size)
	var colors: Array = spec.get("colors", ["5070a0", "303848", "c0b8a8"])
	for i in 7:
		var color := Color.from_string(String(colors[i % colors.size()]), Color.GRAY)
		var w := rng.randi_range(size.x / 3, size.x / 2 + 4)
		var h := rng.randi_range(size.y / 3, size.y / 2 + 2)
		_ellipse(image, Rect2i(rng.randi_range(0, size.x - w), rng.randi_range(size.y / 4, size.y - h), w, h), color)
	_rect(image, Vector2i(size.x / 2 - 4, size.y - 5), Vector2i(8, 4), Color("201818"))
	_outline(image)
	return image


static func _shadow(spec: Dictionary) -> Image:
	var size := _size(spec, Vector2i(28, 10))
	var image := _blank(size)
	_ellipse(image, Rect2i(Vector2i.ZERO, size), Color(0, 0, 0, 0.35))
	return image


## 32x32 item icons. "glyph": bottle, can, box, bat, key, book, paper, pills, carton.
static func _icon(spec: Dictionary) -> Image:
	var image := _blank(Vector2i(32, 32))
	var color := _color(spec, "color", "c0c0c0")
	match String(spec.get("glyph", "box")):
		"bottle":
			_rect(image, Vector2i(12, 10), Vector2i(9, 18), color)
			_rect(image, Vector2i(14, 5), Vector2i(5, 5), color.lightened(0.3))
			_rect(image, Vector2i(12, 15), Vector2i(9, 5), Color("e0e8f0"))
		"can":
			_rect(image, Vector2i(9, 9), Vector2i(14, 17), color)
			_rect(image, Vector2i(9, 13), Vector2i(14, 8), Color("e8dcc0"))
		"bat":
			for i in 22:
				_rect(image, Vector2i(5 + i, 26 - i), Vector2i(2 + i / 7, 2 + i / 7), color)
			_rect(image, Vector2i(4, 25), Vector2i(4, 4), color.darkened(0.4))
		"key":
			_ellipse(image, Rect2i(5, 9, 12, 12), color)
			_rect(image, Vector2i(9, 13), Vector2i(4, 4), Color(0, 0, 0, 0))
			_rect(image, Vector2i(16, 14), Vector2i(12, 3), color)
			_rect(image, Vector2i(23, 17), Vector2i(2, 4), color)
			_rect(image, Vector2i(27, 17), Vector2i(2, 3), color)
		"book":
			_rect(image, Vector2i(7, 5), Vector2i(18, 23), color)
			_rect(image, Vector2i(8, 6), Vector2i(2, 21), color.darkened(0.3))
			_rect(image, Vector2i(15, 10), Vector2i(2, 10), Color("d8b860"))
			_rect(image, Vector2i(12, 13), Vector2i(8, 2), Color("d8b860"))
		"paper":
			_rect(image, Vector2i(8, 5), Vector2i(17, 22), color)
			for y in [10, 14, 18, 22]:
				_rect(image, Vector2i(11, y), Vector2i(11, 1), Color("6a6a7a"))
		"pills":
			_rect(image, Vector2i(10, 10), Vector2i(12, 16), color)
			_rect(image, Vector2i(9, 6), Vector2i(14, 5), Color("f0f0f0"))
			_rect(image, Vector2i(12, 15), Vector2i(8, 5), Color("f0f0f0"))
		"carton":
			_rect(image, Vector2i(10, 10), Vector2i(12, 18), color)
			_rect(image, Vector2i(10, 5), Vector2i(12, 5), color.darkened(0.15))
			_rect(image, Vector2i(10, 16), Vector2i(12, 6), Color("4070c0"))
		_:
			_rect(image, Vector2i(7, 9), Vector2i(18, 16), color)
			_rect(image, Vector2i(7, 9), Vector2i(18, 4), color.lightened(0.2))
	_outline(image)
	return image


# --- Helpers -------------------------------------------------------------------

static func _details(image: Image, spec: Dictionary) -> void:
	for detail: Variant in spec.get("details", []):
		var d: Dictionary = detail
		var r: Array = d.get("rect", [0, 0, 1, 1])
		var rect := Rect2i(int(r[0]), int(r[1]), int(r[2]), int(r[3]))
		var color := Color.from_string(String(d.get("color", "ffffff")), Color.WHITE)
		if d.get("ellipse", false):
			_ellipse(image, rect, color)
		else:
			_rect(image, rect.position, rect.size, color)


static func _blank(size: Vector2i) -> Image:
	return Image.create_empty(maxi(size.x, 1), maxi(size.y, 1), false, Image.FORMAT_RGBA8)


static func _size(spec: Dictionary, fallback: Vector2i) -> Vector2i:
	var raw: Variant = spec.get("size")
	if raw is Array and (raw as Array).size() >= 2:
		return Vector2i(int(raw[0]), int(raw[1]))
	return fallback


static func _color(spec: Dictionary, key: String, fallback_hex: String) -> Color:
	return Color.from_string(String(spec.get(key, fallback_hex)), Color.from_string(fallback_hex, Color.MAGENTA))


static func _rect(image: Image, position: Vector2i, size: Vector2i, color: Color) -> void:
	var rect := Rect2i(position, size).intersection(Rect2i(Vector2i.ZERO, image.get_size()))
	if rect.has_area():
		image.fill_rect(rect, color)


static func _ellipse(image: Image, rect: Rect2i, color: Color) -> void:
	var center := Vector2(rect.position) + Vector2(rect.size) / 2.0
	var radius := Vector2(rect.size) / 2.0
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var d := (Vector2(x + 0.5, y + 0.5) - center) / radius
			if d.length_squared() <= 1.0 and x >= 0 and y >= 0 and x < image.get_width() and y < image.get_height():
				image.set_pixel(x, y, color)


static func _border(image: Image, color: Color) -> void:
	var size := image.get_size()
	_rect(image, Vector2i(0, 0), Vector2i(size.x, 1), color)
	_rect(image, Vector2i(0, size.y - 1), Vector2i(size.x, 1), color)
	_rect(image, Vector2i(0, 0), Vector2i(1, size.y), color)
	_rect(image, Vector2i(size.x - 1, 0), Vector2i(1, size.y), color)


static func _frame(image: Image, color: Color) -> void:
	_border(image, color)
	var size := image.get_size()
	_rect(image, Vector2i(1, 1), Vector2i(size.x - 2, 1), color.darkened(0.4))
	_rect(image, Vector2i(1, 1), Vector2i(1, size.y - 2), color.darkened(0.4))


## Adds a 1 px dark outline around opaque pixels.
static func _outline(image: Image) -> void:
	var source := image.duplicate() as Image
	var size := image.get_size()
	for y in size.y:
		for x in size.x:
			if source.get_pixel(x, y).a > 0.5:
				continue
			for n: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var p := Vector2i(x, y) + n
				if p.x >= 0 and p.y >= 0 and p.x < size.x and p.y < size.y and source.get_pixel(p.x, p.y).a > 0.5:
					image.set_pixel(x, y, OUTLINE)
					break


static func _speckle(image: Image, rng: RandomNumberGenerator, color: Color, count: int) -> void:
	for i in count:
		image.set_pixel(rng.randi_range(0, image.get_width() - 1), rng.randi_range(0, image.get_height() - 1), color)
