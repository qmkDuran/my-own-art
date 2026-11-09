class_name EmberTreeStatSheet
extends RefCounted
## Emberoo's stats as the Ember Tree screen shows them, read live from the player's
## components, and what a stat node changes: exact numbers, never "+X%" to work out.
##
## Reads the components after EmberTreeEffects has changed them, so every value already
## counts the nodes learned so far. `value_with` mirrors how EmberTreeEffects applies each
## change; keep the two in step when adding a stat.

## The stats, in the order the stats panel lists them.
const LEVEL := "level"
## Emberoo's Awakening stage and the flat bonus it gives (see AwakeningBoost): "I (+3 health,
## +1 jab)", or NOT_LEARNED before the first. The bonus is already in Max Health and Jab damage.
const AWAKENING := "awakening"
const HEALTH := "health"
const JAB_DAMAGE := "jab_damage"
const JAB_TIME := "jab_time"
const RUN_SPEED := "run_speed"
const DODGE_COOLDOWN := "dodge_cooldown"
const MAX_HEAT := "max_heat"
## Critical hits (see CritRoll): shown so the numbers are clear; no tree node changes them yet.
const CRIT_CHANCE := "crit_chance"
const CRIT_DAMAGE := "crit_damage"
## Burn from Searing Jab (see SearingJab), lengthened by Kindling: "1/s for 3s", or
## NOT_LEARNED before Searing Jab is ignited. Its value is the burn's length in seconds.
const BURN := "burn"
## Ash Guard (see AshGuard): "50% for 1.2s", or NOT_LEARNED. Its value is the guard's length.
const GUARD := "guard"
## How far enemy shoves push, in percent: 100%, or less with Unshakable (see Unshakable).
const SHOVES := "shoves"
const ORDER: Array[String] = [
	LEVEL, AWAKENING, HEALTH, JAB_DAMAGE, BURN, JAB_TIME, RUN_SPEED, DODGE_COOLDOWN, MAX_HEAT, CRIT_CHANCE, CRIT_DAMAGE,
	GUARD, SHOVES,
]

const LABELS := {
	LEVEL: "Level", AWAKENING: "Awakening", HEALTH: "Max Health", JAB_DAMAGE: "Jab damage", JAB_TIME: "Time between jabs",
	RUN_SPEED: "Run speed", DODGE_COOLDOWN: "Dodge cooldown", MAX_HEAT: "Max Heat",
	CRIT_CHANCE: "Crit chance", CRIT_DAMAGE: "Crit damage", BURN: "Burn", GUARD: "Guard",
	SHOVES: "Shoves taken",
}
## Which stat each Ember Tree effect (EmberTreeEffects, the "stats" of a node) changes.
const STAT_FOR_EFFECT := {
	EmberTreeEffects.MAX_HEALTH: HEALTH, EmberTreeEffects.JAB_DAMAGE: JAB_DAMAGE,
	EmberTreeEffects.JAB_RECOVERY_CUT: JAB_TIME, EmberTreeEffects.MOVE_SPEED: RUN_SPEED,
	EmberTreeEffects.DODGE_COOLDOWN_CUT: DODGE_COOLDOWN, EmberTreeEffects.MAX_HEAT: MAX_HEAT,
}
const SECONDS_STATS: Array[String] = [JAB_TIME, DODGE_COOLDOWN]
const SPEED_UNIT := " px/s"
const PERCENT_SIGN := "%"
const TIMES_SIGN := "×"
const ARROW := " → "
const NOT_LEARNED := "—"
## The player's node with the burn's numbers.
const SEARING_JAB := "SearingJab"
## The player's nodes with the guard's and the shoves' numbers.
const ASH_GUARD := AshGuard.NODE_PATH
const UNSHAKABLE := "Unshakable"

var _player: Node


## `player` is the player creature (see PlayerFinder); null gives an empty sheet.
func _init(player: Node) -> void:
	_player = player


## False while there is no player to read (e.g. it is respawning).
func has_player() -> bool:
	return _player != null and is_instance_valid(_player)


func value(stat: String) -> float:
	return value_with(stat, 0.0)


