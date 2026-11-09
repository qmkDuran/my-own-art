class_name GalePush
extends TimedAbility
## Zephoot's skill: a blast of wind in a cone in front of it that hurts a little and throws
## every enemy in it far back. The "get off me" button of a ranged creature.

@export var reach: float = 44.0
@export var cone_degrees: float = 75.0
@export var damage: int = 1
@export var knockback_speed: float = 260.0


func _land() -> void:
	var origin := _caster.global_position
	var targets := AbilityTargets.in_cone(self, origin, _aim_direction, reach, cone_degrees)
	AbilityTargets.hurt_all(_caster, targets, damage)
	AbilityTargets.knock_back_all(targets, origin, knockback_speed)
	GaleCone.spawn(_caster.get_parent(), _body_position(), _aim_direction, reach, cone_degrees)


func guide_line() -> String:
	return "A cone of wind (%d px, %d°): %d dmg and throws every enemy in it far back." % [reach, cone_degrees, damage]
