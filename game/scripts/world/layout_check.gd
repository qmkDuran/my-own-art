class_name LayoutCheck
extends RefCounted
## Every rule a zone must keep to look logical, as code. ZoneGen rejects any layout that breaks one; the test
## runner (--layout) runs it over many seeds. Each problem is a sentence a person can act on.

const T := ZoneLayout.T
const CHEST_REASONS: Array[String] = ["hut", "tower", "cart", "bedroll", "campfire", "cairn", "farmhouse", "haystack", "house_a",
	"house_b", "house_c", "dock", "barrels", "stall_a", "stall_b", "well"]
const CHEST_REASON_DIST: float = 110.0
const START_CLEAR: float = 420.0


static func problems(z: ZoneLayout) -> PackedStringArray:
	var out := PackedStringArray()
	_roles(z, out)
	_reachable(z, out)
	_props(z, out)
	_trees(z, out)
	_bridges(z, out)
	_border(z, out)
	_chests(z, out)
	_spawns(z, out)
	return out


## Every clearing the biome requires was placed; a zone with a boss has its arena and boss.
static func _roles(z: ZoneLayout, out: PackedStringArray) -> void:
	for role: String in GameData.biome.get("required", []):
		if z.clearing_of_role(role).is_empty():
			out.append("clearing '%s' could not be placed" % role)
	if GameData.biome.get("events", {}).has("boss") and z.boss.is_empty():
		out.append("no boss placed in its arena")
	_setpieces_placed(z, out)


## Every clearing with a set-piece really got it (a group that cannot fit must not vanish silently).
static func _setpieces_placed(z: ZoneLayout, out: PackedStringArray) -> void:
	var sp: Dictionary = GameData.biome.get("setpieces", {})
	for i: int in z.clearings.size():
		var role: String = String(z.clearings[i]["role"])
		var wants: Array = (sp.get(role, []) as Array).filter(func(d: Dictionary) -> bool: return d["kind"] != "pond" and not d.get("gate", false))
		if wants.is_empty() or GameData.biome.get("city", false):
			continue
		if not z.props.any(func(p: Dictionary) -> bool: return int(p.get("clearing", -2)) == i):
			out.append("the %s set-piece could not be placed in its clearing" % role)


## Flood fill from the start over walkable, unblocked cells.
static func reach(z: ZoneLayout) -> PackedByteArray:
	var seen := PackedByteArray()
	seen.resize(z.cols * z.rows)
	var q: Array[Vector2i] = [z.cell_of(z.start)]
	seen[z.idx(q[0])] = 1
	var head: int = 0
	while head < q.size():
		var c: Vector2i = q[head]
		head += 1
		for n: Vector2i in [c + Vector2i.LEFT, c + Vector2i.RIGHT, c + Vector2i.UP, c + Vector2i.DOWN]:
			if z.inside(n) and seen[z.idx(n)] == 0 and z.walkable(n):
				seen[z.idx(n)] = 1
				q.append(n)
	return seen


static func _reachable(z: ZoneLayout, out: PackedStringArray) -> void:
	var seen: PackedByteArray = reach(z)
	if not z.walkable(z.cell_of(z.start)):
		out.append("the start point is not on open ground")
	for c: Dictionary in z.clearings:
		if seen[z.idx(c["center"])] == 0 and z.walkable(c["center"]):
			out.append("clearing '%s' cannot be reached from the start" % c["role"])
	for p: Dictionary in z.props:
		if _interactive(p) and not _stand_spot_reached(z, p, seen):
			out.append("%s at %s has no reachable spot to stand and use it" % [p["kind"], p["pos"]])
	if not z.boss.is_empty() and seen[z.idx(z.cell_of(z.boss["pos"]))] == 0:
		out.append("the boss stands where the player cannot reach")


static func _interactive(p: Dictionary) -> bool:
	return ["chest", "waylamp", "note", "npc", "cairn", "statue_fisher", "cocoon", "exit"].has(p["kind"])


static func _stand_spot_reached(z: ZoneLayout, p: Dictionary, seen: PackedByteArray) -> bool:
	var c: Vector2i = z.cell_of(p["pos"])
	for y: int in range(c.y - 1, c.y + 3):
		for x: int in range(c.x - 2, c.x + 3):
			if z.inside(Vector2i(x, y)) and seen[z.idx(Vector2i(x, y))] == 1:
				return true
	return false


