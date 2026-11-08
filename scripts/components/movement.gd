class_name Movement
extends Node
## Works out how fast a body should be moving.
##
## Speeds up toward the direction it is given, and slows to a stop when given
## no direction. It never moves anything itself; the owner applies the result.

## Fastest the body can move, in pixels per second.
@export var top_speed: float = 60.0
## How quickly the body reaches top speed, in pixels per second squared.
@export var acceleration: float = 600.0
## How quickly the body stops when there is no input, in pixels per second squared.
@export var friction: float = 800.0


func calculate_velocity(current_velocity: Vector2, move_direction: Vector2, delta: float) -> Vector2:
	if move_direction == Vector2.ZERO:
		return _slow_down(current_velocity, delta)
	return _speed_up(current_velocity, move_direction, delta)


func _slow_down(current_velocity: Vector2, delta: float) -> Vector2:
	return current_velocity.move_toward(Vector2.ZERO, friction * delta)


func _speed_up(current_velocity: Vector2, move_direction: Vector2, delta: float) -> Vector2:
	var target_velocity := move_direction * top_speed
	return current_velocity.move_toward(target_velocity, acceleration * delta)
