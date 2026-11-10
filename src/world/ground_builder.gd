class_name GroundBuilder
extends RefCounted
## Builds a TileMapLayer from a zone's ASCII "map" and "legend" (char -> tile id in data/tiles.json).
## Solid tiles get collision.
##
## Tile options (data/tiles.json):
## - "variants": [[art_id, weight], ...] picks an art per cell by a hash of the cell, so large
##   areas of one tile (lawn, road, floors) do not repeat visibly.
## - Walls in the 3/4 view: "face_art" is drawn where the cell below is walkable floor (the wall's
##   front face). With "face_tall": [upper, lower] a wall two cells deep shows a two-row face
##   (upper over lower) and only the cells above that are the cap ("art"). "face_end" gives
##   {"l": [...], "r": [...]} pieces (order: single, upper, lower) used where a face row stops,
##   so wall ends and inner corners get a shaded edge.

var cells: Array[PackedStringArray] = []   # [row][column] -> tile id ("" = void)
var size := Vector2i.ZERO

var _tile_set := TileSet.new()
var _sources: Dictionary = {}   # "tile|art" -> source id


func build(map_rows: Array, legend: Dictionary) -> TileMapLayer:
	_parse(map_rows, legend)
	_tile_set.tile_size = Vector2i(Tiles.SIZE, Tiles.SIZE)
	_tile_set.add_physics_layer()
	_tile_set.set_physics_layer_collision_layer(0, Layers.WORLD)
	_tile_set.set_physics_layer_collision_mask(0, 0)
	var layer := TileMapLayer.new()
	layer.name = "Ground"
	layer.tile_set = _tile_set
	for y in size.y:
		for x in size.x:
			var tile_id := cells[y][x]
			if tile_id.is_empty():
				continue
			layer.set_cell(Vector2i(x, y), _source_for(tile_id, art_for(tile_id, x, y)), Vector2i.ZERO)
	return layer


func tile_at(cell: Vector2i) -> String:
	if cell.y < 0 or cell.y >= size.y or cell.x < 0 or cell.x >= size.x:
		return ""
	return cells[cell.y][cell.x]


func is_walkable(cell: Vector2i) -> bool:
	var tile_id := tile_at(cell)
	return not tile_id.is_empty() and not (DB.tiles.get(tile_id, {}) as Dictionary).get("solid", false)


func _parse(map_rows: Array, legend: Dictionary) -> void:
	for row: Variant in map_rows:
		var text := String(row)
		size.x = maxi(size.x, text.length())
	for row: Variant in map_rows:
		var text := String(row)
		var ids := PackedStringArray()
		for x in size.x:
			var symbol := text[x] if x < text.length() else " "
			ids.append(String(legend.get(symbol, "")))
		cells.append(ids)
	size.y = cells.size()


## 0 = not a face (cap, or not a wall), 1 = single/lower face row, 2 = upper face row.
func face_level(x: int, y: int) -> int:
	var tile: Dictionary = DB.tiles.get(tile_at(Vector2i(x, y)), {})
	if not tile.has("face_art"):
		return 0
	if is_walkable(Vector2i(x, y + 1)):
		return 1
	if tile.has("face_tall") and (DB.tiles.get(tile_at(Vector2i(x, y + 1)), {}) as Dictionary).has("face_art") \
			and is_walkable(Vector2i(x, y + 2)):
		return 2
	return 0


func art_for(tile_id: String, x: int, y: int) -> String:
	var tile: Dictionary = DB.tiles.get(tile_id, {})
	var level := face_level(x, y)
	if level > 0:
		var tall: Array = tile.get("face_tall", [])
		var index := 0 if tall.is_empty() else (2 if level == 1 else 1)
		var base := String(tile["face_art"]) if index == 0 else String(tall[index - 1])
		var ends: Dictionary = tile.get("face_end", {})
		if not ends.is_empty():
			if face_level(x - 1, y) != level:
				return String((ends["l"] as Array)[index])
			if face_level(x + 1, y) != level:
				return String((ends["r"] as Array)[index])
		return base
	if tile.has("variants"):
		return _pick_variant(tile["variants"], x, y)
	return String(tile.get("art", tile_id))


static func cell_hash(x: int, y: int) -> int:
	var h := (x * 73856093) ^ (y * 19349663)
	h = (h * 2654435761) & 0xffffffff
	return (h >> 8) & 0xffffff


func _pick_variant(variants: Array, x: int, y: int) -> String:
	var total := 0.0
	for v: Variant in variants:
		total += float((v as Array)[1]) if v is Array else 1.0
	var roll := float(cell_hash(x, y) % 100000) / 100000.0 * total
	for v: Variant in variants:
		var weight := float((v as Array)[1]) if v is Array else 1.0
		if roll < weight:
			return String((v as Array)[0]) if v is Array else String(v)
		roll -= weight
	var last: Variant = variants[-1]
	return String((last as Array)[0]) if last is Array else String(last)


func _source_for(tile_id: String, art_id: String) -> int:
	var key := tile_id + "|" + art_id
	if _sources.has(key):
		return _sources[key]
	var source := TileSetAtlasSource.new()
	source.texture = Art.texture(art_id)
	source.texture_region_size = Vector2i(Tiles.SIZE, Tiles.SIZE)
	var source_id := _tile_set.add_source(source)
	source.create_tile(Vector2i.ZERO)
	var tile: Dictionary = DB.tiles.get(tile_id, {})
	if tile.get("solid", false):
		var half := Tiles.SIZE / 2.0
		var data := source.get_tile_data(Vector2i.ZERO, 0)
		data.add_collision_polygon(0)
		data.set_collision_polygon_points(0, 0, PackedVector2Array([
			Vector2(-half, -half), Vector2(half, -half), Vector2(half, half), Vector2(-half, half)]))
	_sources[key] = source_id
	return source_id
