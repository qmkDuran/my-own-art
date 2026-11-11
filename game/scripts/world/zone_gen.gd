class_name ZoneGen
extends RefCounted
## Lays out a zone from biome rules (data/glasswood.json) and a seed. Order matters and each step has a reason:
## the city wall and the stream first (geography), then clearings away from the water, ponds, paths found by A*
## (they meander, merge, avoid ponds and cross the stream only where a bridge is then built), the map border,
## set-pieces (props placed together, only on open ground, never on a path), edge details where the forest meets
## the clearings, trees only inside the forest, and finally the enemy packs. ZoneGen.make() retries the next seed
## if LayoutCheck finds a problem, so a broken zone is never shown.

const T := ZoneLayout.T
const MAX_TRIES: int = 12
const PLACE_TRIES: int = 600
const SHIFTS: Array[Vector2] = [Vector2.ZERO, Vector2(32, 0), Vector2(-32, 0), Vector2(0, 32), Vector2(0, -32),
	Vector2(48, 32), Vector2(-48, 32), Vector2(48, -32), Vector2(-48, -32), Vector2(64, 0), Vector2(-64, 0)]
const PATH_WEIGHT: Dictionary = {T.THICKET: 3.0, T.MOSS: 1.0, T.PATH: 0.6, T.STONE: 1.0, T.BRIDGE: 0.6}
const STREAM_WEIGHT: float = 14.0
const MEANDER: float = 4.0
const TRUNK_MARGIN: float = 10.0

var b: Dictionary
var rng := RandomNumberGenerator.new()
var noise := FastNoiseLite.new()
var z: ZoneLayout


## A zone that passed every layout check (tries following seeds if needed).
static func make(biome: Dictionary, seed_value: int) -> ZoneLayout:
	for k: int in MAX_TRIES:
		var gen := ZoneGen.new()
		var layout: ZoneLayout = gen.generate(biome, seed_value + k * 7919)
		if LayoutCheck.problems(layout).is_empty():
			return layout
	push_error("ZoneGen: no valid layout near seed %d" % seed_value)
	return ZoneGen.new().generate(biome, seed_value)


func generate(biome: Dictionary, seed_value: int) -> ZoneLayout:
	b = biome
	rng.seed = seed_value
	noise.seed = seed_value
	noise.frequency = 0.08
	z = ZoneLayout.new()
	z.setup(int(b["cols"]), int(b["rows"]), int(b["cell"]), seed_value)
	_wall()
	_stream()
	_clearings()
	_ponds()
	_links()
	_paths()
	_border()
	_setpieces()
	_rebuild_blocked()
	_edge_props()
	_rebuild_blocked()
	_trees()
	_packs()
	return z


# ------------------------------------------------------------------ geography
func _wall() -> void:
	var w: Dictionary = b["wall"]
	z.wall_cols = int(w["cols"])
	z.wall_rows = int(w["rows"])
	z.gate_col = int(w["gate_col"])
	for y: int in z.wall_rows:
		for x: int in z.wall_cols:
			z.set_t(Vector2i(x, y), T.WALL)
	z.start = Vector2((z.gate_col + 2) * z.cell, (z.wall_rows + 2.5) * z.cell)
	for y: int in range(z.wall_rows, z.wall_rows + 2):            # the city keeps a cleared strip below its wall
		for x: int in range(int(b["border"]), z.wall_cols):
			z.set_t(Vector2i(x, y), T.MOSS)


func stream_x(row: float) -> float:
	var s: Dictionary = b["stream"]
	var amp: Array = s["amp"]
	var fr: Array = s["freq"]
	return z.cols * float(s["x_frac"]) + sin(row * float(fr[0]) + float(z.seed % 97)) * float(amp[1]) \
		+ sin(row * float(fr[1]) + float(z.seed % 13)) * float(amp[0])


func _stream() -> void:
	var half: int = int(b["stream"]["width"]) / 2
	for y: int in z.rows:
		var cx: int = roundi(stream_x(y))
		for x: int in range(cx - half, cx + half + 1):
			var c := Vector2i(x, y)
			if z.inside(c) and z.t(c) != T.WALL:
				z.set_t(c, T.WATER)
				z.stream[z.idx(c)] = 1


