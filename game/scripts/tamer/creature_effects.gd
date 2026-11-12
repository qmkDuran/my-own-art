class_name CreatureEffects
extends RefCounted
## Buffs and debuffs on a creature (data/tamer/effects.json), each with its cost built in: speed, damage dealt and
## taken, no dodging, hidden. Strength (0..1, how long the status move was channelled) scales them. Buffs drain
## faster when the creature is hit; debuffs just run out. An effect can leave another behind (Sprint -> Lethargy).

var list: Dictionary = {}               ## effect id -> {"t": seconds left, "max": its full time, "s": strength}


static func data(id: String) -> Dictionary:
	return TamerData.effects["effects"][id]


func add(id: String, strength: float) -> void:
	var d: Dictionary = data(id)
	var time: float = float(d["time"]) + float(d.get("time_extra", 0.0)) * strength
	list[id] = {"t": time, "max": time, "s": clampf(strength, 0.0, 1.0)}


func has(id: String) -> bool:
	return list.has(id)


func remove(id: String) -> void:
	list.erase(id)


## The product of an effect value over every active effect: 1 + value x strength (or a flat multiplier).
func mult(key: String) -> float:
	var k: float = 1.0
	for id: String in list:
		var d: Dictionary = data(id)
		if d.has(key):
			k *= 1.0 + float(d[key]) * float(list[id]["s"])
		if d.has(key + "_flat"):
			k *= float(d[key + "_flat"])
	return k


func flag(key: String) -> bool:
	for id: String in list:
		if bool(data(id).get(key, false)):
			return true
	return false


## A hit taken: buffs lose time; the first hit while Hidden is a critical (and ends it).
func on_hit() -> float:
	var crit: float = 1.0
	for id: String in list.keys():
		var d: Dictionary = data(id)
		if bool(d.get("crit_first", false)):
			crit = 1.5
			remove(id)
		elif String(d["kind"]) == "buff":
			list[id]["t"] = float(list[id]["t"]) - float(TamerData.effects["hit_drain"])
	return crit


func tick(delta: float) -> void:
	for id: String in list.keys():
		list[id]["t"] = float(list[id]["t"]) - delta
		if float(list[id]["t"]) <= 0.0:
			var then: String = String(data(id).get("then", ""))
			list.erase(id)
			if then != "":
				add(then, 1.0)
