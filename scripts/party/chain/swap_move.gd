class_name SwapMove
extends Node
## A team creature's swap-chain move (see PROJECT_B.md, "Chaining"): an Outro plays as it
## leaves the field (it leaves a set-up on enemies), an Intro as it comes in (it cashes a
## set-up in for a big finisher). The Party plays a member's child named "Outro" when it is
## swapped out and its child named "Intro" when it is swapped in.


## Plays the move for `member`, which is leaving (Outro) or arriving (Intro) at its spot.
func play(_member: PlayableCreature) -> void:
	pass


## For an Intro: whether coming in at `spot` would cash in a set-up right now.
func is_armed_at(_spot: Vector2) -> bool:
	return false