# ------------------------------------------------------------------ clearings
func _clearings() -> void:
	for spec: Dictionary in b["clearings"]:
		var r := Vector2(float(spec["r"][0]), float(spec["r"][1]))
		var at: Vector2i = _clearing_spot(spec, r)
		if at.x < 0:
			continue
		var c := {"role": String(spec["role"]), "center": at, "r": r, "secret": bool(spec.get("secret", false))}
		z.clearings.append(c)
		_carve_clearing(z.clearings.size() - 1)


func _clearing_spot(spec: Dictionary, r: Vector2) -> Vector2i:
	if spec.has("at"):
		return Vector2i(int(spec["at"][0]), int(spec["at"][1]))
	if spec.has("at_frac"):
		return Vector2i(roundi(z.cols * float(spec["at_frac"][0])), roundi(z.rows * float(spec["at_frac"][1])))
	var margin: int = int(b["border"]) + 3
	for k: int in PLACE_TRIES:
		var c := Vector2i(rng.randi_range(margin + int(r.x), z.cols - margin - int(r.x)),
			rng.randi_range(margin + int(r.y), z.rows - margin - int(r.y)))
		if _clearing_ok(c, r):
			return c
	return Vector2i(-1, -1)


func _clearing_ok(c: Vector2i, r: Vector2) -> bool:
	if c.x - r.x < z.wall_cols + 2 and c.y - r.y < z.wall_rows + 3:
		return false
	for y: int in range(c.y - int(r.y) - 1, c.y + int(r.y) + 2):
		if absf(stream_x(y) - c.x) < r.x + 4.0:
			return false
	for o: Dictionary in z.clearings:
		var oc: Vector2i = o["center"]
		var orad: Vector2 = o["r"]
		if Vector2(oc).distance_to(Vector2(c)) < maxf(r.x, r.y) + maxf(orad.x, orad.y) + float(b["clearing_spacing"]) * 0.5:
			return false
	return true


func _carve_clearing(i: int) -> void:
	var c: Dictionary = z.clearings[i]
	var ctr: Vector2i = c["center"]
	var r: Vector2 = c["r"]
	for y: int in range(ctr.y - int(r.y) - 2, ctr.y + int(r.y) + 3):
		for x: int in range(ctr.x - int(r.x) - 2, ctr.x + int(r.x) + 3):
			var cc := Vector2i(x, y)
			var d: float = Vector2(float(x - ctr.x) / r.x, float(y - ctr.y) / r.y).length()
			if d < 1.0 + noise.get_noise_2d(x * 3.0, y * 3.0) * 0.18 and z.t(cc) == T.THICKET:
				z.set_t(cc, T.MOSS)
				z.clearing_id[z.idx(cc)] = i


func _ponds() -> void:
	for i: int in z.clearings.size():
		for sp: Dictionary in b["setpieces"].get(z.clearings[i]["role"], []):
			if sp["kind"] != "pond":
				continue
			var ctr: Vector2 = z.center_of(z.clearings[i]["center"]) + _vec(sp["at"])
			var rr := Vector2(float(sp["r"][0]), float(sp["r"][1])) * z.cell
			for y: int in range(z.cell_of(ctr).y - 4, z.cell_of(ctr).y + 5):
				for x: int in range(z.cell_of(ctr).x - 7, z.cell_of(ctr).x + 8):
					var cc := Vector2i(x, y)
					var p: Vector2 = z.center_of(cc) - ctr
					if Vector2(p.x / rr.x, p.y / rr.y).length() < 1.0 and z.clearing_id[z.idx(cc)] == i:
						z.set_t(cc, T.WATER)


# ------------------------------------------------------------------ links and paths
func _links() -> void:
	var open: Array[int] = []
	for i: int in z.clearings.size():
		if not z.clearings[i]["secret"]:
			open.append(i)
	var linked: Array[int] = [open[0]]
	var rest: Array[int] = open.slice(1)
	while not rest.is_empty():                              # Prim's minimum spanning tree over clearing centres
		var best := Vector2i(-1, -1)
		var best_d: float = INF
		for a: int in linked:
			for c: int in rest:
				var d: float = _cdist(a, c)
				if d < best_d:
					best_d = d
					best = Vector2i(a, c)
		z.links.append(best)
		linked.append(best.y)
		rest.erase(best.y)
	_extra_links(open)


