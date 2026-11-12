class_name StalkState
extends BotState
## Stalk: the bot has spotted the player, but the player has not spotted it. It sneaks in (slow and quiet), aiming
## to come from behind, and opens with an ambush bite. The moment the player notices it, it fights in the open.

const BEHIND_DISTANCE: float = 1.5

var _struck: bool = false


func enter() -> void:
	_struck = false
	stop_looking()


func exit() -> void:
	stop_looking()


func tick(_delta: float) -> String:
	if _struck:
		return "" if bot().busy() else "fight"
	if target().aware_of_opponent:
		return pursuit_state()
	if not senses().sees_target and senses().time_since_seen > Tuning.f("bot", "hunt_memory"):
		return "search"
	if distance_to_target() > Tuning.f("bot", "stalk_give_up_range"):
		return "hunt"
	if distance_to_target() <= Tuning.f("bot", "bite_engage_range"):
		_strike()
	else:
		mover().go_to(target().global_position - target().forward() * BEHIND_DISTANCE, true)
	return ""


func _strike() -> void:
	mover().stop()
	bot().aim_point = target().global_position
	look_at_point(target().global_position)
	_struck = bot().try_bite()
