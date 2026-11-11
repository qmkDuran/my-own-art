class_name TamerSpawner
extends Node
## Wild creatures: packs spread over open ground away from the meadow start and the camp (tougher kinds and levels
## further out, tamer.json "spawn"), a shiny roll per creature (one shiny of the named species is guaranteed in the
## prototype every time the packs return, so it can be seen), material drops when one faints, and fresh packs when you rest at camp.

signal defeated(c: Creature)

const T := ZoneLayout.T
const MEMBER_SPREAD := Vector2(60, 44)
const MEMBER_TRIES: int = 30
const SEED_OFFSET: int = 31

var g: TamerGame
var packs: Array[Dictionary] = []       ## {pos, progress, row}
var rng := RandomNumberGenerator.new()
var _shiny_given: bool = false


func setup(game: TamerGame) -> void:
	g = game
	rng.seed = g.layout.seed + SEED_OFFSET
	_place_packs()


func _place_packs() -> void:
	var S: Dictionary = TamerData.rule("spawn")
	var camp: Vector2 = g.camp_point()
	var cand: Array[Vector2i] = []
	var far: float = 1.0
	for y: int in g.layout.rows:
		for x: int in g.layout.cols:
			var c := Vector2i(x, y)
			if _cell_ok(c, S, camp):
				cand.append(c)
				far = maxf(far, g.layout.center_of(c).distance_to(g.layout.start))
	for i: int in range(cand.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: Vector2i = cand[i]
		cand[i] = cand[j]
		cand[j] = tmp
	for c: Vector2i in cand:
		if packs.size() >= int(S["packs"]):
			break
		var pos: Vector2 = g.layout.center_of(c)
		if packs.any(func(p: Dictionary) -> bool: return (p["pos"] as Vector2).distance_to(pos) < float(S["spacing"]) * g.layout.cell):
			continue
		packs.append({"pos": pos, "progress": pos.distance_to(g.layout.start) / far})


func _cell_ok(c: Vector2i, S: Dictionary, camp: Vector2) -> bool:
	var z: ZoneLayout = g.layout
	if not (z.t(c) == T.MOSS or z.t(c) == T.PATH) or not z.walkable(c):
		return false
	var p: Vector2 = z.center_of(c)
	return p.distance_to(z.start) > float(S["safe_radius"]) * z.cell and p.distance_to(camp) > float(S["camp_clear"]) * z.cell


## Every pack comes (back) to life, except near the trainer (no one pops into being in front of you).
func spawn_all(keep_clear: Vector2 = Vector2.INF) -> void:
	for n: Node in get_tree().get_nodes_in_group(Combatant.SIDE_WILD):
		n.queue_free()
	_shiny_given = false
	for i: int in packs.size():
		if keep_clear != Vector2.INF and (packs[i]["pos"] as Vector2).distance_to(keep_clear) < g.view_radius():
			continue
		_spawn_pack(i)


func _row(progress: float) -> Dictionary:
	var row: Dictionary = {}
	for r: Dictionary in TamerData.rule("spawn.table"):
		if progress >= float(r["from"]):
			row = r
	return row


func _spawn_pack(i: int) -> void:
	var row: Dictionary = _row(float(packs[i]["progress"]))
	var size: Array = TamerData.rule("spawn.size")
	var kind: String = _weighted(row["kinds"])             # a pack is one kind: easy to read, easy to plan for
	for k: int in rng.randi_range(int(size[0]), int(size[1])):
		var at: Vector2 = _member_spot(packs[i]["pos"])
		if at != Vector2.INF:
			spawn(kind, at, int(row["level"]), i)


func _member_spot(center: Vector2) -> Vector2:
	for k: int in MEMBER_TRIES:
		var p: Vector2 = center + Vector2(rng.randf_range(-MEMBER_SPREAD.x, MEMBER_SPREAD.x), rng.randf_range(-MEMBER_SPREAD.y, MEMBER_SPREAD.y))
		if g.layout.point_free(p, 14.0):
			return p.round()
	return Vector2.INF


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


func _shiny_roll(kind: String) -> bool:
	if not _shiny_given and kind == String(TamerData.rule("spawn.guarantee_shiny")):
		_shiny_given = true
		return true
	return rng.randf() < float(TamerData.species(kind)["shiny_chance"])


func spawn(kind: String, at: Vector2, level: int, pack: int = -1, shiny: int = -1) -> Creature:
	var rec := CreatureRecord.make(kind, level, true, _shiny_roll(kind) if shiny < 0 else shiny == 1)
	var c := Creature.new().setup(rec, Combatant.SIDE_WILD)
	c.position = at
	var brain := WildBrain.new(c)
	brain.home = at
	brain.pack = pack
	c.brain = brain
	c.struck.connect(func(cr: Creature, by: Combatant) -> void:
		if cr.brain is WildBrain:
			(cr.brain as WildBrain).wake(by))
	c.fainted.connect(_on_fainted)
	g.world.add_child(c)
	CreatureTag.attach(c)
	if rec.shiny:
		Audio.sfx("lamp_lit", -6.0, 1.6)
	return c


func _on_fainted(c: Creature) -> void:
	var D: Dictionary = TamerData.rule("drops")
	if rng.randf() < float(D["chance"]):
		var n: int = rng.randi_range(int(D["count"][0]), int(D["count"][1]))
		MaterialPickup.drop(g, c.global_position, String(c.rec.data()["material"]), n)
	defeated.emit(c)
