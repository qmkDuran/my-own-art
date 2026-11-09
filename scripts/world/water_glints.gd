class_name WaterGlints
extends Node2D
## Sunlight catching ripples: short pale glints that flicker on open water near the camera,
## so ponds and pools read as water, not flat blue floor. Decoration only, a handful at a time.
## Glints only appear on cells whose four neighbours are water too, so never on a bank.

## Glints alive at once, and how long each one shimmers (seconds).
const GLINT_COUNT := 6
const GLINT_SECONDS := 1.4
## Glint lengths in pixels (a short horizontal dash) and their brightness at the peak.
const MIN_LENGTH := 2
const MAX_LENGTH := 4
const GLINT_ALPHA := 0.8
## Random cells in view tried per glint before it waits for its next turn.
const SPAWN_ATTEMPTS := 12
## Only water this close to the view's centre gets glints (a little more than the 480×270 view).
const VIEW_HALF_EXTENTS := Vector2(260.0, 150.0)

## The layer that holds the water tiles.
@export var water_layer: TileMapLayer
## Atlas rows that hold water tiles in that layer; empty means every tile of the layer.
@export var water_atlas_rows: PackedInt32Array = PackedInt32Array()

## Cells of open water, as a set (cell → true).
var _open_water_cells: Dictionary = {}
var _glints: Array[Dictionary] = []


func _ready() -> void:
	z_index = 0
	_find_open_water()
	for index in GLINT_COUNT:
		_glints.append({"age": GLINT_SECONDS * index / GLINT_COUNT, "spot": Vector2.ZERO, "length": 0, "visible": false})


func _process(delta: float) -> void:
	if _open_water_cells.is_empty():
		return
	for glint in _glints:
		glint["age"] += delta
		if glint["age"] >= GLINT_SECONDS:
			_respawn(glint)
	queue_redraw()


func _draw() -> void:
	for glint in _glints:
		if not glint["visible"]:
			continue
		var progress: float = glint["age"] / GLINT_SECONDS
		var alpha := sin(PI * progress) * GLINT_ALPHA
		var spot: Vector2 = glint["spot"]
		draw_rect(Rect2(spot, Vector2(glint["length"], 1)), Color(ApolloPalette.SKY_LIGHT, alpha))
		draw_rect(Rect2(spot + Vector2(1, 0), Vector2(maxi(1, glint["length"] - 2), 1)), Color(ApolloPalette.WHITE, alpha))


func _find_open_water() -> void:
	_open_water_cells.clear()
	if water_layer == null:
		return
	for cell in water_layer.get_used_cells():
		if not _is_water(cell):
			continue
		var is_open := true
		for side: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			if not _is_water(cell + side):
				is_open = false
				break
		if is_open:
			_open_water_cells[cell] = true


func _is_water(cell: Vector2i) -> bool:
	if water_layer.get_cell_source_id(cell) == -1:
		return false
	return water_atlas_rows.is_empty() or water_atlas_rows.has(water_layer.get_cell_atlas_coords(cell).y)


## Moves a glint to a random open-water spot in view; it stays hidden when none turns up.
func _respawn(glint: Dictionary) -> void:
	glint["age"] = 0.0
	glint["visible"] = false
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
	var view_center := water_layer.to_local(camera.get_screen_center_position())
	var first_cell := water_layer.local_to_map(view_center - VIEW_HALF_EXTENTS)
	var last_cell := water_layer.local_to_map(view_center + VIEW_HALF_EXTENTS)
	for attempt in SPAWN_ATTEMPTS:
		var cell := Vector2i(randi_range(first_cell.x, last_cell.x), randi_range(first_cell.y, last_cell.y))
		if _open_water_cells.has(cell):
			var cell_center := to_local(water_layer.to_global(water_layer.map_to_local(cell)))
			glint["spot"] = (cell_center + Vector2(randi_range(-6, 4), randi_range(-6, 6))).floor()
			glint["length"] = randi_range(MIN_LENGTH, MAX_LENGTH)
			glint["visible"] = true
			return
