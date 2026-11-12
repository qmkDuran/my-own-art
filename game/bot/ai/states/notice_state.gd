class_name NoticeState
extends BotState
## Notice: the first sound or sighting while idle. Stop and turn toward it with a "!" overhead for the bot's
## reaction time (longer on Easy): a readable beat before it acts.

var _left: float = 0.0


func enter() -> void:
	mover().stop()
	_left = Difficulty.setting("reaction_time")


func exit() -> void:
	stop_looking()


func tick(delta: float) -> void:
	look_at_point(senses().last_known_position)
	_left -= delta
	done = _left <= 0.0


func committed() -> bool:
	return not done
