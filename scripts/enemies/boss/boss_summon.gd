class_name BossSummon
extends BossAttack
## A boss calls bound Glimra to the fight (the Warden Captain raises his rod like any Warden;
## the Shalendrill calls Fizzbugs). The creatures, the timing between waves and the cap on
## how many are out at once live on a HandlerSummoner; this makes the call one of the boss's
## attacks (pose, tip flare, battle cry).

@export var summoner: HandlerSummoner
## The boss only summons when the player is at least this far away, so it doesn't turn its back on them.
@export var minimum_distance: float = 30.0
@export var speech_bubble: SpeechBubble
## The flare while the boss calls (e.g. the Captain's rod tip); optional.
@export var charge_particles: ChargeParticles


func _ready() -> void:
	super._ready()
	summoner.wait_before_next_summon(first_use_delay)


func count_down(delta: float) -> void:
	super.count_down(delta)
	summoner.count_down(delta)


func start_over() -> void:
	super.start_over()
	summoner.start_over(first_use_delay)


func _is_wanted(distance_to_player: float) -> bool:
	return distance_to_player >= minimum_distance and summoner.is_time_to_summon()


func _on_start() -> void:
	var battle_cry := summoner.battle_cry()
	if battle_cry != "" and speech_bubble != null:
		speech_bubble.say(battle_cry)
	if charge_particles != null:
		charge_particles.start_charging()


func _release() -> void:
	if charge_particles != null:
		charge_particles.stop_charging()
	summoner.finish_summon()


func _on_finish() -> void:
	if charge_particles != null:
		charge_particles.stop_charging()
