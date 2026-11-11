class_name Nav
extends RefCounted
## Grid pathfinding over the zone (cells blocked by terrain or props), with corners only cut where both sides are
## free, and the path pulled tight (waypoints skipped while the straight line stays on free cells).

const SAMPLE: float = 8.0

var z: ZoneLayout
var grid := AStarGrid2D.new()


func _init(layout: ZoneLayout) -> void:
	z = layout
	grid.region = Rect2i(0, 0, z.cols, z.rows)
	grid.cell_size = Vector2(z.cell, z.cell)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	for y: int in z.rows:
		for x: int in z.cols:
			grid.set_point_solid(Vector2i(x, y), not z.walkable(Vector2i(x, y)))


## World points from `from` to `to` (to is snapped to the nearest free cell); empty if unreachable.
func path(from: Vector2, to: Vector2) -> PackedVector2Array:
	var a: Vector2i = nearest_free(z.cell_of(from))
	var b: Vector2i = nearest_free(z.cell_of(to))
	if a.x < 0 or b.x < 0:
		return PackedVector2Array()
	var ids: Array[Vector2i] = grid.get_id_path(a, b, true)
	var pts := PackedVector2Array()
	for c: Vector2i in ids:
		pts.append(z.center_of(c))
	if not pts.is_empty() and z.walkable(z.cell_of(to)):
		pts[pts.size() - 1] = to
	return _pull(from, pts)


func nearest_free(c: Vector2i) -> Vector2i:
	if z.walkable(c):
		return c
	for r: int in range(1, 4):
		for y: int in range(c.y - r, c.y + r + 1):
			for x: int in range(c.x - r, c.x + r + 1):
				if z.walkable(Vector2i(x, y)):
					return Vector2i(x, y)
	return Vector2i(-1, -1)


func line_free(a: Vector2, b: Vector2) -> bool:
	var n: int = maxi(1, ceili(a.distance_to(b) / SAMPLE))
	for i: int in n + 1:
		if not z.walkable(z.cell_of(a.lerp(b, float(i) / n))):
			return false
	return true


func _pull(from: Vector2, pts: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	var cur: Vector2 = from
	var i: int = 0
	while i < pts.size():
		var j: int = pts.size() - 1
		while j > i and not line_free(cur, pts[j]):
			j -= 1
		out.append(pts[j])
		cur = pts[j]
		i = j + 1
	return out
