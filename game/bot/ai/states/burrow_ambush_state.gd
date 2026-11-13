class_name BurrowAmbushState
extends BotState
## Burrow ambush: go to soft soil near where the player is (or is predicted to be), dig in, creep under it toward
## the player and pop up beside it. Underground the bot is unseen but leaves a rumbling dust trail.

const POP_SHARE: float = 0.8
const TIME_LIMIT: float = 14.0
## Underground but not getting any closer for this long (edge of the soil): pop up where it is.
const BLOCKED_AFTER: float = 1.5

var _time: float = 0.0
var _under_time: float = 0.0


func enter() -> void:
	_time = 0.0
	_under_time = 0.0
	stop_looking()
	var reach: float = Tuning.ai_f("tactics", "near_feature_reach")
	var soil: Vector3 = brain.woods.soft_spot_near(brain.predicted_target(), reach)
	done = soil == Vector3.INF
	if not done:
		mover().go_to(soil, true, true)


func tick(delta: float) -> void:
	_time += delta
	var burrow: BurrowMove = bot().move_with_role("burrow") as BurrowMove
	if done or burrow == null:
		done = true
		return
	if burrow.underground():
		_under_time += delta
		_creep(burrow)
	elif mover().arrived() and not bot().busy():
		mover().stop()
		if not use_role("burrow"):
			done = true
	done = done or _time > TIME_LIMIT


func _creep(burrow: BurrowMove) -> void:
	var guess: Vector3 = brain.predicted_target()
	mover().go_to(guess, true)
	var close: bool = bot().global_position.distance_to(guess) <= burrow.number("pop_radius") * POP_SHARE
	var blocked: bool = _under_time > BLOCKED_AFTER and bot().horizontal_speed() < Creature.MOVING_SPEED
	if close or blocked:
		burrow.pop_up()
		done = true


## A burrow ambush is a plan: once decided it runs to the end (or its time limit).
func committed() -> bool:
	return not done
