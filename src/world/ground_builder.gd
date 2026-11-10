class_name GroundBuilder
extends RefCounted
## Builds a TileMapLayer from a zone's ASCII "map" and "legend" (char -> tile id in data/tiles.json).
## Solid tiles get collision. A tile with "face_art" uses it where the cell below is not the same
## tile, giving walls a visible front face in the 3/4 view.

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
			layer.set_cell(Vector2i(x, y), _source_for(tile_id, _art_for(tile_id, x, y)), Vector2i.ZERO)
	return layer


func tile_at(cell: Vector2i) -> String:
	if cell.y < 0 or cell.y >= size.y or cell.x < 0 or cell.x >= size.x:
		return ""
	return cells[cell.y][cell.x]


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


func _art_for(tile_id: String, x: int, y: int) -> String:
	var tile: Dictionary = DB.tiles.get(tile_id, {})
	if tile.has("face_art") and tile_at(Vector2i(x, y + 1)) != tile_id:
		return String(tile["face_art"])
	return String(tile.get("art", tile_id))


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
