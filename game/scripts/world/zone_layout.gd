class_name ZoneLayout
extends RefCounted
## The generated zone as plain data: a terrain grid (cells), what blocks movement, clearings and their roles,
## bridges, props with footprints, trees, interactables and enemy packs. ZoneGen fills it, ZoneView draws it,
## LayoutCheck verifies it. Positions are world pixels; footprints are Rect2 on the ground.

enum T { THICKET, MOSS, PATH, WATER, BRIDGE, STONE, WALL }

const WALKABLE: Array[int] = [T.MOSS, T.PATH, T.BRIDGE, T.STONE]

var cols: int
var rows: int
var cell: int
var seed: int
var terrain: PackedByteArray
var stream: PackedByteArray           ## 1 where the glass stream runs (paths may bridge it; ponds they may not)
var clearing_id: PackedInt32Array     ## which clearing a cell belongs to (-1: none)
var route: PackedByteArray            ## 1 along every path and trail (kept clear of props)
var blocked: PackedByteArray          ## 1 where nothing can stand: non-walkable terrain or a prop's footprint
var clearings: Array[Dictionary] = [] ## {role, center: Vector2i, r: Vector2, secret: bool}
var links: Array[Vector2i] = []
var bridges: Array[Rect2i] = []
var props: Array[Dictionary] = []     ## {kind, pos: Vector2, foot: Rect2, frame: int, role, ...}
var trees: Array[Dictionary] = []     ## {kind, pos: Vector2}
var spawns: Array[Dictionary] = []    ## {kind, pos: Vector2, rank, mods: Array, pack: int}
var boss: Dictionary = {}
var start: Vector2
var wall_cols: int
var wall_rows: int
var gate_col: int


func setup(c: int, r: int, cell_px: int, s: int) -> void:
	cols = c
	rows = r
	cell = cell_px
	seed = s
	terrain = PackedByteArray()
	terrain.resize(c * r)
	terrain.fill(T.THICKET)
	stream = PackedByteArray()
	stream.resize(c * r)
	clearing_id = PackedInt32Array()
	clearing_id.resize(c * r)
	clearing_id.fill(-1)
	route = PackedByteArray()
	route.resize(c * r)
	blocked = PackedByteArray()
	blocked.resize(c * r)


func size_px() -> Vector2:
	return Vector2(cols * cell, rows * cell)


func inside(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < cols and c.y < rows


func idx(c: Vector2i) -> int:
	return c.y * cols + c.x


func t(c: Vector2i) -> int:
	return terrain[idx(c)] if inside(c) else T.THICKET


func set_t(c: Vector2i, v: int) -> void:
	if inside(c):
		terrain[idx(c)] = v


func walkable_terrain(c: Vector2i) -> bool:
	return inside(c) and WALKABLE.has(int(terrain[idx(c)]))


func walkable(c: Vector2i) -> bool:
	return walkable_terrain(c) and blocked[idx(c)] == 0


func cell_of(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / cell), floori(p.y / cell))


func center_of(c: Vector2i) -> Vector2:
	return Vector2((c.x + 0.5) * cell, (c.y + 0.5) * cell)


func cell_rect(c: Vector2i) -> Rect2:
	return Rect2(c.x * cell, c.y * cell, cell, cell)


## Cells a ground rectangle touches.
func cells_under(r: Rect2) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var a: Vector2i = cell_of(r.position)
	var b: Vector2i = cell_of(r.end - Vector2(0.01, 0.01))
	for y: int in range(a.y, b.y + 1):
		for x: int in range(a.x, b.x + 1):
			out.append(Vector2i(x, y))
	return out


## Footprint of a prop of `kind` standing at `pos` (anchor = bottom centre).
static func footprint(kind: String, pos: Vector2) -> Rect2:
	var f: Array = GameData.props[kind]["foot"] if GameData.props.has(kind) else [16, 8]
	return Rect2(pos.x - float(f[0]) / 2.0, pos.y - float(f[1]), float(f[0]), float(f[1]))


func footprints() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for p: Dictionary in props:
		var r: Rect2 = p["foot"]
		if r.size.x > 0.0:
			out.append(r)
	return out


## Is a point free for a body of `radius`: walkable cell, not inside any footprint.
func point_free(p: Vector2, radius: float) -> bool:
	for off: Vector2 in [Vector2.ZERO, Vector2(radius, 0), Vector2(-radius, 0), Vector2(0, radius), Vector2(0, -radius)]:
		if not walkable(cell_of(p + off)):
			return false
	for r: Rect2 in footprints():
		if r.grow(radius).has_point(p):
			return false
	return true


func props_of(kind: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for p: Dictionary in props:
		if p["kind"] == kind:
			out.append(p)
	return out


func clearing_of_role(role: String) -> Dictionary:
	for c: Dictionary in clearings:
		if c["role"] == role:
			return c
	return {}
