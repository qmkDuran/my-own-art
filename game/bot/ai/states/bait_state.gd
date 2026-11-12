class_name BaitState
extends BotState
## Bait: with its snare set and the player watching, the bot stands just beyond the snare, in plain view, so the
## straight way to it runs over the snare, and spits to provoke. Done after a while or when the snare is gone.

var _time: float = 0.0


func enter() -> void:
	_time = 0.0
	var snare: SnareTrap = bot().trap.snare
	if not is_instance_valid(snare):
		done = true
		return
	var away: Vector3 = snare.global_position - senses().last_known_position
	away.y = 0.0
	mover().go_to(snare.global_position + away.normalized() * Tuning.f("bot", "bait_distance"), false)


func exit() -> void:
	stop_looking()


func tick(delta: float) -> void:
	_time += delta
	var clue: Vector3 = senses().last_known_position
	look_at_point(clue)
	bot().aim_point = Prediction.lead_point(bot().mouth_position(), clue + Vector3.UP * Tuning.f("perception",
			"chest_height"), senses().observed_velocity, Tuning.f("spit", "speed"))
	if mover().arrived() and senses().sees_target:
		bot().try_spit()
	var snare_gone: bool = not is_instance_valid(bot().trap.snare) or bot().trap.snare.sprung
	done = snare_gone or _time > Tuning.f("bot", "bait_time")
