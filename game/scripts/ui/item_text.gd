class_name ItemText
extends RefCounted
## Tooltip rows for an item: name, rarity and slot, item level and requirement, staff damage, implicit, affixes
## with their tier, unique power, set bonus, lore, and (for a bag item) the difference against what is worn.

const IMPLICIT := Color("c9b98f")
const AFFIX := Color("9fc4ff")
const UNIQUE := Color("f07a24")
const SET := Color("8fdc6a")
const LORE := Color("8a86ad")


## What wearing `it` instead would do to your real numbers (DPS, life, defences...), for a bag item's tooltip.
static func effect_rows(p: Player, it: Dictionary) -> Array:
	var slot: String = p.inv.target_slot(it)
	var now: Dictionary = Derived.of(p.stats, p)
	var then: Array = Derived.changes(now, Derived.of(Derived.with_item(p, slot, it), p))
	if then.is_empty():
		return []
	return [["If you wear it:", UiDraw.DIM]] + then


## Implicit and affix lines with the same stat merged into one line (summed; the highest tier shown), so no stat is
## ever listed twice.
static func _stat_rows(it: Dictionary) -> Array:
	var total: Dictionary = {}                     # stat -> [value, highest tier (0: implicit only)]
	for k: String in it.get("implicit", {}):
		total[k] = [float(it["implicit"][k]), 0]
	for a: Dictionary in it.get("affixes", []):
		var k: String = String(a["stat"])
		var had: Array = total.get(k, [0.0, 0])
		total[k] = [float(had[0]) + float(a["value"]), maxi(int(had[1]), int(a["tier"]))]
	var out: Array = []
	for k: String in total:
		var line: String = GameData.stat_line(k, float(total[k][0]))
		var tier: int = int(total[k][1])
		out.append([line, IMPLICIT] if tier == 0 else ["%s   T%d" % [line, tier], AFFIX])
	return out


static func rows(it: Dictionary, worn: Dictionary = {}, level: int = 99) -> Array:
	var out: Array = [String(it["name"])]
	var rarity: String = String(GameData.items["rarity_names"][it["rarity"]])
	out.append(["%s %s" % [rarity, GameData.items["slot_names"].get(it["slot"], String(it["slot"]).capitalize()) if it["slot"] != "ring" else "Ring"], UiDraw.DIM])
	var req_col: Color = UiDraw.TEXT if int(it.get("req", 1)) <= level else UiDraw.DOWN
	out.append(["Item level %d   Requires level %d" % [int(it["ilvl"]), int(it.get("req", 1))], req_col])
	if it.has("dmg"):
		out.append(["Staff damage %d-%d" % [int(it["dmg"][0]), int(it["dmg"][1])], UiDraw.TEXT])
	out.append_array(_stat_rows(it))
	for k: String in it.get("fixed", {}):
		out.append([GameData.stat_line(k, float(it["fixed"][k])), UNIQUE if it["rarity"] == "unique" else SET])
	if String(it.get("special_text", "")) != "":
		out.append([String(it["special_text"]), UNIQUE])
	if it.has("set"):
		out.append([String(GameData.items["sets"][it["set"]]["bonus_text"]), SET])
	if String(it.get("lore", "")) != "":
		out.append(["\"%s\"" % it["lore"], LORE])
	if not worn.is_empty():
		out.append_array(_compare(it, worn))
	return out


static func _compare(it: Dictionary, worn: Dictionary) -> Array:
	var a: Dictionary = LootGen.item_stats(it)
	var b: Dictionary = LootGen.item_stats(worn)
	var keys: Array = a.keys()
	for k: String in b:
		if not keys.has(k):
			keys.append(k)
	var out: Array = [["Against what you wear:", UiDraw.DIM]]
	if it.has("dmg") and worn.has("dmg"):
		var d: float = (float(it["dmg"][0]) + float(it["dmg"][1]) - float(worn["dmg"][0]) - float(worn["dmg"][1])) * 0.5
		if absf(d) > 0.01:
			out.append(["%+.1f average staff damage" % d, UiDraw.UP if d > 0.0 else UiDraw.DOWN])
	for k: String in keys:
		var d: float = float(a.get(k, 0.0)) - float(b.get(k, 0.0))
		if absf(d) > 0.01:
			out.append([GameData.stat_line(k, d), UiDraw.UP if d > 0.0 else UiDraw.DOWN])
	return out
