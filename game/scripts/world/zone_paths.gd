class_name ZonePaths
extends GenStep
## Paths between clearings: a minimum spanning tree plus a couple of loops, each found by A* over the terrain (so
## they meander, merge with earlier paths, avoid ponds and cross the stream only where a bridge is then built),
## plus a narrow deer trail to the secret clearing. Records smoothed centre lines for drawing.

const PATH_WEIGHT: Dictionary = {T.THICKET: 3.0, T.MOSS: 1.0, T.PATH: 0.6, T.STONE: 1.0, T.BRIDGE: 0.6}
const STREAM_WEIGHT: float = 14.0
const MEANDER: float = 4.0
const CHAIKIN_PASSES: int = 3


func run() -> void:
	_links()
	_paths()


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
		_record_lines(cells)
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


## The drawn line of a path: the stretches outside clearings (one cell into each), corners rounded (Chaikin).
func _record_lines(cells: Array[Vector2i]) -> void:
	var run := PackedVector2Array()
	for i: int in cells.size():
		var inside: bool = z.clearing_id[z.idx(cells[i])] >= 0
		var near_out: bool = (i > 0 and z.clearing_id[z.idx(cells[i - 1])] < 0) or (i + 1 < cells.size() and z.clearing_id[z.idx(cells[i + 1])] < 0)
		if not inside or near_out:
			run.append(z.center_of(cells[i]))
		elif run.size() > 1:
			z.path_lines.append(_chaikin(run))
			run = PackedVector2Array()
	if run.size() > 1:
		z.path_lines.append(_chaikin(run))


func _chaikin(pts: PackedVector2Array) -> PackedVector2Array:
	var out: PackedVector2Array = pts
	for it: int in CHAIKIN_PASSES:
		var nxt := PackedVector2Array([out[0]])
		for i: int in out.size() - 1:
			nxt.append(out[i].lerp(out[i + 1], 0.25))
			nxt.append(out[i].lerp(out[i + 1], 0.75))
		nxt.append(out[out.size() - 1])
		out = nxt
	return out


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
