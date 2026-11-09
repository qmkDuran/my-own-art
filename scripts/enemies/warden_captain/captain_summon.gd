class_name CaptainSummon
extends CaptainAttack
## The Captain raises his rod and calls bound Glimra to the fight, like any Warden. The
## creatures, the timing between waves and the cap on how many are out at once live on a
## HandlerSummoner; this makes the call one of his attacks (pose, tip flare, battle cry).

@export var summoner: HandlerSummoner
## He only summons when the player is at least this far away, so he doesn't turn his back on them.
@export var minimum_distance: float = 30.0
@export var speech_bubble: SpeechBubble
## The tip flare while he calls.
@export var charge_particles: ChargeParticles


func _ready() -> void:
	super._ready()
	summoner.wait_before_next_summon(first_use_delay)


func count_down(delta: float) -> void:
	super.count_down(delta)
	summoner.count_down(delta)


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
