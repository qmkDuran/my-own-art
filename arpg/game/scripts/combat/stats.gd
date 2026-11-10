class_name Stats
extends RefCounted
## Michael's numbers: base values + level + equipment + masteries, attributes and stars. Recomputed whenever any of
## those change. "*_more" stats are multipliers in percent. Every value here is used by the game (the character sheet
## shows them and the smoke test recomputes them). Damage types: physical (blows), fire, shadow (bolts).

const BASE: Dictionary = {
	"life": 160.0, "glory": 100.0, "armour": 25.0, "damage": 12.0, "holy_pct": 0.0, "move_pct": 0.0, "attack_pct": 0.0,
	"crit": 5.0, "block": 0.0, "life_regen": 1.0, "glory_regen": 0.0, "life_on_hit": 0.0, "cooldown_pct": 0.0, "dodge_pct": 0.0,
	"might": 0.0, "agility": 0.0, "spirit": 0.0, "damage_pct": 0.0,
	"crit_damage": 75.0, "cast_pct": 0.0, "block_amount": 10.0, "fire_res": 0.0, "shadow_res": 0.0,
}
const ROLL_LOW: float = 0.85
const ROLL_HIGH: float = 1.15
const RES_CAP: float = 75.0
const CAST_TIME: float = 0.22             # Michael stands for this long after using a skill (cast speed shortens it)
const SWING_FRAMES: float = 9.0
const SWING_FPS: float = 24.0
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
	values["fire_res"] = minf(values["fire_res"], RES_CAP)
	values["shadow_res"] = minf(values["shadow_res"], RES_CAP)


func v(stat: String) -> float:
	return float(values.get(stat, 0.0))


func move_speed() -> float:
	return SPEED * (1.0 + v("move_pct") / 100.0)


func cooldown(base: float) -> float:
	return base / (1.0 + v("cooldown_pct") / 100.0)


## Weapon damage range of one hit at multiplier 1 (before a critical).
func damage_range(mult: float = 1.0) -> Vector2:
	var d: float = v("damage") * mult * (1.0 + (v("holy_pct") + v("damage_pct")) / 100.0)
	return Vector2(d * ROLL_LOW, d * ROLL_HIGH)


## A hit's damage before the enemy: weapon damage x skill multiplier x damage %, maybe critical.
func roll_damage(mult: float) -> Vector2:
	var r: Vector2 = damage_range(mult)
	var d: float = randf_range(r.x, r.y)
	var crit: bool = randf() * 100.0 < v("crit")
	return Vector2(d * (1.0 + v("crit_damage") / 100.0) if crit else d, 1.0 if crit else 0.0)


func swings_per_second() -> float:
	return SWING_FPS * (1.0 + v("attack_pct") / 100.0) / SWING_FRAMES


func cast_time() -> float:
	return CAST_TIME / (1.0 + v("cast_pct") / 100.0)


## Share of physical damage armour removes.
func armour_reduction() -> float:
	return v("armour") / (100.0 + v("armour"))


## Damage Michael takes of a type: armour against blows, resistances against fire and shadow.
func mitigate(raw: float, kind: String = "physical") -> float:
	match kind:
		"fire": return raw * (1.0 - v("fire_res") / 100.0)
		"shadow": return raw * (1.0 - v("shadow_res") / 100.0)
	return raw * (1.0 - armour_reduction())
