class_name Facing
extends Node
## Remembers which way the creature is looking.
##
## The creature keeps facing its last direction after it stops moving,
## so it doesn't snap back to looking down every time you let go.

enum Direction { DOWN, UP, SIDE }

var direction: Direction = Direction.DOWN
var is_looking_left: bool = false


func look_toward(move_direction: Vector2) -> void:
	if move_direction == Vector2.ZERO:
		return

	if _is_mostly_horizontal(move_direction):
		direction = Direction.SIDE
		is_looking_left = move_direction.x < 0.0
	elif move_direction.y > 0.0:
		direction = Direction.DOWN
	else:
		direction = Direction.UP


func _is_mostly_horizontal(move_direction: Vector2) -> bool:
	return absf(move_direction.x) >= absf(move_direction.y)
