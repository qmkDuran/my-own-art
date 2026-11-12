class_name ChaseState
extends BotState
## Chase: run openly toward the player (or the spot it was last seen). Done once there with no sight of it.


func enter() -> void:
	stop_looking()


func tick(_delta: float) -> void:
	mover().go_to(senses().last_known_position, false)
	done = not senses().sees_target and mover().arrived()
