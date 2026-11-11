class_name PropLayer
extends Node2D
## The standing things of a map, y-sorted with the walkers: trees (2x2 blocks), houses, props and signs.
## Each knows the heal stage that brings it back; `refresh()` swaps withered and healed art with a fade and
## removes things (brambles) whose time has passed.

const T: int = 16
const FADE_TIME: float = 1.2

var _map: MapGrid
var _entries: Array[Dictionary] = []


func build(map: MapGrid, stage: int) -> void:
	_map = map
	y_sort_enabled = true
	for block: Dictionary in map.tree_blocks():
		var c: Vector2i = block["cell"]
		_add("props/" + String(block["kind"]), c, Vector2i(2, 2), c + Vector2i.ONE, {}, stage)
	for o: Dictionary in map.objects:
		var art: String = _art_for(o)
		if art != "" and map.is_present(o, stage):
			var sz: Vector2i = map.object_size(o)
			_add(art, MapGrid.cell_of(o["cell"]), sz, MapGrid.cell_of(o["cell"]), o, stage)


func _art_for(o: Dictionary) -> String:
	match String(o["kind"]):
		"house":
			return "props/house_" + String(o["style"])
		"prop":
			return "props/" + String(o["prop"])
		"sign":
			return "props/sign"
	return ""


func _add(art: String, cell: Vector2i, sz: Vector2i, heal_cell: Vector2i, o: Dictionary, stage: int) -> void:
	var s := Sprite2D.new()
	s.centered = false
	var tex: Texture2D = _texture(art, _map.is_withered(heal_cell, stage))
	s.texture = tex
	s.position = Vector2(cell.x * T + sz.x * T / 2, (cell.y + sz.y) * T)
	s.offset = Vector2(-tex.get_width() / 2, -tex.get_height())
	if o.get("walk", false):
		s.z_index = -1
	add_child(s)
	_entries.append({"sprite": s, "art": art, "heal_cell": heal_cell, "object": o})


func _texture(art: String, withered: bool) -> Texture2D:
	var path: String = "res://art/%s_withered.png" % art
	if withered and ResourceLoader.exists(path):
		return load(path)
	return load("res://art/%s.png" % art)


## Swaps art to match a new heal stage, fading the change in; brambles past their stage wither away.
func refresh(stage: int) -> void:
	for e: Dictionary in _entries:
		var s: Sprite2D = e["sprite"]
		var o: Dictionary = e["object"]
		if not o.is_empty() and not _map.is_present(o, stage):
			var tw: Tween = s.create_tween()
			tw.tween_property(s, "modulate:a", 0.0, FADE_TIME)
			tw.tween_callback(s.queue_free)
			continue
		var tex: Texture2D = _texture(String(e["art"]), _map.is_withered(e["heal_cell"], stage))
		if tex != s.texture:
			_crossfade(s, tex)


func _crossfade(s: Sprite2D, tex: Texture2D) -> void:
	var ghost := s.duplicate() as Sprite2D
	s.get_parent().add_child(ghost)
	s.texture = tex
	var tw: Tween = ghost.create_tween()
	tw.tween_property(ghost, "modulate:a", 0.0, FADE_TIME)
	tw.tween_callback(ghost.queue_free)


func sprite_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for e: Dictionary in _entries:
		var s: Sprite2D = e["sprite"]
		if is_instance_valid(s):
			out.append(Rect2(s.position + s.offset, s.texture.get_size()))
	return out