func _extra_links(open: Array[int]) -> void:
	var cand: Array[Vector2i] = []
	for a: int in open:
		for c: int in open:
			if a < c and not z.links.has(Vector2i(a, c)) and not z.links.has(Vector2i(c, a)):
				cand.append(Vector2i(a, c))
	cand.sort_custom(func(p: Vector2i, q: Vector2i) -> bool: return _cdist(p.x, p.y) < _cdist(q.x, q.y))
	for k: int in mini(int(b["extra_links"]), cand.size()):
		z.links.append(cand[k])


func _cdist(a: int, c: int) -> float:
	return Vector2(z.clearings[a]["center"]).distance_to(Vector2(z.clearings[c]["center"]))


func _astar(narrow: bool) -> AStarGrid2D:
	var a := AStarGrid2D.new()
	a.region = Rect2i(0, 0, z.cols, z.rows)
	a.cell_size = Vector2(1, 1)
	a.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	a.update()
	var edge: int = int(b["border"]) + 1
	for y: int in z.rows:
		for x: int in z.cols:
			var c := Vector2i(x, y)
			var tt: int = z.t(c)
			var solid: bool = tt == T.WALL or (tt == T.WATER and (narrow or z.stream[z.idx(c)] == 0)) \
				or x < edge or y < edge or x >= z.cols - edge or y >= z.rows - edge
			a.set_point_solid(c, solid)
			if not solid:
				var w: float = STREAM_WEIGHT if tt == T.WATER else float(PATH_WEIGHT.get(tt, 1.0))
				a.set_point_weight_scale(c, w + (noise.get_noise_2d(x * 1.7, y * 1.7) + 1.0) * MEANDER * 0.5)
	return a


func _paths() -> void:
	var p: Dictionary = b["path"]
	for l: Vector2i in z.links:
		var a: AStarGrid2D = _astar(false)                  # rebuilt per link so later paths prefer earlier ones
		var cells: Array[Vector2i] = a.get_id_path(z.clearings[l.x]["center"], z.clearings[l.y]["center"])
		_carve_path(cells, float(p["half_width"]), float(p["verge"]), true)
		_bridge(cells)
	_secret_trail()


func _carve_path(cells: Array[Vector2i], half: float, verge: float, dirt: bool) -> void:
	for c: Vector2i in cells:
		z.route[z.idx(c)] = 1
		if z.clearing_id[z.idx(c)] >= 0 and z.t(c) != T.THICKET:
			continue                                           # inside a clearing the open ground is the way
		_disc(c, verge, T.MOSS, [T.THICKET])
		if dirt:
			_disc(c, half, T.PATH, [T.THICKET, T.MOSS])


func _disc(c: Vector2i, rad: float, v: int, over: Array) -> void:
	var r: int = ceili(rad)
	for y: int in range(c.y - r, c.y + r + 1):
		for x: int in range(c.x - r, c.x + r + 1):
			var cc := Vector2i(x, y)
			if z.inside(cc) and Vector2(x - c.x, y - c.y).length() <= rad and over.has(z.t(cc)) \
					and z.clearing_id[z.idx(cc)] < 0:
				z.set_t(cc, v)


## Where a path crosses the stream, a plank bridge three cells wide spans it from bank to bank.
func _bridge(cells: Array[Vector2i]) -> void:
	var group: Array[Vector2i] = []
	for i: int in cells.size() + 1:
		var c: Vector2i = cells[i] if i < cells.size() else Vector2i(-1, -1)
		if c.x >= 0 and z.stream[z.idx(c)] == 1:
			group.append(c)
		elif not group.is_empty():
			_span(group)
			group.clear()


func _span(group: Array[Vector2i]) -> void:
	var row: int = 0
	for c: Vector2i in group:
		row += c.y
	row = roundi(float(row) / group.size())
	var xa: int = z.cols
	var xb: int = 0
	for y: int in range(row - 1, row + 2):
		for x: int in range(group[0].x - 6, group[0].x + 7):
			if z.inside(Vector2i(x, y)) and z.stream[z.idx(Vector2i(x, y))] == 1:
				xa = mini(xa, x)
				xb = maxi(xb, x)
	if group.all(func(c: Vector2i) -> bool: return z.t(c) == T.BRIDGE):
		return                                             # the path already uses an existing bridge
	var rect := Rect2i(xa - 1, row - 1, xb - xa + 3, 3)
	z.bridges.append(rect)
	for y: int in range(rect.position.y, rect.end.y):
		for x: int in range(rect.position.x, rect.end.x):
			z.set_t(Vector2i(x, y), T.BRIDGE)
	for side: int in [-1, 1]:                               # a straight approach on each bank
		var x0: int = rect.position.x - 1 if side < 0 else rect.end.x
		for k: int in 3:
			for y: int in range(row - 1, row + 2):
				var cc := Vector2i(x0 + side * k, y)
				if z.t(cc) == T.THICKET or z.t(cc) == T.MOSS:
					z.set_t(cc, T.PATH if y == row or k < 2 else T.MOSS)


