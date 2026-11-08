class_name StateTimer
extends RefCounted
## The current state of an enemy's state machine and how long it has been in it.
##
## Each state can have a length; once it has run that long, the state is "over" and the
## enemy decides what to do next. `state` holds a value of the enemy's own State enum.

var state: int = 0
## Seconds since the current state was entered.
var elapsed: float = 0.0
## Seconds the current state is meant to last.
var length: float = 0.0


## Switches to `new_state`, meant to last `new_length` seconds, and restarts the clock.
func enter(new_state: int, new_length: float) -> void:
	state = new_state
	elapsed = 0.0
	length = new_length


func advance(delta: float) -> void:
	elapsed += delta


func is_over() -> bool:
	return elapsed >= length


## How far through the current state we are, from 0.0 to 1.0.
func progress() -> float:
	return clampf(elapsed / length, 0.0, 1.0)


func seconds_left() -> float:
	return length - elapsed
