class_name Pushback
extends RefCounted
## A shove the creature is taking (a Warden's slam, a Gruntite's ram, a gust orb): for a
## moment it slides with the push instead of following the player's orders, slowing down as
## it goes. Creature.push starts one; Unshakable decides how much of it lands.

## How fast a full push slows down, in pixels per second squared.
const FRICTION := 600.0

var _seconds_left: float = 0.0
## Scaled with the push, so a quarter push goes a quarter as far.
var _friction: float = FRICTION


## Starts a push lasting `seconds`; `share` is how much of it lands (see Unshakable).
func start(share: float, seconds: float) -> void:
	_friction = FRICTION * share
	_seconds_left = seconds


func is_active() -> bool:
	return _seconds_left > 0.0


func count_down(delta: float) -> void:
	_seconds_left = maxf(0.0, _seconds_left - delta)


## The sliding velocity one frame later.
func slowed(velocity: Vector2, delta: float) -> Vector2:
	return velocity.move_toward(Vector2.ZERO, _friction * delta)
