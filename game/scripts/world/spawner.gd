class_name Spawner
extends Node
## Puts the zone's packs, the opening ambush, relight waves and the Glazier into the world; wakes enemies as the
## Lamplighter nears and puts far ones to sleep (they cost nothing then); pays out experience, Light, life/Oil on
## kill and loot when something dies.

signal killed(e: Enemy)
signal boss_died(e: Enemy)

const CHECK_EVERY: float = 0.4
const WAVE_RING: float = 260.0
const AMBUSH_SPREAD: float = 60.0
const ARRIVAL_TRIES: int = 8
const AMBUSH_NEAR: float = 600.0

var world: Node2D
var z: ZoneLayout
var player: Player
var boss: Enemy
var _check: float = 0.0


func setup(w: Node2D, layout: ZoneLayout, p: Player) -> void:
	world = w
	z = layout
	player = p
	for s: Dictionary in z.spawns:
		spawn(String(s["kind"]), s["pos"], String(s["rank"]), s["mods"], level_at(float(s["level_progress"])))


func level_at(progress: float) -> int:
	var r: Array = GameData.zone(GameData.zone_id)["level"]
	return roundi(lerpf(float(r[0]), float(r[1]), clampf(progress, 0.0, 1.0)))


func spawn(kind: String, at: Vector2, rank: String = "normal", mods: Array = [], lvl: int = 1) -> Enemy:
	var e := Enemy.new()
	e.setup(kind, rank, mods, lvl)
	e.position = at
	world.add_child(e)
	e.died.connect(_on_died)
	return e


func spawn_boss() -> Enemy:
	boss = spawn(String(z.boss["kind"]), z.boss["pos"], "boss", [], level_at(1.0))
	return boss


## The gloams that came over the wall: they arrive from the forest's edge east of the gate.
func opening_ambush(a: Dictionary) -> void:
	if player.global_position.distance_to(z.start) > AMBUSH_NEAR:
		return
	var base: Vector2 = player.global_position + Vector2(float(a["offset"][0]), float(a["offset"][1]))
	for k: int in int(a["count"]):
		var at: Vector2 = _free_near(base + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * AMBUSH_SPREAD, 10.0)
		var e: Enemy = spawn(String(a["kind"]), at, "normal", [], 1)
		e.wake()
		Fx.burst(world, at, 10, Vector2(20, 60), 0.6, [Pal.c("violet", 0.8), Pal.c("void", 0.0)], Vector2.UP, 60.0, Vector2(2, 3), false)


## A relight wave: the dark comes for the waylamp from all sides.
func wave(center: Vector2, n: int, kinds: Dictionary, lvl: int) -> void:
	for k: int in n:
		var kind: String = _weighted(kinds)
		var at: Vector2 = _free_near(center + Vector2.RIGHT.rotated(TAU * k / n + randf() * 0.4) * WAVE_RING, 14.0)
		var e: Enemy = spawn(kind, at, "normal", [], lvl)
		e.wake()
		Fx.burst(world, at, 10, Vector2(20, 60), 0.6, [Pal.c("violet", 0.8), Pal.c("void", 0.0)], Vector2.UP, 60.0, Vector2(2, 3), false)


## A free spot near p, also clear of every living enemy (arrivals never land inside one another).
func _free_near(p: Vector2, radius: float) -> Vector2:
	var q: Vector2 = z.free_spot_near(p, radius)
	for k: int in ARRIVAL_TRIES:
		if not _crowded(q, radius):
			return q
		q = z.free_spot_near(q + Vector2.RIGHT.rotated(randf() * TAU) * radius * 3.0, radius)
	return q


func _crowded(p: Vector2, radius: float) -> bool:
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		var e := n as Enemy
		if e.global_position.distance_to(p) < e.radius + radius:
			return true
	return false


func _weighted(t: Dictionary) -> String:
	var roll: float = randf()
	for k: String in t:
		roll -= float(t[k])
		if roll <= 0.0:
			return k
	return String(t.keys()[0])


func _process(delta: float) -> void:
	_check -= delta
	if _check > 0.0:
		return
	_check = CHECK_EVERY
	var E: Dictionary = GameData.enemies
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		var e := n as Enemy
		var d: float = e.global_position.distance_to(player.global_position)
		var far: bool = d > float(E["sleep_range"]) and e != boss
		e.process_mode = Node.PROCESS_MODE_DISABLED if far else Node.PROCESS_MODE_INHERIT
		if d < float(E["wake_range"]):
			e.wake()


func _on_died(e: Enemy) -> void:
	var E: Dictionary = GameData.enemies
	var xp: float = float(e.data["xp"]) * (1.0 + float(E["xp_per_level"]) * (e.level - 1)) * float(E["ranks"][e.rank]["xp"])
	player.prog.add_xp(xp)
	player.light.on_kill(e.rank)
	player.gain_life(player.stats.v("life_on_kill"))
	player.oil = minf(player.stats.max_oil(), player.oil + player.stats.v("oil_on_kill"))
	if randf() < float(GameData.player["tonic"]["kill_refill_chance"]) and player.tonics < player.max_tonics():
		player.tonics += 1
	_drop_loot(e)
	Session.campaign.killed(e.kind)
	killed.emit(e)
	if e == boss:
		boss_died.emit(e)


func _drop_loot(e: Enemy) -> void:
	var D: Dictionary = GameData.items["drop"]
	var source: String = e.rank
	if randf() > float(D["chance"][source]):
		return
	drop_items(e.global_position, int(D["count"][source]), source, e.level)


## Rolls n items and lays the ones the loot filter shows on open ground.
func drop_items(at: Vector2, n: int, source: String, lvl: int) -> void:
	var items: Array = []
	for i: int in n:
		var it: Dictionary = LootGen.make(lvl, LootGen.roll_rarity(source))
		if LootFilter.shows(it):
			items.append(it)
		else:
			LootFilter.hidden_count += 1
	var spots: Array[Vector2] = LootDrop.free_spots(z, at, items.size(), player.global_position)
	for i: int in spots.size():
		GroundItem.spawn(world, spots[i], items[i])
		Audio.sfx("drop_rare" if LootFilter.emphasised(items[i]) else "drop_item", -8.0)
