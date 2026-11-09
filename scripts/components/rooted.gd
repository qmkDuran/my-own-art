class_name Rooted
extends ImpairingEffect
## A root snare (the Bloom element), e.g. from a Bramole's slam: the target's feet are held,
## so it can't walk or dodge for a moment, but it can still jab. Then it can't be rooted again
## for a while (ImpairingEffect.IMMUNITY_SECONDS).
##
## Attached at runtime by `Rooted.apply_to`; the target asks `Rooted.is_rooting(self)`.
## Its sprite takes a green tint meanwhile. Ash Guard blocks it (see StatusResistance).

## The child name a target's root goes by.
const NODE_NAME := "Rooted"


## Roots the target with `target_health` for `seconds`. False when it didn't take
## (dead, guarding, already rooted or still immune after the last one).
static func apply_to(target_health: Health, seconds: float) -> bool:
	var rooted := _find_or_add(target_health, NODE_NAME, func() -> StatusEffect: return Rooted.new()) as Rooted
	if rooted == null or rooted.is_active():
		return false
	rooted.start(_resisted_length(target_health, NODE_NAME, seconds))
	return true


## True while `creature` is rooted (it can't move).
static func is_rooting(creature: Node) -> bool:
	var rooted := creature.get_node_or_null(NODE_NAME) as Rooted
	return rooted != null and rooted.is_active()


func _tint_color() -> Color:
	return StatusColors.ROOT