## The stat's value if an Ember Tree effect added `effect_amount` more (negative = less).
## Cuts (jab recovery, dodge cooldown) lower the value, exactly as EmberTreeEffects does.
func value_with(stat: String, effect_amount: float) -> float:
	match stat:
		LEVEL:
			return Progression.level
		AWAKENING:
			return Awakening.stage
		HEALTH:
			return Health.of(_player).max_health + effect_amount
		JAB_DAMAGE:
			return (_player.get_node(MeleeAttack.NODE_NAME) as MeleeAttack).damage + effect_amount
		JAB_TIME:
			var melee: MeleeAttack = _player.get_node(MeleeAttack.NODE_NAME)
			return maxf(melee.hit_delay, melee.attack_duration - melee.recovery_cut - effect_amount)
		RUN_SPEED:
			return (_player.get_node(Movement.NODE_NAME) as Movement).top_speed + effect_amount
		DODGE_COOLDOWN:
			return maxf(0.0, (_player.get_node(Dodge.NODE_NAME) as Dodge).cooldown - effect_amount)
		MAX_HEAT:
			return (_player.get_node(Heat.NODE_NAME) as Heat).max_heat + effect_amount
		CRIT_CHANCE:
			return (_player.get_node(CritRoll.NODE_NAME) as CritRoll).crit_chance * 100.0 + effect_amount
		CRIT_DAMAGE:
			return (_player.get_node(CritRoll.NODE_NAME) as CritRoll).crit_multiplier + effect_amount
		BURN:
			var searing_jab := _learned_searing_jab()
			return searing_jab.current_burn_duration() + effect_amount if searing_jab != null else 0.0
		GUARD:
			var ash_guard := _learned_ash_guard()
			return ash_guard.guard_duration + effect_amount if ash_guard != null else 0.0
		SHOVES:
			var unshakable := _player.get_node_or_null(UNSHAKABLE) as Unshakable
			return (unshakable.resting_share() if unshakable != null else 1.0) * 100.0 + effect_amount
	push_warning("EmberTreeStatSheet: unknown stat '%s'." % stat)
	return 0.0


## The stat's value as the stats panel shows it, e.g. "72 px/s" or "1/s for 3s".
func shown_value(stat: String) -> String:
	if stat == GUARD:
		return _guard_text()
	if stat == AWAKENING:
		return _awakening_text()
	if stat != BURN:
		return value_text(stat, value(stat))
	var searing_jab := _learned_searing_jab()
	if searing_jab == null:
		return NOT_LEARNED
	var duration := EmberTreeSkillFacts.number_text(searing_jab.current_burn_duration())
	return "%d/s for %ss" % [searing_jab.burn_damage, duration]


## "I (+3 health, +1 jab)", or NOT_LEARNED before the first Awakening.
func _awakening_text() -> String:
	if Awakening.stage == AwakeningStage.NONE:
		return NOT_LEARNED
	return "%s (%s)" % [AwakeningStage.NUMERALS[Awakening.stage], AwakeningBoost.bonus_text(Awakening.stage)]


## The player's Searing Jab, or null while it isn't learned.
func _learned_searing_jab() -> SearingJab:
	var searing_jab := _player.get_node_or_null(SEARING_JAB) as SearingJab
	return searing_jab if searing_jab != null and searing_jab.is_unlocked() else null


## "50% for 1.2s" (damage taken while guarding), or NOT_LEARNED.
func _guard_text() -> String:
	var ash_guard := _learned_ash_guard()
	if ash_guard == null:
		return NOT_LEARNED
	var duration := EmberTreeSkillFacts.number_text(ash_guard.guard_duration)
	return "%d%s for %ss" % [ash_guard.damage_taken_percent, PERCENT_SIGN, duration]


## The player's Ash Guard, or null while it isn't learned.
func _learned_ash_guard() -> AshGuard:
	var ash_guard := _player.get_node_or_null(ASH_GUARD) as AshGuard
	return ash_guard if ash_guard != null and EmberTree.is_skill_unlocked(ash_guard.name) else null


## What a stat node does, one entry per stat: {"stat", "before", "after"}. For a node
## already learned, "before" is the value without it, so the numbers never change meaning.
func changes_from(node: EmberTreeNode) -> Array[Dictionary]:
	var changes: Array[Dictionary] = []
	if not has_player():
		return changes
	var is_learned := EmberTree.is_learned(node.id)
	for effect: String in node.stat_changes:
		var stat: String = STAT_FOR_EFFECT[effect]
		var amount := float(node.stat_changes[effect])
		var before := value_with(stat, -amount if is_learned else 0.0)
		var after := value_with(stat, 0.0 if is_learned else amount)
		changes.append({"stat": stat, "before": before, "after": after})
	return changes


## A number as the screen shows it: "12", "0.36s", "72 px/s", "10%", "×2".
static func value_text(stat: String, number: float) -> String:
	match stat:
		RUN_SPEED:
			return _number_text(stat, number) + SPEED_UNIT
		CRIT_CHANCE, SHOVES:
			return _number_text(stat, number) + PERCENT_SIGN
	return _number_text(stat, number)


## A change in full words, e.g. "Run speed 60 → 72 px/s (+20%)" or "Max Health 10 → 12".
static func change_line(stat: String, before: float, after: float) -> String:
	var line := "%s %s" % [LABELS[stat], change_text(stat, before, after)]
	if stat == RUN_SPEED and before > 0.0:
		line += " (%+d%%)" % roundi((after - before) / before * 100.0)
	return line


## Just the numbers of a change, e.g. "60 → 72 px/s" or "0.44s → 0.36s".
static func change_text(stat: String, before: float, after: float) -> String:
	return _number_text(stat, before) + ARROW + value_text(stat, after)


static func _number_text(stat: String, number: float) -> String:
	if SECONDS_STATS.has(stat):
		return "%.2fs" % number
	if stat == CRIT_DAMAGE:
		# Multipliers keep their tenths when they have them, e.g. "×2" or "×2.5".
		return TIMES_SIGN + str(snappedf(number, 0.1)).trim_suffix(".0")
	return str(roundi(number))
