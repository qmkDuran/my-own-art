class_name ArenaLayout
extends ZoneLayout
## A small hand-made space (a battle arena, the Gate Hall) as a ZoneLayout, so movement, pathing and placement work
## as on the route. It sits at `origin` in the world, away from the route. On top of the walkable grid it keeps a
## feature per cell (tall grass, water, mud, cover rocks, trees, ledges...) that moves and terrain rules read
## (TerrainRules) and that moves can change (TerrainChange: burn grass, raise vines, break rocks).

enum F { NONE, GRASS, SHALLOW, DEEP, MUD, ROCK, TREE, THICKET, ROOTS, LEDGE, RAMP, THORNS, WALL, BRIDGE, CRACKED, COALS, VINE, FLAT,
	ASH, BURNT, RUBBLE, PIT }

const MOVE_BLOCK: Array[int] = [F.ROCK, F.TREE, F.THICKET, F.WALL, F.DEEP, F.VINE]
const SHOT_BLOCK: Array[int] = [F.ROCK, F.TREE, F.WALL, F.VINE]
const NAMES: Dictionary = {"none": F.NONE, "grass": F.GRASS, "shallow": F.SHALLOW, "deep": F.DEEP, "mud": F.MUD,
	"rock": F.ROCK, "tree": F.TREE, "thicket": F.THICKET, "roots": F.ROOTS, "ledge": F.LEDGE, "ramp": F.RAMP,
	"thorns": F.THORNS, "wall": F.WALL, "bridge": F.BRIDGE, "cracked": F.CRACKED, "coals": F.COALS, "vine": F.VINE,
	"flat": F.FLAT, "ash": F.ASH, "burnt": F.BURNT, "rubble": F.RUBBLE, "pit": F.PIT}

var origin: Vector2 = Vector2.ZERO
var feature: PackedByteArray
var hp: PackedFloat32Array              ## rocks, bridges, cracked floor and vines can break (burning cells: how far the fire spread)
var timer: PackedFloat32Array           ## passing states (burning, ash, burnt, flattened, vines) last this long
var under: PackedByteArray              ## what a passing state replaced


func build(c: int, r: int, cell_px: int, at: Vector2) -> ArenaLayout:
	setup(c, r, cell_px, 0)
	origin = at
	terrain.fill(T.MOSS)
	feature = PackedByteArray()
	feature.resize(c * r)
	hp = PackedFloat32Array()
	hp.resize(c * r)
	timer = PackedFloat32Array()
	timer.resize(c * r)
	under = PackedByteArray()
	under.resize(c * r)
	for x: int in c:
		set_f(Vector2i(x, 0), F.WALL)
		set_f(Vector2i(x, r - 1), F.WALL)
	for y: int in r:
		set_f(Vector2i(0, y), F.WALL)
		set_f(Vector2i(c - 1, y), F.WALL)
	start = center_of(Vector2i(c / 2, r / 2))
	return self


func cell_of(p: Vector2) -> Vector2i:
	return Vector2i(floori((p.x - origin.x) / cell), floori((p.y - origin.y) / cell))


func center_of(c: Vector2i) -> Vector2:
	return origin + Vector2((c.x + 0.5) * cell, (c.y + 0.5) * cell)


func cell_rect(c: Vector2i) -> Rect2:
	return Rect2(origin + Vector2(c.x * cell, c.y * cell), Vector2(cell, cell))


func rect_px() -> Rect2:
	return Rect2(origin, size_px())


func f(c: Vector2i) -> int:
	return int(feature[idx(c)]) if inside(c) else F.WALL


func f_at(p: Vector2) -> int:
	return f(cell_of(p))


## Sets a cell's feature; what blocks movement becomes blocked (the static body is rebuilt by ArenaView).
func set_f(c: Vector2i, v: int, life: float = 0.0) -> void:
	if not inside(c):
		return
	feature[idx(c)] = v
	hp[idx(c)] = life
	blocked[idx(c)] = 1 if MOVE_BLOCK.has(v) else 0


## A passing state that lasts `seconds` (TerrainChange decides what follows). The first of a chain remembers what it
## replaced; `chained` states (fire -> ash -> burnt) keep that memory.
func set_temporary(c: Vector2i, v: int, seconds: float, life: float = 0.0, chained: bool = false) -> void:
	if not inside(c) or f(c) == F.WALL:
		return
	if timer[idx(c)] <= 0.0 and not chained:
		under[idx(c)] = f(c)
	set_f(c, v, life)
	timer[idx(c)] = seconds


## A lasting feature: any passing state on the cell ends.
func set_lasting(c: Vector2i, v: int) -> void:
	if inside(c):
		timer[idx(c)] = 0.0
		set_f(c, v)


## Ticks passing states; returns the cells whose state just ran out.
func tick(delta: float) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for i: int in timer.size():
		if timer[i] > 0.0:
			timer[i] -= delta
			if timer[i] <= 0.0:
				out.append(Vector2i(i % cols, i / cols))
	return out


func blocks_shot(p: Vector2) -> bool:
	return SHOT_BLOCK.has(f_at(p))


## Fills `kind` over a cell rectangle [x, y, w, h] (arena data).
func paint(kind: String, rect: Array, life: float) -> void:
	for y: int in range(int(rect[1]), int(rect[1]) + int(rect[3])):
		for x: int in range(int(rect[0]), int(rect[0]) + int(rect[2])):
			set_f(Vector2i(x, y), int(NAMES[kind]), life)
