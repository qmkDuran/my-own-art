class_name MapGrid
extends RefCounted
## One map's data as a grid: terrain letters (data/legend.json), objects and their footprints, warps,
## encounters and heal regions. Pure data and rules; drawing is TerrainPainter's and PropLayer's job.

const TILE: int = 16
const HOUSE_SIZE: Vector2i = Vector2i(4, 3)
const DIRS: Dictionary = {"up": Vector2i.UP, "down": Vector2i.DOWN, "left": Vector2i.LEFT, "right": Vector2i.RIGHT}

var id: String = ""
var title: String = ""
var music: String = ""
var battle_stage: String = "meadow"
var indoor: bool = false
var size: Vector2i = Vector2i.ZERO
var rows: PackedStringArray = []
var objects: Array[Dictionary] = []
var encounters: Dictionary = {}
var heal_regions: Array = []
var _warps: Dictionary = {}


static func load_map(map_id: String) -> MapGrid:
	var d: Dictionary = Db.map_data(map_id)
	var m := MapGrid.new()
	m.id = map_id
	m.title = String(d["name"])
	m.music = String(d.get("music", "town"))
	m.battle_stage = String(d.get("battle_stage", "meadow"))
	m.indoor = bool(d.get("indoor", false))
	m.rows = PackedStringArray(d["rows"])
	m.size = Vector2i(m.rows[0].length(), m.rows.size())
	m.objects.assign(d.get("objects", []))
	m.encounters = d.get("encounters", {})
	m.heal_regions = d.get("heal_regions", [])
	for w: Dictionary in d.get("warps", []):
		m._warps[cell_of(w["cell"])] = w["to"]
	for o: Dictionary in m.objects:
		if o["kind"] == "house" and o.has("to"):
			m._warps[door_cell(o)] = o["to"]
	return m


static func cell_of(a: Array) -> Vector2i:
	return Vector2i(int(a[0]), int(a[1]))


static func dir_of(name: String) -> Vector2i:
	return DIRS.get(name, Vector2i.DOWN)


static func door_cell(house: Dictionary) -> Vector2i:
	return cell_of(house["cell"]) + Vector2i(int(house["door"]), HOUSE_SIZE.y - 1)


func in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < size.x and c.y < size.y


func letter(c: Vector2i) -> String:
	return rows[c.y][c.x] if in_bounds(c) else " "


func info(c: Vector2i) -> Dictionary:
	return Db.legend.get(letter(c), Db.legend[" "])


func ground(c: Vector2i) -> String:
	return String(info(c)["ground"])


func is_tall(c: Vector2i) -> bool:
	return bool(info(c).get("tall", false))


## The stage that heals this cell (0 = never withered).
func region_stage(c: Vector2i) -> int:
	for r: Dictionary in heal_regions:
		var rect := Rect2i(int(r["rect"][0]), int(r["rect"][1]), int(r["rect"][2]), int(r["rect"][3]))
		if rect.has_point(c):
			return int(r["stage"])
	return 0


func is_withered(c: Vector2i, world_stage: int) -> bool:
	return not Restoration.is_healed(region_stage(c), world_stage)


func object_size(o: Dictionary) -> Vector2i:
	if o["kind"] == "house":
		return HOUSE_SIZE
	return cell_of(o["size"]) if o.has("size") else Vector2i.ONE


func footprint(o: Dictionary) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var origin: Vector2i = cell_of(o["cell"])
	var sz: Vector2i = object_size(o)
	for y: int in sz.y:
		for x: int in sz.x:
			out.append(origin + Vector2i(x, y))
	return out


func is_present(o: Dictionary, world_stage: int) -> bool:
	return not o.has("until_stage") or world_stage < int(o["until_stage"])


## The static object covering a cell (props, houses, signs), if any.
func object_at(c: Vector2i, world_stage: int) -> Dictionary:
	for o: Dictionary in objects:
		if o["kind"] in ["npc", "trainer"] or not is_present(o, world_stage):
			continue
		if footprint(o).has(c):
			return o
	return {}


func walkable(c: Vector2i, world_stage: int) -> bool:
	if not in_bounds(c) or not bool(info(c)["walk"]):
		return false
	if _warps.has(c):
		return true
	var o: Dictionary = object_at(c, world_stage)
	return o.is_empty() or bool(o.get("walk", false))


func warp_at(c: Vector2i) -> Dictionary:
	return _warps.get(c, {})


func warp_cells() -> Array:
	return _warps.keys()


## Top-left cells of the 2x2 tree blocks (letter # or P), with the kind of tree.
func tree_blocks() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for y: int in range(0, size.y - 1):
		for x: int in range(0, size.x - 1):
			var c := Vector2i(x, y)
			var kind: String = String(info(c).get("tree", ""))
			if kind != "" and _starts_block(c):
				out.append({"cell": c, "kind": kind})
	return out


func _starts_block(c: Vector2i) -> bool:
	var l: String = letter(c)
	if l != letter(c + Vector2i.RIGHT) or l != letter(c + Vector2i.DOWN) or l != letter(c + Vector2i.ONE):
		return false
	var left_run: int = 0
	while letter(c + Vector2i(-left_run - 1, 0)) == l:
		left_run += 1
	var up_run: int = 0
	while letter(c + Vector2i(0, -up_run - 1)) == l:
		up_run += 1
	return left_run % 2 == 0 and up_run % 2 == 0
