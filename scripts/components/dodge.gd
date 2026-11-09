class_name Dodge
extends Node
## A quick leap to get out of danger.
##
## While dodging, the creature moves at a fixed fast speed in one direction
## and can't steer. It rises and falls in an arc, like a kangaroo bound.
## After a dodge there is a short cooldown.

## The child node name the player's Dodge goes by.
const NODE_NAME := "Dodge"

## Speed during the dodge, in pixels per second.
@export var dodge_speed: float = 180.0
## How long the dodge lasts, in seconds.
@export var dodge_duration: float = 0.33
## How high the leap peaks, in pixels.
@export var leap_height: float = 7.0
## Seconds to wait after a dodge before the next one.
@export var cooldown: float = 0.5

var is_dodging: bool = false
var dodge_velocity: Vector2 = Vector2.ZERO

var _time_dodging: float = 0.0
var _cooldown_remaining: float = 0.0


func _physics_process(delta: float) -> void:
	if is_dodging:
		_advance_dodge(delta)
	else:
		_cooldown_remaining = maxf(0.0, _cooldown_remaining - delta)


func is_ready() -> bool:
	return not is_dodging and _cooldown_remaining == 0.0


func start(dodge_direction: Vector2) -> void:
	is_dodging = true
	_time_dodging = 0.0
	dodge_velocity = dodge_direction.normalized() * dodge_speed


## Height above the ground right now: 0 at take-off and landing, highest halfway.
func current_height() -> float:
	if not is_dodging:
		return 0.0
	return sin(PI * _progress()) * leap_height


## How far through the dodge we are, from 0.0 to 1.0.
func _progress() -> float:
	return clampf(_time_dodging / dodge_duration, 0.0, 1.0)


func _advance_dodge(delta: float) -> void:
	_time_dodging += delta
	if _time_dodging >= dodge_duration:
		_finish_dodge()


func _finish_dodge() -> void:
	is_dodging = false
	dodge_velocity = Vector2.ZERO
	_cooldown_remaining = cooldown
