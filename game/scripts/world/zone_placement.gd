class_name ZonePlacement
extends GenStep
## Set-pieces placed together on open ground of their clearing (never on a path, bridge or water, never on another
## prop; shore props by the water), the stone ring, then glass and rocks where clearings meet the thicket, away
## from every route. Rebuilds what blocks movement after each.

const SHIFTS: Array[Vector2] = [Vector2.ZERO, Vector2(32, 0), Vector2(-32, 0), Vector2(0, 32), Vector2(0, -32),
	Vector2(48, 32), Vector2(-48, 32), Vector2(48, -32), Vector2(-48, -32), Vector2(64, 0), Vector2(-64, 0)]


const GATE_STEP: float = 6.0


func run() -> void:
	_setpieces()
	_rebuild_blocked()
	_edge_props()
	_rebuild_blocked()


func _setpieces() -> void:
	for i: int in z.clearings.size():
		var c: Dictionary = z.clearings[i]
		var spec: Array = b["setpieces"].get(c["role"], [])
		var center: Vector2 = z.center_of(c["center"])
		if c["role"] == "circle":
			_stone_circle(i, center, spec)
			continue
		for shift: Vector2 in SHIFTS:
			var placed: Array[Dictionary] = _try_group(i, center + shift, spec)
			if not placed.is_empty() or spec.is_empty():
				z.props.append_array(placed)
				break


func _try_group(ci: int, center: Vector2, spec: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for sp: Dictionary in spec:
		if sp["kind"] == "pond":
			continue
		if sp.get("gate", false):
			out.append(_at_gate(sp, ci))
			continue
		var pos: Vector2 = (center + _vec(sp["at"])).round()
		var kind: String = String(sp["kind"])
		var prop: Dictionary = sp.duplicate()
		prop["kind"] = kind
		prop["pos"] = pos
		prop["foot"] = ZoneLayout.footprint(kind, pos)
		prop["clearing"] = ci
		if not _fits(prop, out):
			return []
		out.append(prop)
	return out


## Something standing at the city gate itself (the way back into Tallow): in front of the gate, on the cleared
## strip below the wall, not blocking anything.
func _at_gate(sp: Dictionary, ci: int) -> Dictionary:
	var prop: Dictionary = sp.duplicate()
	prop["pos"] = Vector2((z.gate_col + 2) * z.cell, z.wall_rows * z.cell + GATE_STEP)
	prop["foot"] = Rect2(prop["pos"], Vector2.ZERO)
	prop["clearing"] = ci
	return prop


## Ground under a prop must be open moss or stone of a clearing (never a path, bridge or water), clear of other
## props; shore props (reeds, the fisher) must also stand within two cells of water.
func _fits(prop: Dictionary, others: Array[Dictionary]) -> bool:
	var r: Rect2 = prop["foot"]
	var probe: Rect2 = r if r.size.x > 0.0 else Rect2(r.position - Vector2(6, 4), Vector2(12, 4))
	for c: Vector2i in z.cells_under(probe):
		if not [T.MOSS, T.STONE].has(z.t(c)):
			return false
	for o: Dictionary in z.props + others:
		if (o["foot"] as Rect2).grow(6.0).intersects(probe.grow(6.0)):
			return false
	if ["reeds", "statue_fisher"].has(prop["kind"]):
		return _near_water(z.cell_of(prop["pos"]), 2)
	return true


func _near_water(c: Vector2i, d: int) -> bool:
	for y: int in range(c.y - d, c.y + d + 1):
		for x: int in range(c.x - d, c.x + d + 1):
			if z.t(Vector2i(x, y)) == T.WATER:
				return true
	return false


func _stone_circle(ci: int, center: Vector2, spec: Array) -> void:
	var ring: Dictionary = spec[0]
	var rad: float = float(ring["r"])
	for y: int in range(z.cell_of(center).y - 7, z.cell_of(center).y + 8):
		for x: int in range(z.cell_of(center).x - 7, z.cell_of(center).x + 8):
			var cc := Vector2i(x, y)
			if z.center_of(cc).distance_to(center) < rad + z.cell * 0.9 and z.t(cc) == T.MOSS:
				z.set_t(cc, T.STONE)
	z.circle = Vector3(center.x, center.y, rad + z.cell * 0.9)
	var n: int = int(ring["count"])
	for k: int in n:
		var a: float = TAU * (k + 0.5) / n
		var pos: Vector2 = (center + Vector2(cos(a), sin(a) * 0.8) * rad).round()
		var stones: Array = ring.get("stones", ["menhir_a", "menhir_b"])
		var kind: String = String(stones[k % stones.size()])
		var prop := {"kind": kind, "pos": pos, "foot": ZoneLayout.footprint(kind, pos), "clearing": ci}
		if _fits(prop, []):
			z.props.append(prop)
	for sp: Dictionary in spec.slice(1):
		var pos: Vector2 = center + _vec(sp["at"])
		if sp["kind"] == "boss":
			z.boss = {"kind": String(sp["enemy"]), "pos": pos}
		else:
			z.props.append({"kind": String(sp["kind"]), "pos": pos, "foot": ZoneLayout.footprint(String(sp["kind"]), pos),
				"clearing": ci})


func _rebuild_blocked() -> void:
	for i: int in z.terrain.size():
		z.blocked[i] = 0 if ZoneLayout.WALKABLE.has(int(z.terrain[i])) else 1
	for p: Dictionary in z.props:
		var r: Rect2 = p["foot"]
		if r.size.x <= 0.0:
			continue
		for c: Vector2i in z.cells_under(r.grow(-2.0)):
			if z.inside(c):
				z.blocked[z.idx(c)] = 1


## Glass creeping out of the forest: crystals and rocks where open ground meets the thicket, never by a path.
func _edge_props() -> void:
	var cand: Array[Vector2i] = []
	for y: int in z.rows:
		for x: int in z.cols:
			var c := Vector2i(x, y)
			if z.t(c) == T.MOSS and z.clearing_id[z.idx(c)] >= 0 and z.blocked[z.idx(c)] == 0 and _touches(c, T.THICKET) \
					and not _near(c, T.PATH, 2) and not _near_route(c, 2) \
					and not _near(c, T.BRIDGE, 3) and not _near(c, T.WATER, 1):
				cand.append(c)
	_shuffle(cand)
	var placed: Array[Vector2] = []
	for kind: String in b["edge_props"]:
		var want: int = int(b["edge_props"][kind])
		for c: Vector2i in cand:
			if want <= 0:
				break
			var pos: Vector2 = z.center_of(c) + Vector2(0, z.cell * 0.4)
			if placed.any(func(q: Vector2) -> bool: return q.distance_to(pos) < z.cell * 3.0):
				continue
			var prop := {"kind": kind, "pos": pos.round(), "foot": ZoneLayout.footprint(kind, pos.round()), "clearing": -1}
			if _fits(prop, []):
				z.props.append(prop)
				placed.append(pos)
				want -= 1


func _touches(c: Vector2i, v: int) -> bool:
	for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		if z.t(c + d) == v:
			return true
	return false


func _near(c: Vector2i, v: int, d: int) -> bool:
	for y: int in range(c.y - d, c.y + d + 1):
		for x: int in range(c.x - d, c.x + d + 1):
			if z.t(Vector2i(x, y)) == v:
				return true
	return false


func _near_route(c: Vector2i, d: int) -> bool:
	for y: int in range(c.y - d, c.y + d + 1):
		for x: int in range(c.x - d, c.x + d + 1):
			if z.inside(Vector2i(x, y)) and z.route[z.idx(Vector2i(x, y))] == 1:
				return true
	return false
