class_name ZonePacks
extends GenStep
## Enemy packs: spread over open ground away from the arrival and the quiet clearings, mixes harder with distance
## (biome pack table), a few elite packs (a rare leader with magic followers), members never inside props or
## each other.


const ELITE_FROM: float = 0.3
const ELITE_SPACING: float = 30.0


func run() -> void:
	_packs()


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


## Elite packs: past the first third of the zone, and far apart (two elite packs together overwhelm early on).


func _elite_packs(centers: Array[Vector2], far: float, n: int) -> Array[int]:
	var idx: Array[int] = []
	for i: int in centers.size():
		if centers[i].distance_to(z.start) / far > ELITE_FROM:
			idx.append(i)
	_shuffle(idx)
	var out: Array[int] = []
	for i: int in idx:
		if out.size() < n and out.all(func(o: int) -> bool: return centers[o].distance_to(centers[i]) > ELITE_SPACING * z.cell):
			out.append(i)
	return out


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