## The secret clearing hangs off its nearest clearing by a narrow deer trail (moss, no dirt, no bridge).
func _secret_trail() -> void:
	for i: int in z.clearings.size():
		if not z.clearings[i]["secret"]:
			continue
		var order: Array[int] = []
		for j: int in z.clearings.size():
			if j != i and not z.clearings[j]["secret"]:
				order.append(j)
		order.sort_custom(func(p: int, q: int) -> bool: return _cdist(i, p) < _cdist(i, q))
		var a: AStarGrid2D = _astar(true)
		for j: int in order:
			var cells: Array[Vector2i] = a.get_id_path(z.clearings[i]["center"], z.clearings[j]["center"])
			if not cells.is_empty():
				_carve_path(cells, 0.0, 1.0, false)
				z.links.append(Vector2i(j, i))
				break


func _border() -> void:
	var e: int = int(b["border"])
	for y: int in z.rows:
		for x: int in z.cols:
			if (x < e or y < e or x >= z.cols - e or y >= z.rows - e) and z.t(Vector2i(x, y)) != T.WALL:
				z.set_t(Vector2i(x, y), T.THICKET)
				z.stream[z.idx(Vector2i(x, y))] = 0


# ------------------------------------------------------------------ set-pieces
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
	var n: int = int(ring["count"])
	for k: int in n:
		var a: float = TAU * (k + 0.5) / n
		var pos: Vector2 = (center + Vector2(cos(a), sin(a) * 0.8) * rad).round()
		var kind: String = "menhir_a" if k % 2 else "menhir_b"
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


# ------------------------------------------------------------------ edges, trees
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


## Distance (in cells) from every cell to the nearest walkable cell, by breadth-first search.
func _depth() -> PackedInt32Array:
	var d := PackedInt32Array()
	d.resize(z.cols * z.rows)
	d.fill(1 << 20)
	var q: Array[Vector2i] = []
	for y: int in z.rows:
		for x: int in z.cols:
			if z.walkable_terrain(Vector2i(x, y)):
				d[y * z.cols + x] = 0
				q.append(Vector2i(x, y))
	var head: int = 0
	while head < q.size():
		var c: Vector2i = q[head]
		head += 1
		for n: Vector2i in [c + Vector2i.LEFT, c + Vector2i.RIGHT, c + Vector2i.UP, c + Vector2i.DOWN]:
			if z.inside(n) and d[z.idx(n)] > d[z.idx(c)] + 1:
				d[z.idx(n)] = d[z.idx(c)] + 1
				q.append(n)
	return d


## Trees stand only in the thicket, trunks clear of open ground (so what you see blocks you exactly where it
## stands), denser at the forest's edge than deep inside.
func _trees() -> void:
	var tr: Dictionary = b["trees"]
	var depth: PackedInt32Array = _depth()
	var kinds: Dictionary = tr["kinds"]
	var step: float = float(tr["edge_spacing"])
	var y: float = step * 0.5
	while y < z.rows * z.cell:
		var x: float = step * 0.5
		while x < z.cols * z.cell:
			var p := Vector2(x + rng.randf_range(-step, step) * 0.4, y + rng.randf_range(-step, step) * 0.4).round()
			var c: Vector2i = z.cell_of(p)
			if z.inside(c) and z.t(c) == T.THICKET and _trunk_clear(p):
				var deep: bool = depth[z.idx(c)] > int(tr["edge_depth"])
				if not deep or rng.randf() < pow(step / float(tr["deep_spacing"]), 2.0):
					z.trees.append({"kind": _weighted(kinds), "pos": p})
			x += step
		y += step


