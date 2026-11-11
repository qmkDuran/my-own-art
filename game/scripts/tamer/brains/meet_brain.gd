class_name MeetBrain
extends CreatureBrain
## A starter waiting to be chosen: it stays on its spot and turns to watch the trainer.


func think(_delta: float) -> Vector2:
	c.face(TamerGame.current.trainer.global_position)
	return Vector2.ZERO
