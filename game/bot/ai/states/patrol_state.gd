class_name PatrolState
extends BotState
## Patrol: walk quietly from patrol point to patrol point, pausing at each. Anything seen or heard: notice.

var _index: int = 0
var _pause_left: float = 0.0


func enter() -> void:
	stop_looking()
	_go_next()


func tick(delta: float) -> String:
	if senses().sees_target or senses().take_fresh_lead():
		return "notice"
	if mover().arrived():
		_pause_left -= delta
		if _pause_left <= 0.0:
			_go_next()
	return ""


func _go_next() -> void:
	var points: Array[Vector3] = brain.woods.patrol_points
	_index = (_index + 1) % points.size()
	mover().go_to(points[_index], true)
	_pause_left = Tuning.f("bot", "patrol_pause")
