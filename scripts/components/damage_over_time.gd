class_name DamageOverTime
extends StatusEffect
## A status effect that hurts its target every `tick_interval` seconds until it runs out
## (Burning, Poisoned).
##
## Applying it again refreshes it to its full length (no stacking yet) but keeps the tick
## rhythm, so quick re-applications never push the next tick back.
## Ticks use Health.take_tick_damage with the effect's `damage_type`: no knockback, no hit
## flash, no interrupted attack, just a damage number in the element's colour.

## Damage each tick deals.
var damage_per_tick: int = 0
## Seconds between ticks.
var tick_interval: float = 1.0
## What the ticks count as (sets the colour of their numbers).
var damage_type: Health.DamageType = Health.DamageType.BURN

## The effect's full length, in seconds, as last applied.
var _duration: float = 0.0
var _ticks_left: int = 0
var _seconds_to_next_tick: float = 0.0


func _init(interval: float, type: Health.DamageType) -> void:
	tick_interval = interval
	damage_type = type
	_seconds_to_next_tick = interval


## The effect's numbers, at full length again. A weaker re-application never weakens it.
func refresh(damage: int, duration: float) -> void:
	damage_per_tick = maxi(damage_per_tick, damage)
	_duration = maxf(_duration, duration)
	_ticks_left = maxi(_ticks_left, ceili(duration / tick_interval - 0.001))


func is_active() -> bool:
	return _ticks_left > 0


func seconds_left() -> float:
	return maxf(0.0, (_ticks_left - 1) * tick_interval + _seconds_to_next_tick)


func full_length() -> float:
	return _duration


func _advance(delta: float) -> void:
	_seconds_to_next_tick -= delta
	if _seconds_to_next_tick > 0.0:
		return
	_seconds_to_next_tick += tick_interval
	_ticks_left -= 1
	_health.take_tick_damage(damage_per_tick, damage_type)


func consume() -> void:
	_ticks_left = 0
