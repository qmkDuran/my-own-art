class_name ShalendrillAttack
extends CaptainAttack
## One of the Shalendrill's attacks. The same wind-up / glint / release / follow-through as
## the Warden Captain's (see CaptainAttack; its `captain` is the Shalendrill here), plus what a
## brawler that leaps and reels needs: it can move the boss while it plays out, and it can
## change the punish window that follows (e.g. a long reel after its knuckles crack on a guard).

## Set by the Shalendrill before each start: phase-2 versions of a move can do more.
var is_phase_two: bool = false


## The boss's velocity during the attack (e.g. the arc of a leap); still by default.
func movement_velocity(_seconds_attacking: float) -> Vector2:
	return Vector2.ZERO


## Seconds of punish window after this attack, before phase 2 shortens it.
func recovery_seconds() -> float:
	return recovery_time


## The pose the boss holds while recovering.
func recovery_pose() -> String:
	return recovery_animation
