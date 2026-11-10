class_name Stats
extends RefCounted
## Michael's numbers: base values + level + equipment + passive tree. Recomputed whenever any of those change.
## "*_more" stats are multipliers in percent (keystones).

const BASE: Dictionary = {
	"life": 160.0, "glory": 100.0, "armour": 25.0, "damage": 12.0, "holy_pct": 0.0, "move_pct": 0.0, "attack_pct": 0.0,
	"crit": 5.0, "block": 0.0, "life_regen": 1.0, "glory_regen": 0.0, "life_on_hit": 0.0, "cooldown_pct": 0.0, "dodge_pct": 0.0,
	"might": 0.0, "agility": 0.0, "spirit": 0.0, "damage_pct": 0.0,
}
const ATTRIBUTES: Array[String] = ["might", "agility", "spirit"]
const PER_LEVEL: Dictionary = {"life": 12.0, "glory": 4.0, "damage": 1.5, "armour": 3.0}
const SPEED: float = 92.0

var values: Dictionary = {}


func compute(level: int, equipped: Array, passive_stats: Array) -> void:
	values = BASE.duplicate()
	var more: Dictionary = {}
	for k: String in PER_LEVEL:
		values[k] += PER_LEVEL[k] * float(level - 1)
	for sources: Array in [equipped, passive_stats]:
		for st: Dictionary in sources:
			for k: String in st:
				if k.ends_with("_more"):
					more[k] = float(more.get(k, 0.0)) + float(st[k])
				else:
					values[k] = float(values.get(k, 0.0)) + float(st[k])
	var attr: Dictionary = GameData.skills["attributes"]
	for a: String in ATTRIBUTES:                          # each attribute point (allocated or from items) adds its stats
		for k: String in attr[a]["per_point"]:
			values[k] = float(values.get(k, 0.0)) + float(attr[a]["per_point"][k]) * float(values[a])
	for k: String in more:
		var stat: String = k.trim_suffix("_more")
		values[stat] = float(values.get(stat, 0.0)) * (1.0 + float(more[k]) / 100.0)
	values["block"] = minf(values["block"], 60.0)


func v(stat: String) -> float:
	return float(values.get(stat, 0.0))


func move_speed() -> float:
	return SPEED * (1.0 + v("move_pct") / 100.0)


func cooldown(base: float) -> float:
	return base / (1.0 + v("cooldown_pct") / 100.0)


## A hit's damage before the enemy: weapon damage x skill multiplier x holy %, maybe critical.
func roll_damage(mult: float) -> Vector2:
	var d: float = v("damage") * mult * (1.0 + (v("holy_pct") + v("damage_pct")) / 100.0) * randf_range(0.85, 1.15)
	var crit: bool = randf() * 100.0 < v("crit")
	return Vector2(d * (1.75 if crit else 1.0), 1.0 if crit else 0.0)


## Damage Michael takes after armour (and the Shield of Faith reduction, applied by the caller).
func mitigate(raw: float) -> float:
	return raw * 100.0 / (100.0 + v("armour"))
