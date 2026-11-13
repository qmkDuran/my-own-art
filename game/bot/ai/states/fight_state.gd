class_name FightState
extends BotState
## Fight in the open with one of its equipped attacks, facing the player. "ranged": hold a middle distance,
## strafing one way then the other, and shoot (leading the player's observed movement) whenever it has a clear shot.
## "melee" and "area": close in to the move's reach and use it. Every attack is telegraphed by its wind-up.

const STRAFE_STEP: float = 2.5
## A strafe goal the navmesh pulls back to less than this share of a step means that side is blocked.
const BLOCKED_SHARE: float = 0.5
## Strikes start a little inside their full reach, so the lunge or ring lands.
const STRIKE_SHARE: float = 0.8

var _mode: String
var _strafe_side: float = 1.0
var _strafe_left: float = 0.0


func _init(owner: BotBrain, mode: String) -> void:
	super(owner)
	_mode = mode


func enter() -> void:
	_strafe_left = Tuning.f("bot", "strafe_switch_time")


func exit() -> void:
	stop_looking()


func tick(delta: float) -> void:
	var clue: Vector3 = senses().last_known_position
	look_at_point(clue)
	aim_at_clue(_mode == "ranged")
	done = not senses().sees_target or bot().move_with_role(_mode) == null
	if bot().busy():
		mover().stop()
	elif _mode == "ranged":
		if not _shoot():
			_strafe(delta)
	else:
		_close_and_strike(clue)


## Closes to the move's reach (a strike's range plus lunge, an area's radius) and uses it.
func _close_and_strike(clue: Vector3) -> void:
	var move: Move = bot().move_with_role(_mode)
	if move != null and distance_to_clue() <= BotFacts.effective_range(move) * STRIKE_SHARE:
		mover().stop()
		use_role(_mode)
	else:
		mover().go_to(clue, false)


func _shoot() -> bool:
	var chest: Vector3 = senses().last_known_position + Vector3.UP * Tuning.f("perception", "chest_height")
	if not Sight.clear(bot().get_world_3d(), bot().mouth_position(), chest):
		return false
	mover().stop()
	return use_role("ranged")


func _strafe(delta: float) -> void:
	_strafe_left -= delta
	if _strafe_left <= 0.0 or mover().take_stuck():
		_strafe_side = -_strafe_side
		_strafe_left = Tuning.f("bot", "strafe_switch_time")
	var away: Vector3 = bot().global_position - senses().last_known_position
	away = Vector3(away.x, 0.0, away.z).normalized()
	var radial: float = 0.0
	var preferred: float = Tuning.f("bot", "preferred_distance")
	if distance_to_clue() > preferred + Tuning.f("bot", "distance_slack"):
		radial = -1.0
	elif distance_to_clue() < preferred - Tuning.f("bot", "distance_slack"):
		radial = 1.0
	var goal: Vector3 = brain.woods.on_navmesh(bot().global_position + _strafe_step(away, radial))
	var reach: Vector3 = goal - bot().global_position
	if Vector2(reach.x, reach.z).length() < STRAFE_STEP * BLOCKED_SHARE:
		_strafe_side = -_strafe_side
		goal = brain.woods.on_navmesh(bot().global_position + _strafe_step(away, radial))
	mover().go_to(goal, false)


func _strafe_step(away: Vector3, radial: float) -> Vector3:
	return (away.cross(Vector3.UP) * _strafe_side + away * radial).normalized() * STRAFE_STEP
