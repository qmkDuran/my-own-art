class_name LootGen
extends RefCounted
## Item generation. An item is a Dictionary: {slot, base, name, rarity, ilvl, icon, stats: {stat: value}, lines: [text]}.

const DROP_CHANCE: float = 0.32
const PREFIX_SUFFIX_SPLIT: float = 0.5


## Maybe an item for a slain enemy; `quality` > 1 favours better rarities (elites, the prayer reward).
static func maybe_drop(ilvl: int, quality: float = 1.0) -> Dictionary:
	if randf() > DROP_CHANCE * quality:
		return {}
	return make(ilvl, quality)


static func make(ilvl: int, quality: float = 1.0, force_rarity: String = "") -> Dictionary:
	var data: Dictionary = GameData.items
	var rarity: String = force_rarity if force_rarity != "" else _roll_rarity(quality)
	if rarity == "unique":
		return _unique(ilvl)
	var slot: String = data["slots"].keys().pick_random()
	var base: Dictionary = data["slots"][slot]
	var item := {"slot": slot, "base": base["name"], "rarity": rarity, "ilvl": ilvl, "stats": {},
		"icon": Vector2i(randi() % 8, int(base["icon_row"]))}
	for stat: String in base["implicit"]:
		_add(item, stat, _value(base["implicit"][stat], ilvl))
	var n_affix: int = randi_range(int(data["rarities"][rarity]["affixes"][0]), int(data["rarities"][rarity]["affixes"][1]))
	var prefix: String = ""
	var suffix: String = ""
	var pools: Array = [data["prefixes"].keys(), data["suffixes"].keys()]
	for i: int in n_affix:
		var is_prefix: bool = randf() < PREFIX_SUFFIX_SPLIT
		var pool: Array = pools[0] if is_prefix else pools[1]
		if pool.is_empty():
			continue
		var id: String = pool.pick_random()
		pool.erase(id)
		var aff: Dictionary = data["prefixes" if is_prefix else "suffixes"][id]
		_add(item, aff["stat"], _value(aff["value"], ilvl))
		if is_prefix and prefix == "":
			prefix = aff["name"]
		elif not is_prefix and suffix == "":
			suffix = aff["name"]
	item["name"] = _name(item, prefix, suffix)
	return item


static func _roll_rarity(quality: float) -> String:
	var rar: Dictionary = GameData.items["rarities"]
	var weights: Dictionary = {}
	var total: float = 0.0
	for r: String in rar:
		var w: float = float(rar[r]["weight"]) * (pow(quality, 1.5) if r != "common" else 1.0)
		weights[r] = w
		total += w
	var pick: float = randf() * total
	for r: String in weights:
		pick -= weights[r]
		if pick <= 0.0:
			return r
	return "common"


static func _unique(ilvl: int) -> Dictionary:
	var u: Dictionary = GameData.items["uniques"].pick_random()
	var base: Dictionary = GameData.items["slots"][u["slot"]]
	return {"slot": u["slot"], "base": base["name"], "name": u["name"], "rarity": "unique", "ilvl": ilvl,
		"stats": u["stats"].duplicate(), "icon": Vector2i(int(u["icon"]), int(base["icon_row"]))}


static func _value(spec: Array, ilvl: int) -> float:
	var v: float = float(spec[0]) + float(spec[1]) * float(ilvl)
	return v * randf_range(0.85, 1.15)


static func _add(item: Dictionary, stat: String, value: float) -> void:
	var st: Dictionary = item["stats"]
	st[stat] = float(st.get(stat, 0.0)) + value


static func _name(item: Dictionary, prefix: String, suffix: String) -> String:
	match String(item["rarity"]):
		"magic":
			return ("%s %s %s" % [prefix, item["base"], suffix]).strip_edges()
		"rare":
			var words: Array = GameData.items["rare_words"]
			return "%s %s" % [words[0].pick_random(), words[1].pick_random()]
	return item["base"]


## Tooltip lines: name, base (for rare/unique), each stat in words.
static func describe(item: Dictionary) -> PackedStringArray:
	var out := PackedStringArray([item["name"]])
	if item["rarity"] in ["rare", "unique"]:
		out.append(item["base"])
	var names: Dictionary = GameData.items["stat_names"]
	for stat: String in item["stats"]:
		var fmt: String = names.get(stat, stat + " %d")
		var value: float = float(item["stats"][stat])
		out.append(fmt % (value if "%.1f" in fmt else roundi(value)))
	return out


## A single number to compare items in the same slot (the demo and auto-equip use it).
static func score(item: Dictionary) -> float:
	var s: float = 0.0
	for stat: String in item["stats"]:
		s += float(item["stats"][stat]) * (2.0 if stat in ["damage", "holy_pct"] else 1.0)
	return s