## Props never overlap each other, never stand on paths, bridges or water, and stay inside the map.
static func _props(z: ZoneLayout, out: PackedStringArray) -> void:
	for i: int in z.props.size():
		var a: Dictionary = z.props[i]
		var ra: Rect2 = a["foot"]
		if ra.size.x <= 0.0:
			ra = Rect2(ra.position - Vector2(6, 4), Vector2(12, 4))
		for c: Vector2i in z.cells_under(ra):
			if not [T.MOSS, T.STONE].has(z.t(c)):
				out.append("%s at %s stands on %s" % [a["kind"], a["pos"], T.keys()[z.t(c)]])
				break
		for j: int in range(i + 1, z.props.size()):
			var rb: Rect2 = z.props[j]["foot"]
			if rb.size.x > 0.0 and ra.intersects(rb):
				out.append("%s and %s overlap at %s" % [a["kind"], z.props[j]["kind"], a["pos"]])


## Trees grow only in the thicket and their trunks never touch open ground.
static func _trees(z: ZoneLayout, out: PackedStringArray) -> void:
	for t: Dictionary in z.trees:
		var p: Vector2 = t["pos"]
		for off: Vector2 in [Vector2(8, 0), Vector2(-8, 0), Vector2(0, 8), Vector2.ZERO]:
			if z.t(z.cell_of(p + off)) != T.THICKET:
				out.append("tree at %s is not inside the forest (touches %s)" % [p, T.keys()[z.t(z.cell_of(p + off))]])
				break


## Bridges span water from bank to bank: both ends land on walkable ground.
static func _bridges(z: ZoneLayout, out: PackedStringArray) -> void:
	for r: Rect2i in z.bridges:
		var row: int = r.position.y + 1
		var west := Vector2i(r.position.x - 1, row)
		var east := Vector2i(r.end.x, row)
		if not (z.walkable_terrain(west) and z.walkable_terrain(east)):
			out.append("bridge at %s does not land on ground at both ends" % r)
	for i: int in z.terrain.size():
		if z.stream[i] == 1 and z.terrain[i] != T.WATER and z.terrain[i] != T.BRIDGE:
			out.append("the stream is broken at cell %d" % i)
			return


## The map edge is closed (forest or wall all round) and the city wall is unbroken.
static func _border(z: ZoneLayout, out: PackedStringArray) -> void:
	for x: int in z.cols:
		for y: int in [0, z.rows - 1]:
			if z.walkable_terrain(Vector2i(x, y)):
				out.append("the map edge is open at %s" % Vector2i(x, y))
				return
	for y: int in z.rows:
		for x: int in [0, z.cols - 1]:
			if z.walkable_terrain(Vector2i(x, y)):
				out.append("the map edge is open at %s" % Vector2i(x, y))
				return
	for x: int in z.wall_cols:
		for y: int in z.wall_rows:
			if z.t(Vector2i(x, y)) != T.WALL:
				out.append("the city wall has a gap at %s" % Vector2i(x, y))
				return


## A chest has a reason to be where it is: by a hut, a tower, a cart, a camp or a cairn.
static func _chests(z: ZoneLayout, out: PackedStringArray) -> void:
	for c: Dictionary in z.props_of("chest"):
		var ok: bool = false
		for p: Dictionary in z.props:
			if CHEST_REASONS.has(p["kind"]) and (p["pos"] as Vector2).distance_to(c["pos"]) < CHEST_REASON_DIST:
				ok = true
		if not ok:
			out.append("chest at %s has no reason to be there" % c["pos"])


## Enemies stand on open ground, not inside props or each other, and not on top of the player's arrival.
static func _spawns(z: ZoneLayout, out: PackedStringArray) -> void:
	for i: int in z.spawns.size():
		var s: Dictionary = z.spawns[i]
		var p: Vector2 = s["pos"]
		var r: float = float(GameData.enemy(s["kind"])["radius"])
		if not z.point_free(p, r):
			out.append("%s at %s spawns inside something" % [s["kind"], p])
		if p.distance_to(z.start) < START_CLEAR:
			out.append("%s at %s spawns on top of the arrival" % [s["kind"], p])
		for j: int in range(i + 1, z.spawns.size()):
			var o: Dictionary = z.spawns[j]
			if (o["pos"] as Vector2).distance_to(p) < r + float(GameData.enemy(o["kind"])["radius"]):
				out.append("%s and %s spawn overlapping at %s" % [s["kind"], o["kind"], p])
	if z.spawns.size() < int(GameData.biome.get("packs", {}).get("count", 0)) * 2:
		out.append("too few enemies (%d)" % z.spawns.size())
