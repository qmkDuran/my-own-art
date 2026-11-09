class_name ChipStatSheet
extends RefCounted
## Where each stat mod lands on Emberoo, and its numbers as the Link Rod screen shows them:
## the live value and the value with a change, e.g. "Crit chance 10% → 15%", never a vague
## percentage to work out. ChipEffects writes through `change_stat`, so what the screen
## shows and what equipping does are the same sums.
##
## STATS: mod id -> [the player's node, its property, display units per property unit
## (negative when the mod lowers it), the label, the unit after the number]. A number
## shown is property / scale, e.g. crit_chance 0.1 / 0.01 = 10 (%).

const STATS := {
	ChipModTable.JAB_DAMAGE: [MeleeAttack.NODE_NAME, "damage", 1.0, "Jab damage", ""],
	ChipModTable.MAX_HEALTH: [Health.NODE_NAME, "max_health", 1.0, "Max Health", ""],
	ChipModTable.MAX_HEAT: [Heat.NODE_NAME, "max_heat", 1.0, "Max Heat", ""],
	ChipModTable.UPPERCUT_COOLDOWN: [FlameUppercut.NODE_PATH, "", -1.0, "Flame Uppercut cooldown", "s"],
	ChipModTable.CRIT_CHANCE: [CritRoll.NODE_NAME, "crit_chance", 0.01, "Crit chance", "%"],
	ChipModTable.BURN_SECONDS: ["SearingJab", "bonus_burn_seconds", 1.0, "Burn length", "s"],
	ChipModTable.AID_HEAL: [TrainerAid.NODE_NAME, "heal_amount", 1.0, "Aid heal", ""],
	ChipModTable.POISON_RESIST: [StatusEffect.RESISTANCE_NODE, "poison_share", -0.01, "Poison length", "%"],
	ChipModTable.RUN_SPEED: [Movement.NODE_NAME, "top_speed", 1.0, "Run speed", " px/s"],
	ChipModTable.DODGE_COOLDOWN: [Dodge.NODE_NAME, "cooldown", -1.0, "Dodge cooldown", "s"],
}
## Floors, in display units, so stacked chips never break a stat (cooldowns stay above 0).
const FLOORS := {
	ChipModTable.UPPERCUT_COOLDOWN: 0.5, ChipModTable.DODGE_COOLDOWN: 0.1, ChipModTable.POISON_RESIST: 20.0,
}
const ARROW := " → "
## Like the Ember Tree, a speed's unit is written once, after the arrow: "60 → 66 px/s".
const SPEED_UNIT := " px/s"
const NEEDS_SEARING_JAB := " (needs Searing Jab)"
const NEEDS_UPPERCUT := " (needs Flame Uppercut)"

var _player: Node


func _init(player: Node) -> void:
	_player = player


func has_player() -> bool:
	return _player != null and is_instance_valid(_player)


static func is_stat_mod(mod_id: String) -> bool:
	return STATS.has(mod_id)


static func label(mod_id: String) -> String:
	return STATS[mod_id][3]


## The stat a mod changes, as shown now (e.g. 10 for a 10% crit chance).
func value(mod_id: String) -> float:
	var target := _target(mod_id)
	if target == null:
		return 0.0
	match mod_id:
		ChipModTable.UPPERCUT_COOLDOWN:
			return (target as SkillAction).skill.cooldown
		ChipModTable.BURN_SECONDS:
			return (target as SearingJab).current_burn_duration()
	return float(target.get(STATS[mod_id][1])) / absf(STATS[mod_id][2])


## The shown value if the mod's amount changed by `amount` (its own direction: a cut lowers it).
func value_with(mod_id: String, amount: float) -> float:
	var changed := value(mod_id) + signf(STATS[mod_id][2]) * amount
	return maxf(FLOORS[mod_id], changed) if FLOORS.has(mod_id) else changed


## How much of `wanted` lands once the `applied` amount (already in the value) is taken
## out first: all of it, unless a floor stops it. ChipEffects uses it to stay exact.
func landed_amount(mod_id: String, applied: float, wanted: float) -> float:
	var direction: float = signf(STATS[mod_id][2])
	var base := value(mod_id) - direction * applied
	var target := base + direction * wanted
	if FLOORS.has(mod_id):
		target = maxf(FLOORS[mod_id], target)
	return absf(target - base)


## "10% → 15%": the stat now, then with the mod's `amount` added. For a mod already
## working (`is_applied`), the stat without it, then now, so the numbers keep their meaning.
func change_text(mod_id: String, amount: float, is_applied: bool) -> String:
	var before := value_with(mod_id, -amount) if is_applied else value(mod_id)
	var after := value(mod_id) if is_applied else value_with(mod_id, amount)
	return number_text(mod_id, before, STATS[mod_id][4] != SPEED_UNIT) + ARROW + number_text(mod_id, after) + _needs_note(mod_id)


## Changes the player's stat by `amount` display units in the mod's direction (ChipEffects).
func change_stat(mod_id: String, amount: float) -> void:
	var target := _target(mod_id)
	if target == null:
		return
	match mod_id:
		ChipModTable.MAX_HEALTH:
			(target as Health).change_max_health(roundi(amount))
			return
		ChipModTable.UPPERCUT_COOLDOWN:
			var action := target as SkillAction
			action.skill.cooldown -= amount
			return
	var property: String = STATS[mod_id][1]
	var change: float = amount * STATS[mod_id][2]
	var current: Variant = target.get(property)
	target.set(property, current + roundi(change) if current is int else current + change)
	if target is Heat:
		(target as Heat).heat_changed.emit((target as Heat).heat, (target as Heat).max_heat)


## "15%", "0.45s", "64 px/s" (or just "64" without the unit).
static func number_text(mod_id: String, number: float, with_unit: bool = true) -> String:
	return ChipModTable.number_text(snappedf(number, 0.01)) + (STATS[mod_id][4] if with_unit else "")


func _target(mod_id: String) -> Node:
	if not has_player() or not STATS.has(mod_id):
		return null
	return _player.get_node_or_null(STATS[mod_id][0])


## Burn and the uppercut cooldown only matter once their skill is ignited.
func _needs_note(mod_id: String) -> String:
	var target := _target(mod_id)
	if mod_id == ChipModTable.BURN_SECONDS and target != null and not (target as SearingJab).is_unlocked():
		return NEEDS_SEARING_JAB
	if mod_id == ChipModTable.UPPERCUT_COOLDOWN and target != null and not EmberTree.is_skill_unlocked(target.name):
		return NEEDS_UPPERCUT
	return ""
