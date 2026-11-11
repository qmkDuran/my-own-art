class_name BattleRules
extends RefCounted
## Pure battle maths: damage (power, attack against defense, level, element, kinship, timing, a small spread),
## stat stages, turn order and the timing multipliers. No nodes, no waiting: easy to test.

const LEVEL_FACTOR: float = 2.0 / 5.0
const LEVEL_BASE: float = 2.0
const DAMAGE_DIVISOR: float = 22.0
const DAMAGE_FLAT: float = 2.0
const SPREAD_MIN: float = 0.9
const STAGE_STEP: float = 0.25
const STAGE_MIN: int = -2
const STAGE_MAX: int = 3
const ATTACK_TIMING: Dictionary = {"perfect": 1.3, "good": 1.15, "miss": 1.0}
const DEFEND_TIMING: Dictionary = {"perfect": 0.6, "good": 0.8, "miss": 1.0}


static func stage_mult(stage: int) -> float:
	return maxf(0.5, 1.0 + STAGE_STEP * stage)


static func clamp_stage(stage: int) -> int:
	return clampi(stage, STAGE_MIN, STAGE_MAX)


static func element_mult(move_element: String, defender: Creature) -> float:
	return Db.element_mult(move_element, defender.element())


static func kinship(move_element: String, attacker: Creature) -> float:
	return float(Db.elements["kinship_mult"]) if move_element == attacker.element() else 1.0


## Damage of one hit; the timing multiplier combines the attacker's press and the defender's block.
static func damage(attacker: Battler, defender: Battler, move_id: String, timing: float, spread: float) -> int:
	var move: Dictionary = Db.move(move_id)
	var element: String = String(move["element"])
	var atk: float = attacker.creature.stat("atk") * stage_mult(attacker.stage("atk"))
	var def: float = defender.creature.stat("def") * stage_mult(defender.stage("def"))
	var level_term: float = attacker.creature.level * LEVEL_FACTOR + LEVEL_BASE
	var base: float = level_term * float(move["power"]) * atk / def / DAMAGE_DIVISOR + DAMAGE_FLAT
	var mult: float = element_mult(element, defender.creature) * kinship(element, attacker.creature)
	return maxi(1, int(round(base * mult * timing * lerpf(SPREAD_MIN, 1.0, spread))))


static func timing_mult(attack_grade: String, defend_grade: String) -> float:
	return float(ATTACK_TIMING[attack_grade]) * float(DEFEND_TIMING[defend_grade])


## True when the player's creature acts first (ties go to the player).
static func player_first(player: Battler, foe: Battler) -> bool:
	return player.creature.stat("spd") >= foe.creature.stat("spd")


static func heal_amount(c: Creature, move_id: String) -> int:
	return int(ceil(c.max_hp() * float(Db.move(move_id)["amount"])))


static func match_text(mult: float) -> String:
	if mult > 1.0:
		return "A strong match!"
	if mult < 1.0:
		return "A weak match..."
	return ""
