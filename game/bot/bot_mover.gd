class_name BotMover
extends Node
## Walks the bot along the baked navmesh: go to a point (running or sneaking), stop, report arrival. If it stops
## making progress it side-steps (alternating sides) and asks for a fresh
## path; stuck a third time on the same goal, it gives up on it (counts as arrived), so every state moves on. The
## bot never grinds against a tree.

const PATH_SPACING: float = 0.5
const GIVE_UP_AFTER: int = 3
const NEW_GOAL_DISTANCE: float = 3.0

var _bot: Creature
var _woods: Woods
var _agent: NavigationAgent3D
var _destination: Vector3 = Vector3.ZERO
var _moving: bool = false
var _sneak: bool = false
var _stuck_for: float = 0.0
var _was_stuck: bool = false
var _arrive: float = 0.0
var _stuck_count: int = 0
var _window_start: Vector3 = Vector3.ZERO
var _sidestep: Vector3 = Vector3.ZERO
var _sidestep_left: float = 0.0


func setup(bot: Creature, woods: Woods) -> void:
	_bot = bot
	_woods = woods
	name = "BotMover"
	_agent = NavigationAgent3D.new()
	_agent.path_desired_distance = PATH_SPACING
	_agent.target_desired_distance = Tuning.f("bot", "arrive_distance")
	bot.add_child(_agent)


## precise goals (a spot behind cover, a bush) must be reached closely; others count as reached a step away.
func go_to(point: Vector3, sneak: bool, precise: bool = false) -> void:
	_sneak = sneak
	_arrive = Tuning.f("bot", "precise_arrive_distance" if precise else "arrive_distance")
	var goal: Vector3 = _woods.on_navmesh(point)
	if _moving and goal.distance_to(_destination) < Tuning.f("bot", "repath_distance"):
		return
	if not _moving or goal.distance_to(_destination) > NEW_GOAL_DISTANCE:
		_stuck_count = 0
		_restart_progress_window()
	_destination = goal
	_agent.target_position = goal
	_moving = true


func stop() -> void:
	_moving = false
	_bot.move_intent = Vector3.ZERO


func arrived() -> bool:
	return not _moving


## True once after the bot got stuck (the state may want a different goal).
func take_stuck() -> bool:
	var stuck: bool = _was_stuck
	_was_stuck = false
	return stuck


func tick(delta: float) -> void:
	_bot.sneaking = _sneak
	if not _moving:
		_bot.move_intent = Vector3.ZERO
		return
	if _flat(_destination - _bot.global_position).length() <= _arrive:
		stop()
		return
	if _sidestep_left > 0.0:
		_sidestep_left -= delta
		_bot.move_intent = _sidestep
		return
	var direction: Vector3 = _flat(_agent.get_next_path_position() - _bot.global_position).normalized()
	_bot.move_intent = direction * _approach_share()
	_watch_progress(delta)


## Eases off near the goal so the bot stops on it instead of circling it.
func _approach_share() -> float:
	var left: float = _flat(_destination - _bot.global_position).length()
	return clampf(left / Tuning.f("bot", "slow_down_distance"), Tuning.f("bot", "min_approach_share"), 1.0)






func _restart_progress_window() -> void:
	_stuck_for = 0.0
	_window_start = _bot.global_position


## Progress is measured as distance covered over a time window, so pushing into a trunk and circling a goal
## both count as stuck.
func _watch_progress(delta: float) -> void:
	if _bot.busy() or _bot.is_rooted() or _bot.is_staggered():
		_restart_progress_window()
		return
	_stuck_for += delta
	if _stuck_for < Tuning.f("bot", "stuck_time"):
		return
	var covered: float = _flat(_bot.global_position - _window_start).length()
	_restart_progress_window()
	if covered < Tuning.f("bot", "stuck_progress"):
		_was_stuck = true
		_stuck_count += 1
		if _stuck_count >= GIVE_UP_AFTER:
			stop()
		else:
			_side_step()


## A short step to one side (the other side next time) to come free of a snag, then a fresh path.
func _side_step() -> void:
	var side: float = 1.0 if _stuck_count % 2 == 1 else -1.0
	var heading: Vector3 = _bot.move_intent if _bot.move_intent.length() > 0.0 else _bot.forward()
	_sidestep = heading.cross(Vector3.UP).normalized() * side
	_sidestep_left = Tuning.f("bot", "sidestep_time")
	_agent.target_position = _destination


static func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)
