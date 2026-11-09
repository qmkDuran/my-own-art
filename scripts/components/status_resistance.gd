class_name StatusResistance
extends Node
## How the player shrugs off enemy status effects (see DESIGN.md, "Enemy status effects"):
## - Ash Guard up: no enemy status effect lands (poison, stagger, gust push). The hit
##   itself still lands, at the guard's reduced damage.
## - Unshakable learned: staggers last only Unshakable's `stagger_percent`% as long.
##
## StatusEffect asks this (by the node name StatusEffect.RESISTANCE_NODE) whenever an
## effect is applied, so no enemy needs to know about it. The player's own fire on
## enemies never comes here: enemies have no StatusResistance.

## The effects Ash Guard blocks.
const GUARD_BLOCKS: Array[String] = [Poisoned.NODE_NAME, Staggered.NODE_NAME, Buffeted.NODE_NAME]

@export var ash_guard: AshGuard
@export var unshakable: Unshakable


## True when the effect called `effect_name` doesn't land on the player right now.
func resists(effect_name: String) -> bool:
	return ash_guard != null and ash_guard.is_casting and effect_name in GUARD_BLOCKS


## `seconds` of the effect called `effect_name`, after the player's resistances.
func length_of(effect_name: String, seconds: float) -> float:
	if effect_name == Staggered.NODE_NAME and unshakable != null:
		return seconds * unshakable.stagger_share()
	return seconds
