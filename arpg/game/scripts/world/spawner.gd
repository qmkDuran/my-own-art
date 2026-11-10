class_name Spawner
extends Node
## Packs of demons placed by the zone data, with champion packs and respawns for grinding; also spawns waves
## (prayer objective) and the hero demon. Every slain demon gives experience and may leave an item.

signal demon_slain(d: Demon)

var world: Node2D
var michael: Michael
var _packs: Array[Dictionary] = []      # {data, alive: Array[Demon], timer}


func setup(into_world: Node2D, m: Michael) -> void:
	world = into_world
	michael = m
	for p: Dictionary in GameData.zone["packs"]:
		var pack := {"data": p, "alive": [], "timer": 0.0}
		_packs.append(pack)
		_spawn_pack(pack)


func area_level() -> int:
	return maxi(1, michael.prog.level)


func _spawn_pack(pack: Dictionary) -> void:
	var p: Dictionary = pack["data"]
	var champs: int = int(GameData.enemies["champion"]["members"]) if randf() < float(GameData.enemies["champion"]["chance"]) else 0
	var kinds: Array = p["kinds"]
	for i: int in kinds.size():
		var d := spawn(kinds[i], SceneData.vec(p["at"]) + _offset(i), "champion" if i < champs else "")
		pack["alive"].append(d)


func spawn(kind: String, at: Vector2, rank: String = "") -> Demon:
	var d := Demon.make(kind, at, area_level(), rank, michael)
	world.add_child(d)
	d.slain.connect(_on_slain)
	return d


func spawn_hero(at: Vector2) -> Demon:
	return spawn(String(GameData.enemies["hero"]["kind"]), at, "hero")


func spawn_wave(kinds: Array, around: Vector2, radius: float) -> Array[Demon]:
	var out: Array[Demon] = []
	for i: int in kinds.size():
		var a: float = TAU * float(i) / float(kinds.size()) + randf() * 0.4
		out.append(spawn(kinds[i], around + Vector2(cos(a), sin(a) * 0.6) * radius, ""))
	return out


static func _offset(i: int) -> Vector2:
	return Vector2(cos(i * 2.4) * (18.0 + 12.0 * i), sin(i * 2.4) * (12.0 + 8.0 * i))


func _on_slain(d: Demon) -> void:
	michael.prog.add_xp(d.xp_value())
	var item: Dictionary = LootGen.maybe_drop(area_level(), d.loot_quality())
	if not item.is_empty():
		GroundItem.spawn(world, d.global_position + Vector2(randf_range(-10, 10), randf_range(-6, 6)), item)
		if item["rarity"] in ["rare", "unique"]:
			Audio.sfx("rare_drop", -6.0)
	demon_slain.emit(d)


func _process(delta: float) -> void:
	var min_dist: float = float(GameData.zone["respawn_min_distance"])
	for pack: Dictionary in _packs:
		var alive: Array = pack["alive"].filter(func(x: Demon) -> bool: return is_instance_valid(x) and not x.dead)
		pack["alive"] = alive
		if not alive.is_empty():
			continue
		pack["timer"] = float(pack["timer"]) + delta
		var at: Vector2 = SceneData.vec(pack["data"]["at"])
		if float(pack["timer"]) > float(GameData.zone["respawn_seconds"]) and michael.global_position.distance_to(at) > min_dist:
			pack["timer"] = 0.0
			_spawn_pack(pack)
