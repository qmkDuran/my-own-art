class_name ItemText
extends RefCounted
## Tooltip rows for an item: name, rarity and slot, item level and requirement, staff damage, implicit, affixes
## with their tier, unique power, set bonus, lore, and (for a bag item) the difference against what is worn.

const IMPLICIT := Color("c9b98f")
const AFFIX := Color("9fc4ff")
const UNIQUE := Color("f07a24")
const SET := Color("8fdc6a")
const LORE := Color("8a86ad")


static func rows(it: Dictionary, worn: Dictionary = {}, level: int = 99) -> Array:
	var out: Array = [String(it["name"])]
	var rarity: String = String(GameData.items["rarity_names"][it["rarity"]])
	out.append(["%s %s" % [rarity, GameData.items["slot_names"].get(it["slot"], String(it["slot"]).capitalize()) if it["slot"] != "ring" else "Ring"], UiDraw.DIM])
	var req_col: Color = UiDraw.TEXT if int(it.get("req", 1)) <= level else UiDraw.DOWN
	out.append(["Item level %d   Requires level %d" % [int(it["ilvl"]), int(it.get("req", 1))], req_col])
	if it.has("dmg"):
		out.append(["Staff damage %d-%d" % [int(it["dmg"][0]), int(it["dmg"][1])], UiDraw.TEXT])
	for k: String in it.get("implicit", {}):
		out.append([GameData.stat_line(k, float(it["implicit"][k])), IMPLICIT])
	for a: Dictionary in it.get("affixes", []):
		out.append(["%s   T%d" % [GameData.stat_line(String(a["stat"]), float(a["value"])), int(a["tier"])], AFFIX])
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
	var out: Array = [["Instead of %s:" % worn["name"], UiDraw.DIM]]
	if it.has("dmg") and worn.has("dmg"):
		var d: float = (float(it["dmg"][0]) + float(it["dmg"][1]) - float(worn["dmg"][0]) - float(worn["dmg"][1])) * 0.5
		if absf(d) > 0.01:
			out.append(["%+.1f average staff damage" % d, UiDraw.UP if d > 0.0 else UiDraw.DOWN])
	for k: String in keys:
		var d: float = float(a.get(k, 0.0)) - float(b.get(k, 0.0))
		if absf(d) > 0.01:
			out.append([GameData.stat_line(k, d), UiDraw.UP if d > 0.0 else UiDraw.DOWN])
	return out
