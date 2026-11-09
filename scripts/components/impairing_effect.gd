class_name ImpairingEffect
extends StatusEffect
## A status effect that takes control of the target's movement for a moment (Staggered,
## Buffeted; later slows and roots). It runs for a fixed length, then the target is immune
## to it for `IMMUNITY_SECONDS`, so chained hits can't lock the player down.

## Seconds after one of these ends during which the same effect can't land again.
const IMMUNITY_SECONDS := 2.0

var _length: float = 0.0
var _seconds_left: float = 0.0


func _init() -> void:
	immunity_seconds = IMMUNITY_SECONDS


## Starts the effect for `seconds`.
func start(seconds: float) -> void:
	_length = seconds
	_seconds_left = seconds


## Starts it again for `seconds`, unless more than that is still left.
func extend_to(seconds: float) -> void:
	start(maxf(seconds, seconds_left()))


func is_active() -> bool:
	return _seconds_left > 0.0


func seconds_left() -> float:
	return maxf(0.0, _seconds_left)


func full_length() -> float:
	return _length


func _advance(delta: float) -> void:
	_seconds_left -= delta


func consume() -> void:
	_seconds_left = 0.0
