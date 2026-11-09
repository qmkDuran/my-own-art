class_name Buffeted
extends ImpairingEffect
## A gust's push (the Wind element), e.g. from a Zephoot's gust orb: the target is shoved
## for a moment (see PlayerHit.shove). Then gusts can't push it again for a while
## (ImpairingEffect.IMMUNITY_SECONDS), so a volley of orbs can't juggle the player; the
## orbs still hurt. Too short for a HUD icon or a tint: the push itself is the cue.

## The child name a target's gust push goes by.
const NODE_NAME := "Buffeted"


## Pushes the target with `target_health` (a player) with `push_velocity` for `seconds`.
## False when it didn't take (dead, guarding or still immune after the last gust).
static func apply_to(target_health: Health, push_velocity: Vector2, seconds: float) -> bool:
	var buffeted := _find_or_add(target_health, NODE_NAME, func() -> StatusEffect: return Buffeted.new()) as Buffeted
	if buffeted == null or buffeted.is_active():
		return false
	buffeted.start(seconds)
	PlayerHit.shove(buffeted.get_target() as Node2D, push_velocity, seconds)
	return true
