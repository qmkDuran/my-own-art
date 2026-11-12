class_name BotMover
extends Node
## Walks the bot along the baked navmesh: go to a point (running or sneaking), stop, report arrival. Steers around
## snares the bot knows about, and if it ever stops making progress it asks for a fresh path and reports being
## stuck so the current state can pick another goal. The bot never just grinds against a tree.

const PATH_SPACING: float = 0.5
const DETOUR_REACHED: float = 0.4
const DETOUR_PAST: float = 0.6

var _bot: Creature
var _senses: Perception
var _woods: Woods
var _agent: NavigationAgent3D
var _destination: Vector3 = Vector3.ZERO
var _moving: bool = false
var _sneak: bool = false
var _stuck_for: float = 0.0
var _was_stuck: bool = false
var _detour: Vector3 = Vector3.INF


func setup(bot: Creature, senses: Perception, woods: Woods) -> void:
	_bot = bot
	_senses = senses
	_woods = woods
	name = "BotMover"
	_agent = NavigationAgent3D.new()
	_agent.path_desired_distance = PATH_SPACING
	_agent.target_desired_distance = Tuning.f("bot", "arrive_distance")
	bot.add_child(_agent)


func go_to(point: Vector3, sneak: bool) -> void:
	_sneak = sneak
	var goal: Vector3 = _woods.on_navmesh(_clear_of_snares(point))
	if _moving and goal.distance_to(_destination) < Tuning.f("bot", "repath_distance"):
		return
	_destination = goal
	_detour = Vector3.INF
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
	if _flat(_destination - _bot.global_position).length() <= Tuning.f("bot", "arrive_distance"):
		stop()
		return
	var direction: Vector3 = _flat(_agent.get_next_path_position() - _bot.global_position).normalized()
	_bot.move_intent = _steer_around_snares(direction)
	_watch_progress(delta)


## A known snare near the way ahead gets one detour point beside and just past it, on a side chosen once, so
## the bot walks a smooth arc around it instead of dithering.
func _steer_around_snares(direction: Vector3) -> Vector3:
	if _detour == Vector3.INF:
		_detour = _detour_for(direction)
	if _detour == Vector3.INF:
		return direction
	var to_detour: Vector3 = _flat(_detour - _bot.global_position)
	if to_detour.length() <= DETOUR_REACHED:
		_detour = Vector3.INF
		_agent.target_position = _destination
		return direction
	return to_detour.normalized()


func _detour_for(direction: Vector3) -> Vector3:
	var keep_out: float = _snare_keep_out()
	for snare: Vector3 in _senses.known_snares:
		var offset: Vector3 = _flat(snare - _bot.global_position)
		var ahead: float = offset.dot(direction)
		var lateral: Vector3 = offset - direction * ahead
		if ahead > 0.0 and ahead <= Tuning.f("bot", "steer_look_ahead") and lateral.length() < keep_out:
			var side: Vector3 = direction.cross(Vector3.UP)
			if lateral.length() > DETOUR_REACHED:
				side = -lateral.normalized()
			return _walkable_detour(snare, side, direction, keep_out)
	return Vector3.INF


## The detour on the preferred side, or on the other side when the preferred one is blocked (rock, tree).
func _walkable_detour(snare: Vector3, side: Vector3, direction: Vector3, keep_out: float) -> Vector3:
	for flip: float in [1.0, -1.0]:
		var point: Vector3 = snare + side * flip * (keep_out + DETOUR_REACHED) + direction * DETOUR_PAST
		if _flat(_woods.on_navmesh(point) - point).length() <= DETOUR_REACHED:
			return point
	return Vector3.INF


func _clear_of_snares(point: Vector3) -> Vector3:
	var keep_out: float = _snare_keep_out()
	for snare: Vector3 in _senses.known_snares:
		var offset: Vector3 = _flat(point - snare)
		if offset.length() < keep_out:
			var away: Vector3 = offset.normalized() if offset.length() > 0.0 else Vector3.RIGHT
			point = snare + away * keep_out
	return point


func _snare_keep_out() -> float:
	return Tuning.f("trap", "trigger_radius") + Tuning.f("trap", "avoid_margin")


func _watch_progress(delta: float) -> void:
	var blocked: bool = _bot.horizontal_speed() < Tuning.f("bot", "stuck_speed")
	if _bot.busy() or _bot.is_rooted() or _bot.is_staggered() or not blocked:
		_stuck_for = 0.0
		return
	_stuck_for += delta
	if _stuck_for >= Tuning.f("bot", "stuck_time"):
		_stuck_for = 0.0
		_was_stuck = true
		_detour = Vector3.INF
		_agent.target_position = _destination


static func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)
