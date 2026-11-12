class_name Stealth
extends RefCounted
## Whether a creature is hidden: inside a bush or tall grass, and not just revealed by its own attack or snare.

var _spots: Array[HidingSpot] = []
var _reveal_left: float = 0.0


func enter(spot: HidingSpot) -> void:
	if not _spots.has(spot):
		_spots.append(spot)


func leave(spot: HidingSpot) -> void:
	_spots.erase(spot)


func reveal() -> void:
	_reveal_left = Tuning.f("stealth", "reveal_time")


func tick(delta: float) -> void:
	_reveal_left = maxf(0.0, _reveal_left - delta)


func in_cover() -> bool:
	return not _spots.is_empty()


func is_hidden() -> bool:
	return in_cover() and _reveal_left <= 0.0


func current_spot() -> HidingSpot:
	return _spots.back() if in_cover() else null
