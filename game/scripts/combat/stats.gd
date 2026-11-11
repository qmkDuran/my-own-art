class_name Stats
extends RefCounted
## The Lamplighter's numbers, rebuilt whenever level, passives or equipment change: base (player.json) + level +
## passives + mastery bonus + every equipped item's stats + set bonuses. Everything the character sheet shows and
## every formula in combat reads from here, so the sheet is always the truth.

const RES_CAP: float = 75.0
const ARMOUR_CAP: float = 75.0
const ARMOUR_FACTOR: float = 8.0

var total: Dictionary = {}           ## summed stat contributions (see data/stats.json)
var level: int = 1
var staff_dmg: Vector2 = Vector2(2, 4)   ## bare hands if no staff
var specials: Array[String] = []     ## unique item specials in effect


func rebuild(prog: Progression, inv: Inventory) -> void:
	level = prog.level
	total = prog.passive_stats().duplicate()
	specials.clear()
	staff_dmg = Vector2(2, 4)
	for slot: String in inv.equipped:
		var it: Dictionary = inv.equipped[slot]
		if it.is_empty():
			continue
		for k: String in LootGen.item_stats(it):
			_add(k, float(LootGen.item_stats(it)[k]))
		if it.has("dmg"):
			staff_dmg = Vector2(float(it["dmg"][0]), float(it["dmg"][1]))
		if String(it.get("special", "")) != "":
			specials.append(String(it["special"]))
	for k: String in inv.set_bonus_stats():
		_add(k, float(inv.set_bonus_stats()[k]))


func _add(k: String, v: float) -> void:
	total[k] = float(total.get(k, 0.0)) + v


func v(k: String) -> float:
	return float(total.get(k, 0.0))


func has_special(s: String) -> bool:
	return specials.has(s)


func max_life() -> float:
	var p: Dictionary = GameData.player
	return roundf((float(p["life"]) + float(p["life_per_level"]) * (level - 1) + v("life")) * (1.0 + v("life_pct") / 100.0))


func max_oil() -> float:
	var p: Dictionary = GameData.player
	return roundf(float(p["oil"]) + float(p["oil_per_level"]) * (level - 1) + v("oil"))


func oil_regen() -> float:
	return float(GameData.player["oil_regen"]) * (1.0 + v("oil_regen_pct") / 100.0)


func life_regen() -> float:
	return float(GameData.player["life_regen"]) + v("life_regen")


func armour() -> float:
	return roundf((float(GameData.player["armour"]) + v("armour")) * (1.0 + v("armour_pct") / 100.0))


## Fraction of a blunt hit of `dmg` that armour stops.
func armour_reduction(dmg: float) -> float:
	var a: float = armour()
	return minf(ARMOUR_CAP / 100.0, a / (a + ARMOUR_FACTOR * maxf(dmg, 1.0)))


func dusk_res() -> float:
	return minf(RES_CAP, v("dusk_res"))


func move_speed() -> float:
	return float(GameData.player["move_speed"]) * (1.0 + v("move_pct") / 100.0)


func crit_chance() -> float:
	return float(GameData.player["crit_chance"]) + v("crit_chance")


func crit_multi() -> float:
	return float(GameData.player["crit_multi"]) + v("crit_multi")


func attack_speed_mult() -> float:
	return 1.0 + v("attack_speed_pct") / 100.0


func cast_speed_mult() -> float:
	return 1.0 + v("cast_speed_pct") / 100.0


func cooldown_mult() -> float:
	return 1.0 / (1.0 + v("cooldown_pct") / 100.0)


func area_mult() -> float:
	return 1.0 + v("area_pct") / 100.0


func light_radius_mult() -> float:
	return maxf(0.3, 1.0 + v("light_radius_pct") / 100.0)


## Increased damage (additive pool) for a skill of the given kind.
func increased(kind: String) -> float:
	var inc: float = v("damage_pct") + v("sunfire_pct") + float(GameData.player["damage_per_level_pct"]) * (level - 1)
	inc += v("spell_pct") if kind == "spell" else v("melee_pct")
	return 1.0 + inc / 100.0


## The staff's damage range after its own increases, plus added sunfire.
func staff_range() -> Vector2:
	var m: float = 1.0 + v("staff_damage_pct") / 100.0
	return staff_dmg * m + Vector2.ONE * v("added_sunfire")
