class_name FlankState
extends BotState
## Flank: the player just slipped out of sight. Instead of following straight in, swing to the best flanking point
## around where the player is predicted to be (a sightline from the side, in range, ideally across its usual
## escape route). Done on arrival or as soon as the player is seen again.


func enter() -> void:
	stop_looking()
	if not go_to_tactical("flank", brain.predicted_target(), false):
		mover().go_to(senses().last_known_position, false)


func tick(_delta: float) -> void:
	done = senses().sees_target or mover().arrived()
