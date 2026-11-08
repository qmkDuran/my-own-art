class_name CritRoll
extends Node
## The attacker's critical hits: every hit has a small chance to deal extra damage.
##
## The one place crits are decided. Attacks (the jabs, the Spinning Hook, Flame Uppercut)
## hand their damage to `CritRoll.deal_damage`, which finds this node on the attacker,
## rolls and passes the result on to the target's Health. An attacker without a CritRoll
## child never crits.

## The child name `deal_damage` looks for on the attacker.
const NODE_NAME := "CritRoll"

## Chance (0 to 1) that a hit is critical.
@export_range(0.0, 1.0, 0.01) var crit_chance: float = 0.1
## A critical hit deals this many times the normal damage, rounded to whole damage.
@export var crit_multiplier: float = 2.0

## While true, every hit is critical (e.g. a Counter Punch is armed). Whoever sets it clears it.
var is_sure_crit: bool = false


## Damages `target_health` with `base_damage` from `attacker`, rolling the attacker's crit.
static func deal_damage(attacker: Node2D, target_health: Health, base_damage: int) -> void:
	var crit_roll := attacker.get_node_or_null(NODE_NAME) as CritRoll
	var is_critical := crit_roll != null and crit_roll.rolls_critical()
	var amount := crit_roll.critical_damage(base_damage) if is_critical else base_damage
	target_health.take_damage(amount, attacker.global_position, is_critical)


func rolls_critical() -> bool:
	return is_sure_crit or randf() < crit_chance


func critical_damage(base_damage: int) -> int:
	return roundi(base_damage * crit_multiplier)
