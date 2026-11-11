extends Node
## Map rules for every map in data/maps: rows all the same width, letters known, trees in whole 2x2 blocks,
## objects inside the map and not overlapping each other or blocked terrain, every walkable cell reachable,
## every door, warp, sign and person reachable (fully healed), warps leading to open cells of real maps.

var _problems: PackedStringArray = []
const HEALED: int = 3


func _ready() -> void:
	for id: String in Db.map_ids():
		_check_map(MapGrid.load_map(id))
	for p: String in _problems:
		print("MAP problem: ", p)
	print("MAPS %s (%d maps, %d problems)" % ["PASS" if _problems.is_empty() else "FAIL", Db.map_ids().size(), _problems.size()])
	get_tree().quit(0 if _problems.is_empty() else 1)


func fail(map: MapGrid, what: String) -> void:
	_problems.append("%s: %s" % [map.id, what])


func _check_map(m: MapGrid) -> void:
	for y: int in m.size.y:
		if m.rows[y].length() != m.size.x:
			fail(m, "row %d is %d wide (want %d)" % [y, m.rows[y].length(), m.size.x])
		for x: int in m.rows[y].length():
			if not Db.legend.has(m.rows[y][x]):
				fail(m, "unknown letter '%s' at %d,%d" % [m.rows[y][x], x, y])
	_check_trees(m)
	_check_objects(m)
	_check_reach(m)
	_check_warps(m)


func _check_trees(m: MapGrid) -> void:
	var covered: Dictionary = {}
	for b: Dictionary in m.tree_blocks():
		for d: Vector2i in [Vector2i.ZERO, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.ONE]:
			covered[b["cell"] + d] = true
	for y: int in m.size.y:
		for x: int in m.size.x:
			if m.info(Vector2i(x, y)).has("tree") and not covered.has(Vector2i(x, y)):
				fail(m, "tree cell %d,%d is not part of a whole 2x2 tree" % [x, y])


func _check_objects(m: MapGrid) -> void:
	var taken: Dictionary = {}
	for o: Dictionary in m.objects:
		for c: Vector2i in m.footprint(o):
			if not m.in_bounds(c):
				fail(m, "%s at %s sticks out of the map" % [o["kind"], c])
			elif taken.has(c):
				fail(m, "%s overlaps %s at %s" % [o["kind"], taken[c], c])
			elif not o["kind"] in ["house"] and m.info(c).has("tree"):
				fail(m, "%s stands in a tree at %s" % [o["kind"], c])
			taken[c] = o["kind"]
		if o["kind"] in ["npc", "trainer"] and not bool(m.info(MapGrid.cell_of(o["cell"]))["walk"]):
			fail(m, "%s stands on blocked ground at %s" % [o.get("id", ""), o["cell"]])
		if o["kind"] == "house" and not m.walkable(MapGrid.door_cell(o) + Vector2i.DOWN, HEALED):
			fail(m, "the door of house %s opens onto a blocked cell" % o["style"])


func _starts(m: MapGrid) -> Array:
	return m.warp_cells()


func _reachable(m: MapGrid) -> Dictionary:
	var seen: Dictionary = {}
	var queue: Array = _starts(m).duplicate()
	for c: Vector2i in queue:
		seen[c] = true
	while not queue.is_empty():
		var c: Vector2i = queue.pop_front()
		for d: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var n: Vector2i = c + d
			if not seen.has(n) and m.walkable(n, HEALED) and not _person_at(m, n):
				seen[n] = true
				queue.append(n)
	return seen


func _person_at(m: MapGrid, c: Vector2i) -> bool:
	for o: Dictionary in m.objects:
		if o["kind"] in ["npc", "trainer"] and MapGrid.cell_of(o["cell"]) == c and not o.get("wander", false):
			return true
	return false


func _check_reach(m: MapGrid) -> void:
	var seen: Dictionary = _reachable(m)
	for y: int in m.size.y:
		for x: int in m.size.x:
			var c := Vector2i(x, y)
			if m.walkable(c, HEALED) and not seen.has(c) and not _person_at(m, c):
				fail(m, "walkable cell %d,%d cannot be reached" % [x, y])
	for o: Dictionary in m.objects:
		if o.has("talk") or o["kind"] in ["npc", "trainer", "sign"]:
			if not _touchable(m, o, seen):
				fail(m, "%s at %s cannot be reached to talk to" % [o.get("id", o["kind"]), o["cell"]])


func _touchable(m: MapGrid, o: Dictionary, seen: Dictionary) -> bool:
	for c: Vector2i in m.footprint(o):
		for d: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			if seen.has(c + d) or seen.has(c + d * 2):
				return true
	return false


func _check_warps(m: MapGrid) -> void:
	for c: Vector2i in m.warp_cells():
		var to: Dictionary = m.warp_at(c)
		if not Db.map_ids().has(String(to["map"])):
			fail(m, "warp at %s leads to unknown map %s" % [c, to["map"]])
			continue
		var target: MapGrid = MapGrid.load_map(String(to["map"]))
		if not target.walkable(MapGrid.cell_of(to["cell"]), HEALED):
			fail(m, "warp at %s lands on a blocked cell of %s" % [c, to["map"]])
