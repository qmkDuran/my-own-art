class_name Health
extends RefCounted
## Life points with slow regeneration once a creature has been left alone for a while (same rule for both sides).

var maximum: float
var current: float
var _regen_delay: float
var _regen_rate: float
var _since_hurt: float = 0.0


func _init(max_points: float, regen_delay: float, regen_rate: float) -> void:
	maximum = max_points
	current = max_points
	_regen_delay = regen_delay
	_regen_rate = regen_rate


func hurt(amount: float) -> void:
	current = maxf(0.0, current - amount)
	_since_hurt = 0.0


func tick(delta: float) -> void:
	_since_hurt += delta
	if not is_dead() and _since_hurt >= _regen_delay:
		current = minf(maximum, current + _regen_rate * delta)


func fraction() -> float:
	return current / maximum


func is_dead() -> bool:
	return current <= 0.0
