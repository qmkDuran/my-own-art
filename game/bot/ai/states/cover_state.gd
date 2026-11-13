class_name CoverState
extends BotState
## Cover: being shot at, the bot runs to the best covered point nearby (blocked from the player's last known spot,
## with escape routes) and holds there for a moment (until its ranged move is ready again, if it has one). It breaks
## off at once if the player closes in.

var _time: float = 0.0
var _hidden_for: float = 0.0


func enter() -> void:
	brain.since_cover = 0.0
	_time = 0.0
	_hidden_for = 0.0
	done = not go_to_tactical("cover", bot().global_position, false)


func exit() -> void:
	stop_looking()


func tick(delta: float) -> void:
	_time += delta
	if mover().arrived():
		look_at_point(senses().last_known_position)
		_hidden_for += delta
	var ranged: Move = bot().move_with_role("ranged")
	var reloaded: bool = ranged == null or ranged.is_ready()
	var rested: bool = _hidden_for >= Tuning.f("bot", "cover_min_wait") and reloaded
	var rushed: bool = senses().sees_target and distance_to_clue() < Tuning.f("bot", "cover_min_distance")
	done = done or rested or rushed or _time > Tuning.f("bot", "cover_max_time")


## Holds the plan until it has reached cover and sheltered there a moment.
func committed() -> bool:
	return not done and _hidden_for < Tuning.f("bot", "cover_min_wait")
