class_name Stealth
extends RefCounted
## Whether a creature is hidden, the same rule for both creatures. In a bush, tall grass, smoke or a tree crown it is
## hidden beyond a short reveal distance (unless the watcher saw it go in); underground or underwater it is hidden
## at any distance. Its own attacks reveal it for a moment, and a sense move (Echo Pulse) exposes it.

var _spots: Array[HidingSpot] = []
var _reveal_left: float = 0.0
var _exposed_left: float = 0.0
var _deep: bool = false
var _perched: bool = false


func enter(spot: HidingSpot) -> void:
	if not _spots.has(spot):
		_spots.append(spot)


func leave(spot: HidingSpot) -> void:
	_spots.erase(spot)


func reveal() -> void:
	_reveal_left = Tuning.f("stealth", "reveal_time")


## Shown to everyone for a while, whatever cover it is in (Echo Pulse).
func expose(duration: float) -> void:
	_exposed_left = maxf(_exposed_left, duration)


func set_deep(deep: bool) -> void:
	_deep = deep


func set_perched(perched: bool) -> void:
	_perched = perched


func tick(delta: float) -> void:
	_reveal_left = maxf(0.0, _reveal_left - delta)
	_exposed_left = maxf(0.0, _exposed_left - delta)


func in_cover() -> bool:
	return current_spot() != null or _perched


func is_exposed() -> bool:
	return _exposed_left > 0.0


func is_hidden() -> bool:
	if is_exposed():
		return false
	return _deep or (in_cover() and _reveal_left <= 0.0)


## Hidden from a watcher this far away (deep cover hides at any distance; light cover beyond the reveal distance).
func hides_at(distance: float) -> bool:
	return is_hidden() and (_deep or distance > Tuning.f("stealth", "reveal_distance"))


func current_spot() -> HidingSpot:
	for spot: HidingSpot in _spots:
		if spot.conceals():
			return spot
	return null
