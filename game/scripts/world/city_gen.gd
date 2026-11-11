class_name CityGen
extends GenStep
## Tallow is laid by hand (biome `city`): cobbled streets inside ramparts on every side, a gate in the south
## rampart toward the Glasswood, and buildings, people and services at authored places. Everything still goes
## through the same layout data and checks as a generated zone.

const CITY_RADIUS: float = 100000.0


func run() -> void:
	_terrain()
	_place_all(b["buildings"])
	_place_all(b["objects"])
	var sq: Array = b["square"]
	z.circle = Vector3(float(sq[0]), float(sq[1]), CITY_RADIUS)
	z.start = _vec(b["start"])
	z.clearings.append({"role": "start", "center": z.cell_of(z.start), "r": Vector2.ONE, "secret": false})
	if b.has("yard"):                                     # the practice ground the opening drills on
		z.clearings.append({"role": "yard", "center": z.cell_of(_vec(b["yard"])), "r": Vector2.ONE, "secret": false})


## Cobbles everywhere, ramparts around the edge, the gate opening in the south rampart.
func _terrain() -> void:
	var e: int = int(b["border"])
	var gate: Array = b["gate"]
	for y: int in z.rows:
		for x: int in z.cols:
			var wall: bool = x < e or y < e or x >= z.cols - e or y >= z.rows - e
			var opening: bool = y >= z.rows - e and y < z.rows - 1 and x >= int(gate[0]) and x < int(gate[0]) + int(gate[1])
			z.set_t(Vector2i(x, y), T.WALL if wall and not opening else T.STONE)


func _place_all(list: Array) -> void:
	for sp: Dictionary in list:
		var prop: Dictionary = sp.duplicate()
		prop["pos"] = _vec(sp["at"])
		prop["foot"] = ZoneLayout.footprint(String(sp["kind"]), prop["pos"]) if String(sp["kind"]) != "exit" else Rect2(prop["pos"], Vector2.ZERO)
		prop["clearing"] = -1
		z.props.append(prop)
	for i: int in z.terrain.size():
		z.blocked[i] = 0 if ZoneLayout.WALKABLE.has(int(z.terrain[i])) else 1
	for p: Dictionary in z.props:
		for c: Vector2i in z.cells_under((p["foot"] as Rect2).grow(-2.0)):
			if (p["foot"] as Rect2).size.x > 0.0 and z.inside(c):
				z.blocked[z.idx(c)] = 1
