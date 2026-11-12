class_name FightState
extends BotState
## Fight in the open, facing the player. In "spit" mode it holds a middle distance, strafing one way then the
## other, and spits (leading the player's observed movement) whenever it has a clear shot. In "bite" mode it
## closes in and bites. Every attack is telegraphed by the creature's wind-up.

const STRAFE_STEP: float = 2.5
## A strafe goal the navmesh pulls back to less than this share of a step means that side is blocked.
const BLOCKED_SHARE: float = 0.5

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
	_aim(clue)
	done = not senses().sees_target
	if bot().busy():
		mover().stop()
	elif _mode == "bite":
		_close_and_bite(clue)
	elif not _spit():
		_strafe(delta)


## Spit leads the player's observed velocity; the bite goes straight at it.
func _aim(clue: Vector3) -> void:
	var chest: Vector3 = clue + Vector3.UP * Tuning.f("perception", "chest_height")
	if _mode == "spit":
		bot().aim_point = Prediction.lead_point(bot().mouth_position(), chest, senses().observed_velocity,
				Tuning.f("spit", "speed"))
	else:
		bot().aim_point = chest


func _close_and_bite(clue: Vector3) -> void:
	if distance_to_clue() <= Tuning.f("bot", "bite_engage_range"):
		mover().stop()
		bot().try_bite()
	else:
		mover().go_to(clue, false)


func _spit() -> bool:
	var chest: Vector3 = senses().last_known_position + Vector3.UP * Tuning.f("perception", "chest_height")
	if not bot().spit.is_ready() or not Sight.clear(bot().get_world_3d(), bot().mouth_position(), chest):
		return false
	mover().stop()
	return bot().try_spit()


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
