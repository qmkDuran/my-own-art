class_name Staggered
extends ImpairingEffect
## A stagger (the Stone element), e.g. from a Gruntite's charge ram: the target's current
## action (a jab, a skill) is cut off and it can't act for a moment. Then it can't be
## staggered again for a while (ImpairingEffect.IMMUNITY_SECONDS).
##
## Attached at runtime by `Staggered.apply_to`. The target is told through `interrupt()`
## (if it has one) and asks `Staggered.is_staggering(self)` each frame. Its sprite takes a
## stone tint meanwhile. Unshakable shortens it, Ash Guard blocks it (see StatusResistance).

## The child name a target's stagger goes by.
const NODE_NAME := "Staggered"


## Staggers the target with `target_health` for `seconds`. False when it didn't take
## (dead, guarding, already staggered or still immune after the last one).
static func apply_to(target_health: Health, seconds: float) -> bool:
	var staggered := _find_or_add(target_health, NODE_NAME, func() -> StatusEffect: return Staggered.new()) as Staggered
	if staggered == null or staggered.is_active():
		return false
	staggered.start(_resisted_length(target_health, NODE_NAME, seconds))
	var creature := staggered.get_target() as Creature
	if creature != null:
		creature.interrupt()
	return true


## True while `creature` is staggered (it can't act).
static func is_staggering(creature: Node) -> bool:
	var staggered := creature.get_node_or_null(NODE_NAME) as Staggered
	return staggered != null and staggered.is_active()


func _tint_color() -> Color:
	return StatusColors.STAGGER
