@tool
class_name GroundShadows
extends Node2D
## Soft cast shadows under every standing tile of the given layers: trees, rocks, walls, houses,
## stalls, crates, the forest's edge. The light comes from the top left (see DESIGN.md, "Art
## direction"), so each shadow sits at the object's base and leans down-right.
##
## Built once from the tiles' own pixels, so new props get a shadow with no extra art:
## - an object on a narrow foot (tree, lamp, signpost) gets an oval under its foot, about as wide
##   as its crown;
## - anything else (house, wall, crate, the forest edge) gets a band hugging its base, plus a
##   sliver down its right side when it is tall.
## A tile stacked on top of another tile of the same layer casts nothing (only bases touch the
## ground), and tiles whose art already carries a dithered shadow are skipped.
##
## Every shadow is painted into one texture, so where shadows overlap they don't get darker.
## Sit this node above the ground and decoration layers and below `World`.

## The shadow colour (Apollo outline). Its strength is `core_alpha`; the 1 px rim is softer.
const SHADOW_COLOR := ApolloPalette.OUTLINE
## The rim's alpha as a share of the core's.
const RIM_SHARE := 0.48
## Core strength for bright ground (towns); dark grass needs more to read (see `core_alpha`).
const BRIGHT_GROUND_ALPHA := 0.5
const DARK_GROUND_ALPHA := 0.66
## How far a shadow leans down-right, in pixels per pixel of object height, and its limits.
const LEAN_PER_HEIGHT := 0.08
const MIN_LEAN := 2
const MAX_LEAN := 4
## How deep a base band reaches onto the ground, by object height.
const DEPTH_PER_HEIGHT := 0.1
const MIN_DEPTH := 3
const MAX_DEPTH := 6
## A foot narrower than this share of the object's width makes it a "tree" (oval shadow).
const NARROW_FOOT_SHARE := 0.55
## Rows at the bottom of an object that count as its foot.
const FOOT_ROWS := 4
## Objects at least this tall also shade the ground along their right side.
const TALL_HEIGHT := 24

## The layers whose tiles stand on the ground and cast shadows.
@export var caster_layers: Array[TileMapLayer] = []:
	set(value):
		caster_layers = value
		if is_inside_tree():
			rebuild()

## How dark a shadow's core is. Bright ground (towns) reads at BRIGHT_GROUND_ALPHA; zones on
## dark grass or stone (Ruins Edge, the fen) use about DARK_GROUND_ALPHA so shadows still show.
@export_range(0.0, 1.0, 0.01) var core_alpha: float = BRIGHT_GROUND_ALPHA:
	set(value):
		core_alpha = value
		if is_inside_tree():
			rebuild()

var _texture: ImageTexture = null
var _texture_origin := Vector2.ZERO
## Shape facts per tile, keyed by "tileset:source:atlas:alternative", so each tile is read once.
var _shape_cache: Dictionary = {}
## Each atlas texture's pixels, read once per rebuild.
var _atlas_images: Dictionary = {}


func _ready() -> void:
	rebuild()


## Repaints every shadow from the caster layers as they are now.
func rebuild() -> void:
	_shape_cache.clear()
	_atlas_images.clear()
	var bounds := _caster_bounds()
	if bounds.size == Vector2i.ZERO:
		_texture = null
		queue_redraw()
		return
	var core_spans: Array[Rect2i] = []
	var rim_spans: Array[Rect2i] = []
	for layer in caster_layers:
		if layer != null and layer.tile_set != null:
			_collect_layer_spans(layer, core_spans, rim_spans)
	var image := Image.create_empty(bounds.size.x, bounds.size.y, false, Image.FORMAT_RGBA8)
	var image_rect := Rect2i(Vector2i.ZERO, bounds.size)
	for span in rim_spans:
		image.fill_rect(Rect2i(span.position - bounds.position, span.size).intersection(image_rect), Color(SHADOW_COLOR, core_alpha * RIM_SHARE))
	for span in core_spans:
		image.fill_rect(Rect2i(span.position - bounds.position, span.size).intersection(image_rect), Color(SHADOW_COLOR, core_alpha))
	_texture = ImageTexture.create_from_image(image)
	_texture_origin = Vector2(bounds.position)
	queue_redraw()


