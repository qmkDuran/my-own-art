class_name MagicStats
extends RefCounted
## What the passives add up to: area, cooldown and speed bonuses (shares, 0.12 = +12%) and extra pickup reach.
## Attacks read their final numbers through here.

const FASTEST_SHARE: float = 0.2

var area: float = 0.0
var cooldown: float = 0.0
var speed: float = 0.0


func area_scale() -> float:
	return 1.0 + area


## Cooldowns shrink with Steady Hands (never below a fifth).
func cooldown_scale() -> float:
	return maxf(1.0 - cooldown, FASTEST_SHARE)


func speed_scale() -> float:
	return 1.0 + speed
