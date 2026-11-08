class_name Dodge
extends Node
## A quick burst of movement to get out of danger.
##
## While dodging, the creature moves at a fixed fast speed in one direction
## and can't steer. After a dodge there is a short cooldown.

## Speed during the dodge, in pixels per second.
@export var dodge_speed: float = 180.0
## How long the dodge lasts, in seconds (the dodge animation's length).
@export var dodge_duration: float = 0.33
## Seconds to wait after a dodge before the next one.
@export var cooldown: float = 0.5

var is_dodging: bool = false
var dodge_velocity: Vector2 = Vector2.ZERO

var _cooldown_remaining: float = 0.0


func _process(delta: float) -> void:
	_cooldown_remaining = maxf(0.0, _cooldown_remaining - delta)


func is_ready() -> bool:
	return not is_dodging and _cooldown_remaining == 0.0


func start(dodge_direction: Vector2) -> void:
	is_dodging = true
	dodge_velocity = dodge_direction.normalized() * dodge_speed

	await get_tree().create_timer(dodge_duration).timeout

	is_dodging = false
	_cooldown_remaining = cooldown