func _draw() -> void:
	if _texture != null:
		draw_texture(_texture, _texture_origin)


## The pixel rectangle (in this node's space) that the caster layers cover, with room to lean.
func _caster_bounds() -> Rect2i:
	var bounds := Rect2i()
	for layer in caster_layers:
		if layer == null or layer.tile_set == null:
			continue
		var used := layer.get_used_rect()
		if used.size == Vector2i.ZERO:
			continue
		var tile_size := layer.tile_set.tile_size
		var offset := Vector2i(layer.global_position - global_position)
		var layer_rect := Rect2i(used.position * tile_size + offset, used.size * tile_size).grow(tile_size.x * 2)
		bounds = layer_rect if bounds.size == Vector2i.ZERO else bounds.merge(layer_rect)
	return bounds


func _collect_layer_spans(layer: TileMapLayer, core_spans: Array[Rect2i], rim_spans: Array[Rect2i]) -> void:
	var offset := layer.global_position - global_position
	for cell in layer.get_used_cells():
		var shape := _tile_shape(layer, cell)
		if shape.is_empty() or shape["has_baked_shadow"]:
			continue
		var is_single_cell: bool = shape["is_single_cell"]
		if is_single_cell and _is_stacked_on(layer, cell):
			continue
		var top_left := Vector2i((layer.map_to_local(cell) + offset - shape["draw_offset"]).round())
		if shape["is_narrow_foot"]:
			_add_foot_oval(shape, top_left, core_spans, rim_spans)
		else:
			_add_base_band(shape, top_left, core_spans, rim_spans)


## True when the cell just below holds another tile of the layer (this one is not a base).
func _is_stacked_on(layer: TileMapLayer, cell: Vector2i) -> bool:
	return layer.get_cell_source_id(cell + Vector2i.DOWN) != -1


## Reads a tile's pixels once: its bottom edge per column, its foot and how tall it stands.
func _tile_shape(layer: TileMapLayer, cell: Vector2i) -> Dictionary:
	var source_id := layer.get_cell_source_id(cell)
	var atlas_coords := layer.get_cell_atlas_coords(cell)
	var alternative := layer.get_cell_alternative_tile(cell)
	var key := "%d:%d:%v:%d" % [layer.tile_set.get_instance_id(), source_id, atlas_coords, alternative]
	if _shape_cache.has(key):
		return _shape_cache[key]
	var shape := {}
	var source := layer.tile_set.get_source(source_id) as TileSetAtlasSource
	if source != null and source.texture != null:
		shape = _measure_tile(source, atlas_coords, alternative)
	_shape_cache[key] = shape
	return shape


func _measure_tile(source: TileSetAtlasSource, atlas_coords: Vector2i, alternative: int) -> Dictionary:
	var region := source.get_tile_texture_region(atlas_coords)
	var tile_data := source.get_tile_data(atlas_coords, alternative)
	var pixels := _atlas_image(source.texture).get_region(region)
	if tile_data.flip_h:
		pixels.flip_x()
	var width := pixels.get_width()
	var height := pixels.get_height()
	var bottom_per_column := PackedInt32Array()
	bottom_per_column.resize(width)
	bottom_per_column.fill(-1)
	var right_per_row := PackedInt32Array()
	right_per_row.resize(height)
	right_per_row.fill(-1)
	var top := height
	var bottom := -1
	for y in height:
		for x in width:
			if pixels.get_pixel(x, y).a > 0.5:
				bottom_per_column[x] = y
				right_per_row[y] = x
				top = mini(top, y)
				bottom = maxi(bottom, y)
	if bottom < 0:
		return {}
	var left := width
	var right := -1
	var foot_left := width
	var foot_right := -1
	for x in width:
		if bottom_per_column[x] < 0:
			continue
		left = mini(left, x)
		right = maxi(right, x)
		if bottom_per_column[x] >= bottom - FOOT_ROWS + 1:
			foot_left = mini(foot_left, x)
			foot_right = maxi(foot_right, x)
	var object_height := bottom - top + 1
	var object_width := right - left + 1
	var foot_width := foot_right - foot_left + 1
	return {
		"draw_offset": Vector2(region.size) / 2.0 + Vector2(tile_data.texture_origin),
		"is_single_cell": source.get_tile_size_in_atlas(atlas_coords) == Vector2i.ONE,
		"has_baked_shadow": _has_dithered_base(pixels, bottom),
		"is_narrow_foot": object_width > 8 and foot_width < object_width * NARROW_FOOT_SHARE,
		"bottom_per_column": bottom_per_column,
		"right_per_row": right_per_row,
		"top": top,
		"bottom": bottom,
		"left": left,
		"right": right,
		"foot_center": (foot_left + foot_right) / 2.0,
		"lean": clampi(roundi(object_height * LEAN_PER_HEIGHT), MIN_LEAN, MAX_LEAN),
		"depth": clampi(roundi(object_height * DEPTH_PER_HEIGHT), MIN_DEPTH, MAX_DEPTH),
		"height": object_height,
		"width": object_width,
	}


