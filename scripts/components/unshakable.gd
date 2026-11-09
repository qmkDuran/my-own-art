class_name Unshakable
extends Node
## How much of an enemy's shove actually moves the player (Warden shoves, Gruntite rams,
## gust shots): all of it normally, none while Ash Guard is up, and `push_percent`% once the
## Unshakable node (Ember Tree, Bruiser) is learned. Once learned, staggers (e.g. a Gruntite
## ram) also last only `stagger_percent`% as long (StatusResistance asks `stagger_share`).
##
## The creature asks `share_of_push` in its `push`, so no enemy needs to know about it.
## Its numbers fill the Unshakable facts in the tree and the stats panel's Shoves row.

## The Unshakable node's id (Ember Tree, Bruiser).
const UNSHAKABLE_ID := "unshakable"

## How far shoves push once Unshakable is learned, as a percent of the full push.
@export var push_percent: int = 25
## How long staggers last once Unshakable is learned, as a percent of the full stagger.
@export var stagger_percent: int = 50
## While this guard is up, shoves don't move the player at all.
@export var ash_guard: AshGuard


func is_learned() -> bool:
	return EmberTree.is_learned(UNSHAKABLE_ID)


## Share of a shove (0..1) that moves the player right now. 0 also means the shove
## doesn't interrupt what he is doing.
func share_of_push() -> float:
	if ash_guard != null and ash_guard.is_casting:
		return 0.0
	return resting_share()


## Share of a shove that moves the player when he isn't guarding (shown in the stats panel).
func resting_share() -> float:
	return push_percent / 100.0 if is_learned() else 1.0


## Share of a stagger's length (0..1) the player suffers.
func stagger_share() -> float:
	return stagger_percent / 100.0 if is_learned() else 1.0
