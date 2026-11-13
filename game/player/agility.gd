class_name Agility
extends RefCounted
## The player's quick moves, from data/tuning.json "agility": a short, grounded dash (a burst that eases out over
## about 0.2 s, no hang time) and a jump with a good arc (rising under normal gravity, falling under heavier
## gravity), coyote time (a jump still works just after stepping off an edge) and a jump buffer (a press just
## before landing still jumps). Reports landings so the body can play its landing feel.

var _dash_left: float = 0.0
var _dash_cooldown: float = 0.0
var _dash_direction: Vector3 = Vector3.ZERO
var _coyote: float = 0.0
var _buffer: float = 0.0
var _airborne: bool = false


func start_dash(direction: Vector3) -> bool:
	if _dash_cooldown > 0.0:
		return false
	_dash_direction = Vector3(direction.x, 0.0, direction.z).normalized()
	_dash_left = Tuning.f("agility", "dash_seconds")
	_dash_cooldown = Tuning.f("agility", "dash_cooldown")
	return true


func request_jump() -> void:
	_buffer = Tuning.f("agility", "jump_buffer")


func is_dashing() -> bool:
	return _dash_left > 0.0


func is_airborne() -> bool:
	return _airborne


## The dash velocity this frame (strongest at the start, easing out to nothing).
func dash_velocity() -> Vector3:
	var share: float = _dash_left / Tuning.f("agility", "dash_seconds")
	return _dash_direction * Tuning.f("agility", "dash_speed") * share * share


## Advances the timers and returns the new vertical speed; true in "jumped" when a jump starts this frame.
func vertical(delta: float, on_floor: bool, vertical_speed: float, events: Dictionary) -> float:
	_dash_left = maxf(_dash_left - delta, 0.0)
	_dash_cooldown = maxf(_dash_cooldown - delta, 0.0)
	_buffer = maxf(_buffer - delta, 0.0)
	_coyote = Tuning.f("agility", "coyote_seconds") if on_floor else maxf(_coyote - delta, 0.0)
	events["landed"] = on_floor and _airborne and vertical_speed <= 0.0
	if events["landed"]:
		_airborne = false
	if _buffer > 0.0 and _coyote > 0.0:
		_buffer = 0.0
		_coyote = 0.0
		_airborne = true
		events["jumped"] = true
		return sqrt(2.0 * Tuning.f("player", "gravity") * Tuning.f("agility", "jump_height"))
	if on_floor and vertical_speed <= 0.0:
		return 0.0
	_airborne = _airborne or not on_floor
	var fall: float = Tuning.f("agility", "fall_gravity_scale") if vertical_speed < 0.0 else 1.0
	return vertical_speed - Tuning.f("player", "gravity") * fall * delta
