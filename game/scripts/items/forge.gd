class_name Forge
extends RefCounted
## The Ember Forge's rules. A craft needs its material, an item that can be forged (not unique or set) with
## Heat left, and something to act on; it spends one material and a random amount of Heat. Kindle can turn a
## normal item magic and a full magic item rare (and names it anew).

const MAX_TIER: int = 5
const RARE_AT: int = 3

static var rng := RandomNumberGenerator.new()


## Why this craft can't be done ("" if it can). `affix` is the chosen affix index (-1: none chosen).
static func block(it: Dictionary, craft: String, affix: int, mats: Dictionary) -> String:
	if it.is_empty():
		return "Place an item on the anvil"
	if ["unique", "set"].has(String(it["rarity"])):
		return "Uniques and set pieces can't be forged"
	if int(mats.get(craft, 0)) <= 0:
		return "No %s" % GameData.crafting["materials"][craft]["name"]
	if int(it.get("heat", 0)) < heat_range(it, craft, affix).x:
		return "Not enough Heat left"
	var n: int = (it["affixes"] as Array).size()
	match craft:
		"kindle":
			if n >= 4:
				return "No room for another affix"
		"temper", "quench":
			if affix < 0 or affix >= n:
				return "Choose an affix"
			if craft == "temper" and int(it["affixes"][affix]["tier"]) >= MAX_TIER:
				return "Already tier %d" % MAX_TIER
		"anneal":
			if n == 0:
				return "No affixes to reroll"
	return ""


## Heat this craft may spend (min, max).
static func heat_range(it: Dictionary, craft: String, affix: int) -> Vector2i:
	var c: Dictionary = GameData.crafting["crafts"][craft]
	var r := Vector2i(int(c["heat"][0]), int(c["heat"][1]))
	if craft == "temper" and affix >= 0 and affix < (it["affixes"] as Array).size():
		r += Vector2i.ONE * int(c["per_tier"]) * (int(it["affixes"][affix]["tier"]) - 1)
	return r


## Does the craft; returns the Heat spent (0 if it could not be done).
static func craft(it: Dictionary, craft_id: String, affix: int, mats: Dictionary) -> int:
	if block(it, craft_id, affix, mats) != "":
		return 0
	var hr: Vector2i = heat_range(it, craft_id, affix)
	var spent: int = rng.randi_range(hr.x, hr.y)
	match craft_id:
		"kindle":
			if not LootGen.add_one(it):
				return 0
			_promote(it)
		"temper":
			var a: Dictionary = it["affixes"][affix]
			a["tier"] = int(a["tier"]) + 1
			LootGen.reroll(a)
		"quench":
			(it["affixes"] as Array).remove_at(affix)
		"anneal":
			for a: Dictionary in it["affixes"]:
				LootGen.reroll(a)
	mats[craft_id] = int(mats[craft_id]) - 1
	it["heat"] = maxi(0, int(it["heat"]) - spent)
	return spent


static func _promote(it: Dictionary) -> void:
	var n: int = (it["affixes"] as Array).size()
	var to: String = "rare" if n >= RARE_AT else "magic"
	if to != String(it["rarity"]) and String(it["rarity"]) != "rare":
		it["rarity"] = to
		it["name"] = LootGen.item_name(it, LootGen.base_by_id(String(it["base"])))
		it["icon"][1] = int(it["icon"][1]) - int(it["icon"][1]) % int(GameData.sprites["icons"]["variants"]) + int(LootGen.ICON_VARIANT_BY_RARITY[to])
