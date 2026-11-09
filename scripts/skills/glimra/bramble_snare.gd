class_name BrambleSnare
extends TimedAbility
## Mossdillo's Active Skill: thorny vines burst out of the ground around the cursor and
## Root every enemy there (held in place). A pure set-up: almost no damage, lots of poise.

@export var max_distance: float = 80.0
@export var radius: float = 30.0
@export var damage: int = 0
@export var poise_damage: int = 2
@export var root_seconds: float = 3.0

var _snare_spot: Vector2


func _begin() -> void:
	var aim_point := (_caster.get_node("PlayerInput") as PlayerInput).get_aim_point()
	var start := _caster.global_position
	_snare_spot = start + (aim_point - start).limit_length(max_distance)


func _land() -> void:
	BrambleVines.spawn(_caster.get_parent(), _snare_spot, radius)
	var targets := AbilityTargets.within(self, _snare_spot, radius)
	for target_health in targets:
		SetUp.apply(target_health, SetUp.ROOTED, root_seconds)
	ElementStrike.hit(_caster, targets, damage, HitFeel.Weight.LIGHT, poise_damage)
