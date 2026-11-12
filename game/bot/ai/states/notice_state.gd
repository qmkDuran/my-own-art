class_name NoticeState
extends BotState
## Notice: stop, turn toward what was seen or heard, a "!" over the head. A readable beat before anything happens.
## Then: stalk (it saw you, you have not seen it), hunt (it saw you), or search (it only heard you).

var _left: float = 0.0


func enter() -> void:
	mover().stop()
	_left = Tuning.f("bot", "notice_time")


func exit() -> void:
	stop_looking()


func tick(delta: float) -> String:
	look_at_point(senses().last_known_position)
	_left -= delta
	if _left > 0.0:
		return ""
	if not senses().sees_target:
		return "search"
	var unnoticed: bool = not target().aware_of_opponent
	return "stalk" if unnoticed and distance_to_target() <= Tuning.f("bot", "stalk_range") else "hunt"
