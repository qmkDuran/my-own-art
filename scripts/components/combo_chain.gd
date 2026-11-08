class_name ComboChain
extends RefCounted
## Where an attacker is in its combo (e.g. jab, jab, Spinning Hook), and how long it has
## been since the last attack.
##
## Forgiving on purpose: only the time window resets the chain. Kills, switching targets,
## walking, being hit or shoved, and cancelling an attack (e.g. with a dodge) never do.
## An attack cancelled before its hit landed is simply tried again on the next press,
## so a dodge never drops (or skips) a step.

## How many attacks make one full chain (jabs plus the finisher).
var length: int
## Seconds without attacking after which the chain starts again from the first attack.
var reset_time: float

var _next_step: int = 0
var _current_step: int = 0
var _landed_steps: int = 0
var _seconds_idle: float = 0.0


func _init(chain_length: int, chain_reset_time: float) -> void:
	length = maxi(1, chain_length)
	reset_time = chain_reset_time


## Changes how many attacks make the chain (e.g. once the finisher is learned or
## unlearned). A step past the new end starts the chain over.
func resize(chain_length: int) -> void:
	length = maxi(1, chain_length)
	if _next_step >= length:
		_next_step = 0
	_landed_steps = mini(_landed_steps, length)


## Starts the next attack of the chain and returns its step (0 = the first attack).
func begin_attack() -> int:
	_current_step = _next_step
	if _current_step == 0:
		_landed_steps = 0
	_next_step = (_current_step + 1) % length
	_seconds_idle = 0.0
	return _current_step


## The attack in progress has landed its hit (whether or not it struck anything).
func note_landed() -> void:
	_landed_steps = _current_step + 1


## The attack in progress was cut short before its hit landed: the next press retries it.
func note_cancelled_before_landing() -> void:
	_next_step = _current_step


## Counts time between attacks; once the window runs out, the chain starts over.
func wait(delta: float) -> void:
	_seconds_idle += delta
	if _seconds_idle >= reset_time:
		_next_step = 0
		_landed_steps = 0


## How many attacks of the current chain have landed (0 when the chain is fresh).
func landed_steps() -> int:
	return _landed_steps


## True once the last attack of the chain (the finisher) has landed.
func is_complete() -> bool:
	return _landed_steps >= length


## Seconds since the last attack ended (0 while attacking).
func seconds_idle() -> float:
	return _seconds_idle
