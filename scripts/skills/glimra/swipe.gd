class_name Swipe
extends TimedAbility
## A quick close-range swipe in front of the creature with a small lunge: Ripfin's Fin
## Slash (a bite) and Mossdillo's Claw Swipe. Hits every enemy in a short cone.

@export var reach: float = 22.0
@export var cone_degrees: float = 90.0
@export var damage: int = 1
@export var knockback_speed: float = 80.0
## How far the creature lunges into the swipe during the wind-up, in pixels.
@export var lunge_distance: float = 5.0


func caster_velocity() -> Vector2:
	return Vector2.ZERO if _has_landed or wind_up <= 0.0 else _aim_direction * (lunge_distance / wind_up)


func _land() -> void:
	var origin := _caster.global_position
	var targets := AbilityTargets.in_cone(self, origin, _aim_direction, reach, cone_degrees)
	var trail := ElementColors.for_element(ElementStrike.element_of(_caster))
	SlashArc.spawn(_caster.get_parent(), _body_position() + _aim_direction * 6.0, _aim_direction, 10.0, ApolloPalette.WHITE, trail)
	AbilityTargets.hurt_all(_caster, targets, damage)
	AbilityTargets.knock_back_all(targets, origin, knockback_speed)
