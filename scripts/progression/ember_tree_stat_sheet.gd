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
const HEALTH := "health"
const JAB_DAMAGE := "jab_damage"
const JAB_TIME := "jab_time"
const RUN_SPEED := "run_speed"
const DODGE_COOLDOWN := "dodge_cooldown"
const MAX_HEAT := "max_heat"
## Burn joins this list once the burn effect is built (Searing Jab, Kindling).
const ORDER: Array[String] = [LEVEL, HEALTH, JAB_DAMAGE, JAB_TIME, RUN_SPEED, DODGE_COOLDOWN, MAX_HEAT]

const LABELS := {
	LEVEL: "Level", HEALTH: "Max Health", JAB_DAMAGE: "Jab damage", JAB_TIME: "Time between jabs",
	RUN_SPEED: "Run speed", DODGE_COOLDOWN: "Dodge cooldown", MAX_HEAT: "Max Heat",
}
## Which stat each Ember Tree effect (EmberTreeEffects, the "stats" of a node) changes.
const STAT_FOR_EFFECT := {
	EmberTreeEffects.MAX_HEALTH: HEALTH, EmberTreeEffects.JAB_DAMAGE: JAB_DAMAGE,
	EmberTreeEffects.JAB_RECOVERY_CUT: JAB_TIME, EmberTreeEffects.MOVE_SPEED: RUN_SPEED,
	EmberTreeEffects.DODGE_COOLDOWN_CUT: DODGE_COOLDOWN, EmberTreeEffects.MAX_HEAT: MAX_HEAT,
}
const SECONDS_STATS: Array[String] = [JAB_TIME, DODGE_COOLDOWN]
const SPEED_UNIT := " px/s"
const ARROW := " → "

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
		HEALTH:
			return (_player.get_node("Health") as Health).max_health + effect_amount
		JAB_DAMAGE:
			return (_player.get_node("MeleeAttack") as MeleeAttack).damage + effect_amount
		JAB_TIME:
			var melee: MeleeAttack = _player.get_node("MeleeAttack")
			return maxf(melee.hit_delay, melee.attack_duration - melee.recovery_cut - effect_amount)
		RUN_SPEED:
			return (_player.get_node("Movement") as Movement).top_speed + effect_amount
		DODGE_COOLDOWN:
			return maxf(0.0, (_player.get_node("Dodge") as Dodge).cooldown - effect_amount)
		MAX_HEAT:
			return (_player.get_node("Heat") as Heat).max_heat + effect_amount
	push_warning("EmberTreeStatSheet: unknown stat '%s'." % stat)
	return 0.0


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


## A number as the screen shows it: "12", "0.36s", "72 px/s".
static func value_text(stat: String, number: float) -> String:
	return _number_text(stat, number) + (SPEED_UNIT if stat == RUN_SPEED else "")


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
	return str(roundi(number))