func _trunk_clear(p: Vector2) -> bool:
	for off: Vector2 in [Vector2(TRUNK_MARGIN, 0), Vector2(-TRUNK_MARGIN, 0), Vector2(0, TRUNK_MARGIN), Vector2(0, -4)]:
		if z.t(z.cell_of(p + off)) != T.THICKET:
			return false
	return true


# ------------------------------------------------------------------ enemies
func _packs() -> void:
	var pk: Dictionary = b["packs"]
	var cand: Array[Vector2i] = []
	var far: float = 0.0
	for y: int in z.rows:
		for x: int in z.cols:
			var c := Vector2i(x, y)
			if _pack_cell_ok(c, pk):
				cand.append(c)
				far = maxf(far, z.center_of(c).distance_to(z.start))
	_shuffle(cand)
	var centers: Array[Vector2] = []
	for c: Vector2i in cand:
		if centers.size() >= int(pk["count"]):
			break
		var pos: Vector2 = z.center_of(c)
		if centers.any(func(q: Vector2) -> bool: return q.distance_to(pos) < float(pk["spacing"]) * z.cell):
			continue
		centers.append(pos)
	var elites: Array[int] = _elite_packs(centers, far, int(pk["elites"]))
	for i: int in centers.size():
		_pack(i, centers[i], centers[i].distance_to(z.start) / far, elites.has(i))


func _pack_cell_ok(c: Vector2i, pk: Dictionary) -> bool:
	if not (z.t(c) == T.MOSS or z.t(c) == T.PATH) or not z.walkable(c):
		return false
	if z.center_of(c).distance_to(z.start) < float(pk["safe_radius"]) * z.cell:
		return false
	var ci: int = z.clearing_id[z.idx(c)]
	return ci < 0 or not ["start", "circle", "secret"].has(z.clearings[ci]["role"])


func _elite_packs(centers: Array[Vector2], far: float, n: int) -> Array[int]:
	var idx: Array[int] = []
	for i: int in centers.size():
		if centers[i].distance_to(z.start) / far > 0.3:
			idx.append(i)
	_shuffle(idx)
	return idx.slice(0, n)


func _pack(i: int, center: Vector2, progress: float, elite: bool) -> void:
	var row: Dictionary = b["packs"]["table"][0]
	for r: Dictionary in b["packs"]["table"]:
		if progress >= float(r["from"]):
			row = r
	var size: int = rng.randi_range(int(row["size"][0]), int(row["size"][1]))
	var mods: Array = GameData.enemies["mods"].keys()
	var members: Array[Dictionary] = []
	for k: int in size:
		var kind: String = _weighted(row["kinds"])
		var rank: String = "normal"
		if elite:
			rank = "rare" if k == 0 else ("magic" if k < 3 else "normal")
		var m: Array = []
		for j: int in int(GameData.enemies["ranks"][rank]["mods"]):
			var pick: String = mods[rng.randi_range(0, mods.size() - 1)]
			if not m.has(pick):
				m.append(pick)
		var pos: Vector2 = _member_spot(center, kind, members)
		if pos != Vector2.INF:
			members.append({"kind": kind, "pos": pos, "rank": rank, "mods": m, "pack": i, "level_progress": progress})
	z.spawns.append_array(members)


func _member_spot(center: Vector2, kind: String, members: Array[Dictionary]) -> Vector2:
	var rad: float = float(GameData.enemy(kind)["radius"])
	for k: int in 30:
		var p: Vector2 = (center + Vector2(rng.randf_range(-70, 70), rng.randf_range(-50, 50))).round()
		if not z.point_free(p, rad):
			continue
		if members.any(func(o: Dictionary) -> bool:
				return (o["pos"] as Vector2).distance_to(p) < rad + float(GameData.enemy(o["kind"])["radius"]) + 4.0):
			continue
		return p
	return Vector2.INF


# ------------------------------------------------------------------ helpers
func _weighted(table: Dictionary) -> String:
	var total: float = 0.0
	for k: String in table:
		total += float(table[k])
	var roll: float = rng.randf() * total
	for k: String in table:
		roll -= float(table[k])
		if roll <= 0.0:
			return k
	return String(table.keys()[0])


func _shuffle(a: Array) -> void:
	for i: int in range(a.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: Variant = a[i]
		a[i] = a[j]
		a[j] = tmp


static func _vec(a: Array) -> Vector2:
	return Vector2(float(a[0]), float(a[1]))
