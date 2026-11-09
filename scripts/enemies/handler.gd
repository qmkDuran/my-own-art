class_name Handler
extends Enemy
## A Handler: an early-game grunt who serves the AI God.
##
## He never attacks. He keeps his distance from the player (HandlerRetreat), and every few
## seconds raises his control rod to summon bound creatures (toads), up to a limit. Killing
## him stops the summoning; creatures already out keep fighting.
##
## This script runs his state machine; keeping his distance, the summoning and the rod shove
## are child components (HandlerRetreat, HandlerSummoner, HandlerRodShove). He notices the
## player further away than a toad: his visor is tuned to see Glimra light.
##
## States:
##   WATCHING  -> stands still, keeping an eye on the player
##   RETREATING-> walks away because the player is too close (tires out after a bit)
##   SUMMONING -> raises the rod; creatures appear at the end
##   SHOVING   -> player too close: raises the rod overhead while red energy gathers into it,
##                then slams it into the ground; the shockwave knocks the player back
##                (hits don't interrupt it: super armour)
##   RECOVERING-> knocked back after being hit
##   DYING     -> fades away
##
## He only starts once he notices the player (they come within `notice_distance`, or he gets
## hit); until then he stands watching. While DebugControls.enemies_passive is on, he only
## stands (WATCHING) and reacts to hits.

enum State { WATCHING, RETREATING, SUMMONING, SHOVING, RECOVERING, DYING }

@export_group("Summoning")
## Seconds before his first summon (the rest of the summoning is set on his Summoner).
@export var first_summon_delay: float = 1.0

@export_group("Getting hit")
@export var recover_time: float = 0.25

@onready var charge_particles: ChargeParticles = $ChargeParticles
@onready var speech_bubble: SpeechBubble = $SpeechBubble
@onready var retreat: HandlerRetreat = $Retreat
@onready var summoner: HandlerSummoner = $Summoner
@onready var rod_shove: HandlerRodShove = $RodShove


func _ready() -> void:
	super._ready()
	summoner.wait_before_next_summon(first_summon_delay)
	_timer.enter(State.WATCHING, 0.0)


func _physics_process(delta: float) -> void:
	_timer.advance(delta)
	var is_alert := _is_alert()
	if _timer.state != State.DYING and is_alert:
		summoner.count_down(delta)
		rod_shove.count_down(delta)

	if DebugControls.enemies_passive:
		_stop_acting()

	match _timer.state:
		State.WATCHING, State.RETREATING:
			if _can_act(is_alert):
				_keep_distance_or_summon(delta)
			else:
				_stand_still()
		State.SHOVING:
			_shove()
		State.SUMMONING:
			_summon()
		State.RECOVERING, State.DYING:
			_slide_then(State.RECOVERING, State.WATCHING, delta)

	move_and_slide()


# --- States ---------------------------------------------------------------

func _keep_distance_or_summon(delta: float) -> void:
	if rod_shove.should_shove():
		_start_shove()
		return
	if summoner.is_time_to_summon():
		_start_summon()
		return

	var retreat_velocity := retreat.next_velocity(_timer.state == State.RETREATING, delta)
	if retreat_velocity == Vector2.ZERO:
		_stand_still()
	else:
		_back_away(retreat_velocity)


func _stand_still() -> void:
	velocity = Vector2.ZERO
	_timer.state = State.WATCHING
	sprite.show_animation("idle")


func _back_away(retreat_velocity: Vector2) -> void:
	velocity = retreat_velocity
	_timer.state = State.RETREATING
	sprite.show_animation("walk")


func _start_summon() -> void:
	# His first summon of the fight comes with a shout.
	var battle_cry := summoner.battle_cry()
	if battle_cry != "":
		speech_bubble.say(battle_cry)
	sprite.replay_animation("summon")
	_timer.enter(State.SUMMONING, summoner.summon_duration)


func _summon() -> void:
	velocity = Vector2.ZERO
	if _timer.is_over():
		summoner.finish_summon()
		_timer.enter(State.WATCHING, 0.0)


func _start_shove() -> void:
	sprite.replay_animation("shove", "summon")
	rod_shove.start()
	_timer.enter(State.SHOVING, rod_shove.duration())


func _shove() -> void:
	velocity = Vector2.ZERO
	rod_shove.update(_timer.elapsed)
	if _timer.is_over():
		rod_shove.finish()
		_timer.enter(State.WATCHING, 0.0)


## Debug (enemies passive): a summon or a slam in progress is called off and he just stands.
## Recovering from a hit and dying carry on as normal.
func _stop_acting() -> void:
	if _timer.state != State.SUMMONING and _timer.state != State.SHOVING:
		return
	charge_particles.stop_charging()
	_timer.enter(State.WATCHING, 0.0)


# --- Reactions ------------------------------------------------------------

## Super armour: once the shove is winding up, hits hurt but don't interrupt or push it.
## Otherwise holding attack would cancel it every time.
func _has_super_armour() -> bool:
	return _timer.state == State.SHOVING


func _react_to_hit(source_position: Vector2) -> void:
	if _has_super_armour():
		return
	_knock_back_from(source_position)
	_timer.enter(State.RECOVERING, recover_time)


## Back at his spawn after the player fell: his first summon of the next fight waits again.
func _on_returned_to_spawn() -> void:
	charge_particles.stop_charging()
	summoner.start_over(first_summon_delay)


func _die() -> void:
	charge_particles.stop_charging()
	_enter_dying_and_fade(State.DYING)
