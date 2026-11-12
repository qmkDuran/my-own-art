class_name TamerSpawner
extends Node
## Wild creatures on the route: one per patch of tall grass, spread over open ground away from the start and the
## camp (tougher kinds and levels further out, tamer.json "spawn"), a shiny roll each (1 in 4096; F1 spawns one for
## testing), one rare alpha (tamer.json "alpha.route"), and fresh ones when you rest at camp.

const T := ZoneLayout.T
const MEMBER_SPREAD := Vector2(60, 44)
const MEMBER_TRIES: int = 30
const GRASS_TUFTS: int = 22
const GRASS_SPREAD := Vector2(100, 60)
const SEED_OFFSET: int = 31

var g: TamerGame
var packs: Array[Dictionary] = []       ## {pos, progress, row}
var rng := RandomNumberGenerator.new()


func setup(game: TamerGame) -> void:
	g = game
	rng.seed = g.route_layout.seed + SEED_OFFSET
	_place_packs()


func _place_packs() -> void:
	var S: Dictionary = TamerData.rule("spawn")
	var camp: Vector2 = g.camp_point()
	var cand: Array[Vector2i] = []
	var far: float = 1.0
	for y: int in g.route_layout.rows:
		for x: int in g.route_layout.cols:
			var c := Vector2i(x, y)
			if _cell_ok(c, S, camp):
				cand.append(c)
				far = maxf(far, g.route_layout.center_of(c).distance_to(g.route_layout.start))
	for i: int in range(cand.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: Vector2i = cand[i]
		cand[i] = cand[j]
		cand[j] = tmp
	for c: Vector2i in cand:
		if packs.size() >= int(S["packs"]):
			break
		var pos: Vector2 = g.route_layout.center_of(c)
		if packs.any(func(p: Dictionary) -> bool: return (p["pos"] as Vector2).distance_to(pos) < float(S["spacing"]) * g.route_layout.cell):
			continue
		packs.append({"pos": pos, "progress": pos.distance_to(g.route_layout.start) / far})
		_grass(pos)


## A patch of tall grass where the pack roams (decoration: nothing collides with it).
func _grass(center: Vector2) -> void:
	for k: int in GRASS_TUFTS:
		var at: Vector2 = center + Vector2(rng.randf_range(-GRASS_SPREAD.x, GRASS_SPREAD.x), rng.randf_range(-GRASS_SPREAD.y, GRASS_SPREAD.y))
		if not g.route_layout.point_free(at, 4.0):
			continue
		var s: Sprite2D = PropSprite.make("tall_grass", k % 3)
		s.position = at.round()
		s.flip_h = rng.randf() < 0.5
		s.modulate = ZoneView.prop_tint()
		g.route_root.add_child(s)


func _cell_ok(c: Vector2i, S: Dictionary, camp: Vector2) -> bool:
	var z: ZoneLayout = g.route_layout
	if not (z.t(c) == T.MOSS or z.t(c) == T.PATH) or not z.walkable(c):
		return false
	var p: Vector2 = z.center_of(c)
	return p.distance_to(z.start) > float(S["safe_radius"]) * z.cell and p.distance_to(camp) > float(S["camp_clear"]) * z.cell


## Every pack comes (back) to life, except near the trainer (no one pops into being in front of you).
func spawn_all(keep_clear: Vector2 = Vector2.INF) -> void:
	for n: Node in get_tree().get_nodes_in_group(Combatant.SIDE_WILD):
		n.queue_free()
	for i: int in packs.size():
		if keep_clear != Vector2.INF and (packs[i]["pos"] as Vector2).distance_to(keep_clear) < g.view_radius():
			continue
		_spawn_pack(i, i < int(TamerData.rule("alpha.route")))


func _row(progress: float) -> Dictionary:
	var row: Dictionary = {}
	for r: Dictionary in TamerData.rule("spawn.table"):
		if progress >= float(r["from"]):
			row = r
	return row


## Pack `i`; the first ones are alphas (tamer.json "alpha.route"), one creature each.
func _spawn_pack(i: int, alpha: bool = false) -> void:
	var row: Dictionary = _row(float(packs[i]["progress"]))
	var size: Array = row["size"]                          # small packs near the start, bigger deeper in
	var kind: String = _weighted(row["kinds"])             # a pack is one kind: easy to read, easy to plan for
	for k: int in rng.randi_range(int(size[0]), int(size[1])):
		var at: Vector2 = _member_spot(packs[i]["pos"])
		if at != Vector2.INF:
			spawn(kind, at, int(row["level"]), -1, alpha)
		if alpha:
			return


func _member_spot(center: Vector2) -> Vector2:
	for k: int in MEMBER_TRIES:
		var p: Vector2 = center + Vector2(rng.randf_range(-MEMBER_SPREAD.x, MEMBER_SPREAD.x), rng.randf_range(-MEMBER_SPREAD.y, MEMBER_SPREAD.y))
		if g.route_layout.point_free(p, 14.0):
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
	return rng.randf() < float(TamerData.species(kind)["shiny_chance"])


## A wild creature on the route, roaming by its temperament (RouteBrain). Walking into it starts a battle.
func spawn(kind: String, at: Vector2, level: int, shiny: int = -1, alpha: bool = false) -> Creature:
	var rec := CreatureRecord.make(kind, level, true, _shiny_roll(kind) if shiny < 0 else shiny == 1)
	rec.alpha = alpha
	rec.life = rec.max_life()
	var c := Creature.new().setup(rec, Combatant.SIDE_WILD)
	c.position = at
	c.brain = RouteBrain.new(c, at)
	g.route_root.add_child(c)
	CreatureTag.attach(c)
	if rec.shiny:
		Audio.sfx("lamp_lit", -6.0, 1.6)
	return c


## F1 (dev) on the route: a shiny of the showcase species right next to you.
func spawn_shiny_near(at: Vector2) -> Creature:
	var kind: String = String(TamerData.rule("spawn.showcase_shiny"))
	var c: Creature = spawn(kind, g.route_layout.free_spot_near(at + Vector2(140, 0), 14.0), 5, 1)
	g.hud.notice("Dev: a shiny %s appeared" % TamerData.species(kind)["name"])
	return c


## No wild creature right where a rival stands.
func clear_near(at: Vector2, r: float) -> void:
	for n: Node in get_tree().get_nodes_in_group(Combatant.SIDE_WILD):
		if (n as Node2D).global_position.distance_to(at) < r:
			n.queue_free()
