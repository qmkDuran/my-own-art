class_name SwapMove
extends Node
## A team creature's swap move (see PROJECT_B.md, "Chaining"): an Outro plays as it leaves
## the field (a parting set-up or a gift for the incoming teammate); an Intro plays as it
## comes in (its entrance, and its Signal Skill when a condition it needs is on an enemy).
## The Party plays a member's child named "Outro" when it is swapped out and its child
## named "Intro" when it is swapped in.


## Plays the move for `member`, leaving (Outro) or arriving (Intro) at its spot. `partner`
## is the other creature in the swap (the incoming one for an Outro, the outgoing one for
## an Intro).
func play(_member: PlayableCreature, _partner: PlayableCreature) -> void:
	pass


## For an Intro: whether coming in at `spot` would fire its Signal Skill right now.
func is_armed_at(spot: Vector2) -> bool:
	return not armed_status_at(spot).is_empty()


## For an Intro: the status (SetUp name) on a nearby enemy that would fire its Signal Skill
## at `spot` ("" when not armed). The team card shows that status's icon.
func armed_status_at(_spot: Vector2) -> String:
	return ""


## For an Intro: seconds from the swap until its entrance lands (the swap i-frames cover it).
func entrance_seconds() -> float:
	return 0.0


## What the move does, in one plain line with its real numbers (for the chain guide).
func guide_line() -> String:
	return ""


## For an Outro: the status (a SetUp name) it leaves on enemies, "" for none (chain guide).
func set_up_status() -> String:
	return ""