func _atlas_image(texture: Texture2D) -> Image:
	if not _atlas_images.has(texture):
		var image := texture.get_image()
		if image.is_compressed():
			image.decompress()
		_atlas_images[texture] = image
	return _atlas_images[texture]


## The newer tree art carries its own checkered shadow on its bottom rows: no second one.
func _has_dithered_base(pixels: Image, bottom: int) -> bool:
	var isolated := 0
	var opaque := 0
	for x in range(1, pixels.get_width() - 1):
		if pixels.get_pixel(x, bottom).a <= 0.5:
			continue
		opaque += 1
		if pixels.get_pixel(x - 1, bottom).a <= 0.5 and pixels.get_pixel(x + 1, bottom).a <= 0.5:
			isolated += 1
	return opaque >= 4 and isolated * 2 >= opaque


## An oval at the foot of a tree-like object, as wide as most of its crown, leaning right.
func _add_foot_oval(shape: Dictionary, top_left: Vector2i, core_spans: Array[Rect2i], rim_spans: Array[Rect2i]) -> void:
	var lean: int = shape["lean"]
	var radius_x := maxi(3, roundi(shape["width"] * 0.36))
	var radius_y := clampi(roundi(radius_x * 0.32), 2, 5)
	var center := top_left + Vector2i(roundi(shape["foot_center"]) + lean, shape["bottom"] - 1)
	_add_oval(center, radius_x + 1, radius_y + 1, rim_spans)
	_add_oval(center, radius_x, radius_y, core_spans)


func _add_oval(center: Vector2i, radius_x: int, radius_y: int, spans: Array[Rect2i]) -> void:
	for row in range(-radius_y, radius_y + 1):
		var t := float(row) / (radius_y + 0.5)
		var half := roundi(radius_x * sqrt(maxf(0.0, 1.0 - t * t)))
		spans.append(Rect2i(center.x - half, center.y + row, half * 2 + 1, 1))


## A band along the object's base, shifted down-right, and a sliver down the right side of a
## tall object: the ground just past its lit faces stays in shade.
func _add_base_band(shape: Dictionary, top_left: Vector2i, core_spans: Array[Rect2i], rim_spans: Array[Rect2i]) -> void:
	var lean: int = shape["lean"]
	var depth: int = shape["depth"]
	var bottom_per_column: PackedInt32Array = shape["bottom_per_column"]
	for x in bottom_per_column.size():
		var column_bottom := bottom_per_column[x]
		if column_bottom < 0:
			continue
		var start := top_left + Vector2i(x + lean, column_bottom - 1)
		core_spans.append(Rect2i(start, Vector2i(1, depth)))
		rim_spans.append(Rect2i(start, Vector2i(1, depth + 1)))
	rim_spans.append(Rect2i(top_left + Vector2i(shape["right"] + lean + 1, shape["bottom"]), Vector2i(1, depth - 1)))
	if shape["height"] < TALL_HEIGHT:
		return
	var right_per_row: PackedInt32Array = shape["right_per_row"]
	var lower_half_top: int = shape["bottom"] - shape["height"] / 2
	for y in range(lower_half_top, shape["bottom"] + 1):
		var row_right := right_per_row[y]
		if row_right < 0:
			continue
		var start := top_left + Vector2i(row_right + 1, y + lean)
		core_spans.append(Rect2i(start, Vector2i(lean, 1)))
		rim_spans.append(Rect2i(start, Vector2i(lean + 1, 1)))
