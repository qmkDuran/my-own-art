class_name TerrainPainter
extends RefCounted
## Bakes a map's ground into one image: grass variants, autotiled path and water (cut from 8x8 quadrants of
## each terrain's blob sheet), tall grass, decor, fences, interior floor and walls. Cells in unhealed regions use
## the withered twin of every tile.

const T: int = 16
const Q: int = 8
const AUTOTILED: Array[String] = ["path", "water"]
const GRASS_VARIANTS: Array[int] = [0, 0, 0, 1, 2, 0, 3, 1]
const QUADRANTS: Array[Vector2i] = [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]
const FULL_X: int = 48
const INNER_X: int = 64

var _cache: Dictionary = {}


func image(name: String, withered: bool = false) -> Image:
	var key: String = name + ("_withered" if withered else "")
	if not _cache.has(key):
		var path: String = "res://art/%s.png" % key
		if not ResourceLoader.exists(path):
			path = "res://art/%s.png" % name
		var img: Image = (load(path) as Texture2D).get_image()
		img.convert(Image.FORMAT_RGBA8)
		_cache[key] = img
	return _cache[key]


func bake(map: MapGrid, stage: int) -> ImageTexture:
	var img := Image.create(map.size.x * T, map.size.y * T, false, Image.FORMAT_RGBA8)
	for y: int in map.size.y:
		for x: int in map.size.x:
			_paint_cell(img, map, Vector2i(x, y), map.is_withered(Vector2i(x, y), stage))
	return ImageTexture.create_from_image(img)


func _paint_cell(img: Image, map: MapGrid, c: Vector2i, dry: bool) -> void:
	var info: Dictionary = map.info(c)
	var ground: String = String(info["ground"])
	var at := Vector2i(c.x * T, c.y * T)
	match ground:
		"void":
			return
		"floor":
			img.blit_rect(image("tiles/floor"), Rect2i(0, 0, T, T), at)
		"wall", "wall_window":
			_paint_wall(img, map, c, ground)
		_:
			_paint_outdoor(img, map, c, dry)
	if info.has("decor"):
		_blend(img, _decor_image(String(info["decor"]), dry), at)
	if info.get("tall", false):
		_blend(img, image("tiles/tall_grass", dry), at)
	if info.get("fence", false):
		var mask: int = _fence_mask(map, c)
		img.blend_rect(image("props/fence", dry), Rect2i(mask * T, 0, T, T), at)


func _decor_image(decor: String, dry: bool) -> Image:
	var tiles_dir: Array[String] = ["flowers", "bridge", "bridge_v"]
	return image(("tiles/" if decor in tiles_dir else "props/") + decor, dry)


func _paint_outdoor(img: Image, map: MapGrid, c: Vector2i, dry: bool) -> void:
	var at := Vector2i(c.x * T, c.y * T)
	var variant: int = GRASS_VARIANTS[absi(c.x * 7 + c.y * 13 + c.x * c.y) % GRASS_VARIANTS.size()]
	img.blit_rect(image("tiles/grass", dry), Rect2i(variant * T, 0, T, T), at)
	var ground: String = map.ground(c)
	if ground in AUTOTILED:
		for q: Vector2i in QUADRANTS:
			_paint_quadrant(img, map, c, q, ground, dry)


func _paint_quadrant(img: Image, map: MapGrid, c: Vector2i, q: Vector2i, ground: String, dry: bool) -> void:
	var h: bool = _same(map, c + Vector2i(q.x, 0), ground)
	var v: bool = _same(map, c + Vector2i(0, q.y), ground)
	var d: bool = _same(map, c + q, ground)
	var off := Vector2i(0 if q.x < 0 else Q, 0 if q.y < 0 else Q)
	var src: Vector2i
	if h and v:
		src = Vector2i(FULL_X if d else INNER_X, 0)
	elif h:
		src = Vector2i(T, (1 + q.y) * T)
	elif v:
		src = Vector2i((1 + q.x) * T, T)
	else:
		src = Vector2i((1 + q.x) * T, (1 + q.y) * T)
	img.blend_rect(image("tiles/" + ground, dry), Rect2i(src + off, Vector2i(Q, Q)), c * T + off)


func _same(map: MapGrid, c: Vector2i, ground: String) -> bool:
	return not map.in_bounds(c) or map.ground(c) == ground


func _paint_wall(img: Image, map: MapGrid, c: Vector2i, ground: String) -> void:
	var above: String = map.ground(c + Vector2i.UP)
	var lower_half: bool = map.in_bounds(c + Vector2i.UP) and above in ["wall", "wall_window"]
	img.blit_rect(image("props/" + ground), Rect2i(0, T if lower_half else 0, T, T), c * T)


func _fence_mask(map: MapGrid, c: Vector2i) -> int:
	var mask: int = 0
	var bits: Dictionary = {Vector2i.UP: 1, Vector2i.RIGHT: 2, Vector2i.DOWN: 4, Vector2i.LEFT: 8}
	for dir: Vector2i in bits:
		if map.info(c + dir).get("fence", false):
			mask |= int(bits[dir])
	return mask


func _blend(img: Image, src: Image, at: Vector2i) -> void:
	img.blend_rect(src, Rect2i(Vector2i.ZERO, src.get_size()), at)
