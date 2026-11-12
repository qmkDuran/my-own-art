class_name FightState
extends BotState
## Fight: face the player and keep a middle distance, strafing in one direction and then the other. Every attack is
## telegraphed by the creature's wind-up. It spits when it has a clear shot, closes in to bite when it plans to, and
## breaks off to cover when it is being shot at.

const STRAFE_STEP: float = 2.5
## A strafe goal the navmesh pulls back to less than this share of a step means that side is blocked.
const BLOCKED_SHARE: float = 0.5

var _strafe_side: float = 1.0
var _strafe_left: float = 0.0
var _lost_for: float = 0.0
var _plan_bite: bool = false


func enter() -> void:
	_lost_for = 0.0
	_strafe_left = Tuning.f("bot", "strafe_switch_time")
	_plan_next_attack()


func exit() -> void:
	stop_looking()


func tick(delta: float) -> String:
	_lost_for = 0.0 if senses().sees_target else _lost_for + delta
	if _lost_for > Tuning.f("bot", "fight_memory"):
		return "hunt"
	var distance: float = distance_to_target()
	if distance > Tuning.f("bot", "fight_range") * Tuning.f("bot", "leave_fight_factor"):
		return "hunt"
	if _wants_cover(distance):
		return "cover"
	look_at_point(target().global_position)
	bot().aim_point = target().chest_position()
	if bot().busy():
		mover().stop()
	elif not _attack(distance):
		_reposition(delta, distance)
	return ""


func _attack(distance: float) -> bool:
	if bot().bite.is_ready() and distance <= Tuning.f("bot", "bite_engage_range"):
		mover().stop()
		bot().try_bite()
		_plan_next_attack()
		return true
	if _plan_bite and bot().bite.is_ready() and distance <= Tuning.f("bot", "rush_range"):
		mover().go_to(target().global_position, false)
		return true
	if bot().spit.is_ready() and distance >= Tuning.f("bot", "spit_min_range") and _clear_shot():
		mover().stop()
		bot().try_spit()
		_plan_next_attack()
		return true
	return false


func _reposition(delta: float, distance: float) -> void:
	_strafe_left -= delta
	if _strafe_left <= 0.0 or mover().take_stuck():
		_strafe_side = -_strafe_side
		_strafe_left = Tuning.f("bot", "strafe_switch_time")
	var away: Vector3 = bot().global_position - target().global_position
	away = Vector3(away.x, 0.0, away.z).normalized()
	var radial: float = 0.0
	var preferred: float = Tuning.f("bot", "preferred_distance")
	if distance > preferred + Tuning.f("bot", "distance_slack"):
		radial = -1.0
	elif distance < preferred - Tuning.f("bot", "distance_slack"):
		radial = 1.0
	var goal: Vector3 = brain.woods.on_navmesh(bot().global_position + _strafe_step(away, radial))
	var reach: Vector3 = goal - bot().global_position
	if Vector2(reach.x, reach.z).length() < STRAFE_STEP * BLOCKED_SHARE:
		_strafe_side = -_strafe_side
		goal = brain.woods.on_navmesh(bot().global_position + _strafe_step(away, radial))
	mover().go_to(goal, false)


func _strafe_step(away: Vector3, radial: float) -> Vector3:
	return (away.cross(Vector3.UP) * _strafe_side + away * radial).normalized() * STRAFE_STEP


func _wants_cover(distance: float) -> bool:
	if brain.since_cover < Tuning.f("bot", "cover_cooldown") or distance < Tuning.f("bot", "cover_min_distance"):
		return false
	var shot_recently: bool = brain.since_spit_hit <= Tuning.f("bot", "hit_memory")
	var spit_coming: bool = brain.reflexes.incoming_spit() != null and not bot().dodge.is_ready()
	return shot_recently or spit_coming


func _clear_shot() -> bool:
	return Sight.clear(bot().get_world_3d(), bot().mouth_position(), target().chest_position())


func _plan_next_attack() -> void:
	_plan_bite = brain.rng.randf() < Tuning.f("bot", "bite_plan_chance")
