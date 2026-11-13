class_name Effects
extends RefCounted
## Timed effects on a creature from moves: multipliers (speed, slow, damage_out, damage_in, loud, hearing) and flags
## (shield, rooted, steady, blind, confused, crit). A newer effect of the same name replaces the older one.

var _active: Dictionary = {}


func add(effect: String, value: float, duration: float) -> void:
	_active[effect] = { "value": value, "left": duration }


func tick(delta: float) -> void:
	for effect: String in _active.keys():
		_active[effect]["left"] = float(_active[effect]["left"]) - delta
		if float(_active[effect]["left"]) <= 0.0:
			_active.erase(effect)


func has(effect: String) -> bool:
	return _active.has(effect)


## The effect's value, or `otherwise` when it is not active.
func value(effect: String, otherwise: float) -> float:
	return float(_active[effect]["value"]) if _active.has(effect) else otherwise


## Uses up a one-shot effect (a critical hit); returns its value, or 1 when there was none.
func consume(effect: String) -> float:
	var amount: float = value(effect, 1.0)
	_active.erase(effect)
	return amount


func time_left(effect: String) -> float:
	return float(_active[effect]["left"]) if _active.has(effect) else 0.0


func names() -> Array:
	return _active.keys()


func clear() -> void:
	_active.clear()
