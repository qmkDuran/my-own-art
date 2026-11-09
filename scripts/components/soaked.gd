class_name Soaked
extends SlowingEffect
## Soaked (the Tide element), e.g. from a Brinelob's claw clap: heavy with brine, the target
## walks slower for a moment. See SlowingEffect; Ash Guard blocks it (see StatusResistance).

## The child name a target's soak goes by.
const NODE_NAME := "Soaked"


## Soaks the target with `target_health`: it keeps `kept_speed_share` of its speed for `seconds`.
static func apply_to(target_health: Health, kept_speed_share: float, seconds: float) -> bool:
	return _apply(target_health, NODE_NAME, seconds, func() -> StatusEffect: return Soaked.new(kept_speed_share))


func _init(kept_speed_share: float) -> void:
	super._init(kept_speed_share, StatusColors.SOAK)
