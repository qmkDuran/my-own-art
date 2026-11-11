class_name ZoneForest
extends GenStep
## Trees stand only in the thicket, trunks clear of open ground (so what you see blocks you exactly where it
## stands), denser at the forest's edge than deep inside.

const TRUNK_MARGIN: float = 10.0


func run() -> void:
	_trees()


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
