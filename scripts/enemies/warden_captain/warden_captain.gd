class_name WardenCaptain
extends Boss
## The Warden Captain: the first mini-boss, an elite Warden who leads the others.
##
## Unlike a Warden he fights (see Boss): he walks the player down and picks one of his
## attacks: a rod sweep up close, a shockwave slam with a gap, summoning toads (and in phase 2
## a Zephoot), and in phase 2 the chip pulse. At half health he shouts and speeds up
## (BossPhaseTwo); his death plays out in CaptainDefeat.


func _show_flinch(_still_recovering_for: float) -> void:
	sprite.replay_animation("stagger")
