class_name Shalendrill
extends Boss
## The Shalendrill: Act 1's mid-act boss, a hulking shale-backed mandrill Glimra the AI God
## has bound with a chip (the cyan in its eyes, muzzle and stone is the stolen light).
##
## It knuckle-walks the player down (see Boss) and picks one of its attacks: the knuckle
## barrage up close (blocked on Ash Guard, it reels), the quake slam (a gapless ring to
## dodge-leap, then its fists are stuck), the leap onto a player who keeps away, and in
## phase 2 the Rockfall and a call for Fizzbugs. At half health it roars (ShalendrillRoar, its
## phase-change moment) and BossPhaseTwo makes it faster. ShalendrillDefeat plays its death.

@onready var roar: ShalendrillRoar = $Roar


## Its own numbers (a scene can still change them): slower and heavier than the Captain.
func _init() -> void:
	walk_speed = 22.0
	stop_distance = 24.0
	stagger_time = 0.3
	stagger_cooldown = 2.5
	knockback_share = 0.25


func _wants_phase_change_moment() -> bool:
	return phase_two.is_active and not roar.has_roared and not _is_dying


func _start_phase_change_moment() -> void:
	velocity = Vector2.ZERO
	sprite.replay_animation("roar")
	roar.play()
	_timer.enter(State.PHASE_CHANGE, roar.duration)


## Only a flinch that doesn't extend a punish window shows the hurt pose.
func _show_flinch(still_recovering_for: float) -> void:
	if still_recovering_for <= stagger_time:
		sprite.replay_animation("hurt")


func _on_returned_to_spawn() -> void:
	super._on_returned_to_spawn()
	roar.reset()
