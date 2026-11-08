class_name Facing
extends Node
## Remembers which way the creature is looking, in 8 directions.
##
## There are 5 drawn views: front, front-diagonal, side, back-diagonal and back.
## Left-facing directions reuse the right-facing views, flipped.
## The creature keeps facing its last direction after it stops moving,
## so it doesn't snap back to looking down every time you let go.

enum Direction { DOWN, DOWN_SIDE, SIDE, UP_SIDE, UP }

var direction: Direction = Direction.DOWN
var is_looking_left: bool = false

## The exact last direction looked in (any angle), e.g. for dodging "forward".
var _look_vector: Vector2 = Vector2.DOWN


func look_toward(look_direction: Vector2) -> void:
	if look_direction == Vector2.ZERO:
		return
	_look_vector = look_direction.normalized()
	is_looking_left = _look_vector.x < -0.01
	direction = _direction_for(_look_vector)


## The facing as a unit vector (the exact angle last looked toward).
func as_vector() -> Vector2:
	return _look_vector


## Splits the circle into 8 slices of 45°, each centred on a compass direction.
func _direction_for(look: Vector2) -> Direction:
	var degrees_below_horizontal := rad_to_deg(atan2(look.y, absf(look.x)))  # -90 (up) .. 90 (down)
	if degrees_below_horizontal > 67.5:
		return Direction.DOWN
	if degrees_below_horizontal > 22.5:
		return Direction.DOWN_SIDE
	if degrees_below_horizontal > -22.5:
		return Direction.SIDE
	if degrees_below_horizontal > -67.5:
		return Direction.UP_SIDE
	return Direction.UP
