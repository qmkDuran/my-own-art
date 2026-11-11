class_name LootGen
extends RefCounted
## Rolls items from data/items.json: a base for the slot and level, then by rarity — magic 1-2 affixes, rare 3-4
## (at most 2 prefixes + 2 suffixes), each affix at a tier its item level allows (higher tiers rarer); uniques and
## set pieces have fixed stat ranges. An item is a plain Dictionary (saved as JSON).

const MAX_TIER_WEIGHT: float = 0.45     ## each tier above 1 is this much less likely than the one below
const ICON_VARIANT_BY_RARITY: Dictionary = {"normal": 1, "magic": 3, "rare": 2, "set": 4, "unique": 5}

static var rng := RandomNumberGenerator.new()
static var _uid: int = 0


static func roll_rarity(source: String) -> String:
	var w: Array = GameData.items["drop"]["rarity_weights"][source]
	var order: Array = GameData.items["drop"]["rarity_order"]
	var total: float = 0.0
	for x: Variant in w:
		total += float(x)
	var r: float = rng.randf() * total
	for i: int in w.size():
		r -= float(w[i])
		if r <= 0.0:
			return String(order[i])
	return "normal"


static func make(ilvl: int, rarity: String) -> Dictionary:
	if rarity == "unique":
		var u: Dictionary = _unique(ilvl)
		if not u.is_empty():
			return u
		rarity = "rare"
	if rarity == "set":
		var s: Dictionary = _set_piece()
		if not s.is_empty():
			return s
		rarity = "magic"
	var base: Dictionary = _base(ilvl)
	var it: Dictionary = _from_base(base, ilvl, rarity)
	var n: int = {"normal": 0, "magic": rng.randi_range(1, 2), "rare": rng.randi_range(3, 4)}[rarity]
	_add_affixes(it, n, ilvl)
	it["name"] = _name(it, base)
	return it


static func _base(ilvl: int) -> Dictionary:
	var ok: Array = GameData.items["bases"].filter(func(b: Dictionary) -> bool: return int(b["level"]) <= maxi(ilvl, 1))
	return ok[rng.randi_range(0, ok.size() - 1)]


static func base_by_id(id: String) -> Dictionary:
	for b: Dictionary in GameData.items["bases"]:
		if b["id"] == id:
			return b
	return {}


static func _from_base(base: Dictionary, ilvl: int, rarity: String) -> Dictionary:
	_uid += 1
	var it := {"uid": "%d_%d" % [Time.get_ticks_usec(), _uid], "base": base["id"], "slot": base["slot"], "rarity": rarity,
		"ilvl": ilvl, "req": int(base["level"]), "icon": [_icon_row(String(base["slot"])),
		int(base["icon"]) * int(GameData.sprites["icons"]["variants"]) + int(ICON_VARIANT_BY_RARITY[rarity])],
		"implicit": {}, "affixes": []}
	for k: String in base["implicit"]:
		it["implicit"][k] = _roll(base["implicit"][k])
	if base.has("dmg"):
		it["dmg"] = [int(base["dmg"][0]), int(base["dmg"][1])]
	return it


static func _icon_row(slot: String) -> int:
	return (GameData.sprites["icons"]["item_rows"] as Array).find(slot)


static func _roll(range_pair: Array) -> float:
	var a: float = float(range_pair[0])
	var b: float = float(range_pair[1])
	var v: float = rng.randf_range(a, b)
	return roundf(v) if absf(b - a) >= 2.0 or absf(a - roundf(a)) < 0.01 else snappedf(v, 0.1)


static func _add_affixes(it: Dictionary, n: int, ilvl: int) -> void:
	var counts: Dictionary = {"prefix": 0, "suffix": 0}
	var pool: Array = GameData.items["affixes"].filter(func(a: Dictionary) -> bool: return (a["slots"] as Array).has(it["slot"]))
	for i: int in n:
		var choices: Array = pool.filter(func(a: Dictionary) -> bool:
			return int(counts[a["type"]]) < 2 and not (it["affixes"] as Array).any(func(x: Dictionary) -> bool: return x["id"] == a["id"]))
		if choices.is_empty():
			return
		var a: Dictionary = choices[rng.randi_range(0, choices.size() - 1)]
		var tier: int = _tier(a, ilvl)
		var t: Array = a["tiers"][tier - 1]
		it["affixes"].append({"id": a["id"], "type": a["type"], "stat": a["stat"], "tier": tier, "value": _roll([t[0], t[1]])})
		counts[a["type"]] = int(counts[a["type"]]) + 1


