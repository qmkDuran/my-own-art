class_name CoverState
extends BotState
## Cover: being shot at, the bot runs behind the nearest trunk or boulder that blocks the player's line of fire,
## waits there until its own spit is ready again, then comes back out (or flanks if it lost sight of the player).

var _spot: Vector3 = Vector3.INF
var _time: float = 0.0
var _hidden_for: float = 0.0


func enter() -> void:
	brain.since_cover = 0.0
	_time = 0.0
	_hidden_for = 0.0
	_spot = CoverFinder.find(brain.woods, bot().global_position, target().chest_position())
	if _spot != Vector3.INF:
		mover().go_to(_spot, false)


func exit() -> void:
	stop_looking()


func tick(delta: float) -> String:
	if _spot == Vector3.INF or distance_to_target() <= Tuning.f("bot", "cover_min_distance"):
		return "fight"
	_time += delta
	if _time > Tuning.f("bot", "cover_max_time"):
		return _come_out()
	if mover().arrived():
		look_at_point(target().global_position)
		_hidden_for += delta
		if _hidden_for >= Tuning.f("bot", "cover_min_wait") and bot().spit.is_ready():
			return _come_out()
	return ""


func _come_out() -> String:
	return "fight" if senses().sees_target else "hunt"
