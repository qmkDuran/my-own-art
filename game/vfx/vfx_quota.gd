class_name VfxQuota
extends RefCounted
## How much the short-lived effects may cost, set from the graphics tier: how many effect lights may shine at once
## (bolt lights, impact pops), whether projectile trails are drawn, and the particle density. A light asks for a
## slot and gives it back when it goes out, so a busy wave never floods the scene with lights.

var max_lights: int = 0
var trails: bool = true
var density: float = 1.0
var _lights_in_use: int = 0


func apply_tier(spec: Dictionary) -> void:
	max_lights = int(spec["vfx_lights"])
	trails = spec["vfx_trails"]
	density = float(spec["particle_density"])


## True (and a slot is taken) when another effect light may shine.
func take_light() -> bool:
	if _lights_in_use >= max_lights:
		return false
	_lights_in_use += 1
	return true


func give_light() -> void:
	_lights_in_use = maxi(_lights_in_use - 1, 0)


## A particle count scaled to the tier (at least one).
func count(full: int) -> int:
	return maxi(1, int(full * density))