static func _tier(a: Dictionary, ilvl: int) -> int:
	var allowed: int = 1
	for i: int in a["tiers"].size():
		if int(a["tiers"][i][2]) <= ilvl:
			allowed = i + 1
	var tier: int = 1
	while tier < allowed and rng.randf() < MAX_TIER_WEIGHT:
		tier += 1
	return tier


static func _name(it: Dictionary, base: Dictionary) -> String:
	var bname: String = String(base["name"])
	if it["rarity"] == "magic":
		var pre: String = ""
		var suf: String = ""
		for a: Dictionary in it["affixes"]:
			var d: Dictionary = _affix(String(a["id"]))
			if a["type"] == "prefix":
				pre = String(d["name"]) + " "
			else:
				suf = " " + String(d["name"])
		return pre + bname + suf
	if it["rarity"] == "rare":
		var w: Dictionary = GameData.items["rare_words"]
		var first: Array = w["first"]
		var second: Array = w["second"][it["slot"]]
		return "%s %s" % [first[rng.randi_range(0, first.size() - 1)], second[rng.randi_range(0, second.size() - 1)]]
	return bname


static func _affix(id: String) -> Dictionary:
	for a: Dictionary in GameData.items["affixes"]:
		if a["id"] == id:
			return a
	return {}


static func _unique(ilvl: int) -> Dictionary:
	var ok: Array = GameData.items["uniques"].filter(func(u: Dictionary) -> bool: return int(u["level"]) <= maxi(ilvl, 1))
	if ok.is_empty():
		return {}
	return make_unique(String(ok[rng.randi_range(0, ok.size() - 1)]["id"]), ilvl)


static func make_unique(id: String, ilvl: int) -> Dictionary:
	for u: Dictionary in GameData.items["uniques"]:
		if u["id"] != id:
			continue
		var it: Dictionary = _from_base(base_by_id(String(u["base"])), ilvl, "unique")
		it["name"] = u["name"]
		it["unique"] = id
		it["special"] = u["special"]
		it["special_text"] = u["special_text"]
		it["lore"] = u["lore"]
		it["fixed"] = {}
		for k: String in u["stats"]:
			it["fixed"][k] = _roll(u["stats"][k])
		return it
	return {}


static func _set_piece() -> Dictionary:
	var sets: Dictionary = GameData.items["sets"]
	var sid: String = String(sets.keys()[rng.randi_range(0, sets.size() - 1)])
	var pieces: Array = sets[sid]["pieces"]
	var pc: Dictionary = pieces[rng.randi_range(0, pieces.size() - 1)]
	var it: Dictionary = _from_base(base_by_id(String(pc["base"])), 1, "set")
	it["name"] = pc["name"]
	it["set"] = sid
	it["piece"] = pc["id"]
	it["lore"] = sets[sid]["lore"]
	it["fixed"] = {}
	for k: String in pc["stats"]:
		it["fixed"][k] = _roll(pc["stats"][k])
	return it


## All stats an item grants (implicit + affixes + fixed), summed by stat key.
static func item_stats(it: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for k: String in it.get("implicit", {}):
		out[k] = float(out.get(k, 0.0)) + float(it["implicit"][k])
	for a: Dictionary in it.get("affixes", []):
		out[a["stat"]] = float(out.get(a["stat"], 0.0)) + float(a["value"])
	for k: String in it.get("fixed", {}):
		out[k] = float(out.get(k, 0.0)) + float(it["fixed"][k])
	return out


static func affix_tier_range(id: String, tier: int) -> Array:
	var t: Array = _affix(id)["tiers"][tier - 1]
	return [t[0], t[1]]
