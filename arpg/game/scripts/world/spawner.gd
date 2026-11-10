class_name Spawner
extends Node
## Packs of demons placed by the zone data (mixed kinds, sometimes a champion pack with modifiers), respawning for
## grinding; prayer waves, summons and the hero. Respawns, waves and summons arrive as smoke (SmokeArrival).
## Every slain demon gives experience and may leave an item, dropped onto open ground (LootDrop).

signal demon_slain(d: Demon)

const SUMMON_CAP: int = 5
const SUMMON_RADIUS: float = 220.0

var world: Node2D
var michael: Michael
var _packs: Array[Dictionary] = []      # {data, alive: Array[Demon], timer}


func setup(into_world: Node2D, m: Michael) -> void:
	world = into_world
	michael = m
	for p: Dictionary in GameData.zone["packs"]:
		var pack := {"data": p, "alive": [], "timer": 0.0}
		_packs.append(pack)
		_spawn_pack(pack, false)


func area_level() -> int:
	return maxi(1, michael.prog.level)


func _spawn_pack(pack: Dictionary, smoke: bool) -> void:
	var p: Dictionary = pack["data"]
	var ch: Dictionary = GameData.enemies["champion"]
	var champs: int = int(ch["members"]) if randf() < float(ch["chance"]) else 0
	var mods: Array = []
	if champs > 0:
		var pool: Array = ch["mods"].keys()
		pool.shuffle()
		mods = pool.slice(0, randi_range(1, 2))
	var kinds: Array = p["kinds"]
	for i: int in kinds.size():
		var d := spawn(kinds[i], SceneData.vec(p["at"]) + _offset(i), "champion" if i < champs else "",
			mods if i < champs else [], smoke, i * 0.12)
		pack["alive"].append(d)


func spawn(kind: String, at: Vector2, rank: String = "", mods: Array = [], smoke: bool = false, delay: float = 0.0) -> Demon:
	var d := Demon.make(kind, at, area_level(), rank, michael, mods)
	world.add_child(d)
	d.slain.connect(_on_slain)
	d.summon.connect(_on_summon)
	if smoke:
		SmokeArrival.arrive(world, d, delay)
	return d


func spawn_hero(at: Vector2) -> Demon:
	return spawn(String(GameData.enemies["hero"]["kind"]), at, "hero", [], true, 0.6)


func spawn_wave(kinds: Array, around: Vector2, radius: float) -> Array[Demon]:
	var out: Array[Demon] = []
	for i: int in kinds.size():
		var a: float = TAU * float(i) / float(kinds.size()) + randf() * 0.4
		out.append(spawn(kinds[i], around + Vector2(cos(a), sin(a) * 0.6) * radius, "", [], true, i * 0.15))
	return out


static func _offset(i: int) -> Vector2:
	return Vector2(cos(i * 2.4) * (18.0 + 12.0 * i), sin(i * 2.4) * (12.0 + 8.0 * i))


func _on_summon(kind: String, at: Vector2, count: int) -> void:
	var near: int = 0
	for n: Node in get_tree().get_nodes_in_group("demons"):
		if (n as Demon).kind == kind and (n as Demon).global_position.distance_to(at) < SUMMON_RADIUS:
			near += 1
	for i: int in mini(count, SUMMON_CAP - near):
		spawn(kind, at + Vector2(randf_range(-50, 50), randf_range(-30, 30)), "", [], true, i * 0.2)


func _on_slain(d: Demon) -> void:
	michael.prog.add_xp(d.xp_value())
	var item: Dictionary = LootGen.maybe_drop(area_level(), d.loot_quality())
	if not item.is_empty():
		LootDrop.drop(world, d.global_position, [item])
		if item["rarity"] in ["rare", "unique"]:
			Audio.sfx("rare_drop", -6.0)
	demon_slain.emit(d)


func _process(delta: float) -> void:
	var min_dist: float = float(GameData.zone["respawn_min_distance"])
	for pack: Dictionary in _packs:
		var alive: Array = pack["alive"].filter(func(x: Variant) -> bool: return is_instance_valid(x) and not (x as Demon).dead)
		pack["alive"] = alive
		if not alive.is_empty():
			continue
		pack["timer"] = float(pack["timer"]) + delta
		var at: Vector2 = SceneData.vec(pack["data"]["at"])
		if float(pack["timer"]) > float(GameData.zone["respawn_seconds"]) and michael.global_position.distance_to(at) > min_dist:
			pack["timer"] = 0.0
			_spawn_pack(pack, true)
