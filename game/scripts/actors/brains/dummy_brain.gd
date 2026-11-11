class_name DummyBrain
extends EnemyBrain
## A practice target: it stands where it is planted and never strikes back.


func _think(_delta: float) -> Vector2:
	return Vector2.ZERO
