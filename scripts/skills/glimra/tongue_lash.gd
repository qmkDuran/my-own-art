class_name TongueLash
extends TimedAbility
## Toxlop's basic attack: the tongue whips out toward the cursor, hurting and poisoning every
## enemy along it, with a small shove. Reuses the enemy toad's tongue (ToadTongue).

@export var tongue: ToadTongue
## How far the tongue reaches, in pixels.
@export var reach: float = 34.0
## How close to the tongue an enemy's feet must be to get hit, in pixels.
@export var hit_radius: float = 8.0
@export var damage: int = 1
@export var knockback_speed: float = 90.0

@export_group("Poison")
@export var poison_per_tick: int = 1
@export var seconds_between_ticks: float = 1.0
@export var poison_seconds: float = 2.0


func _begin() -> void:
	tongue.lash(_aim_direction, reach, duration)


func cancel() -> void:
	super.cancel()
	tongue.retract_now()


func _land() -> void:
	var start := _caster.global_position
	var targets := AbilityTargets.along(self, start, start + _aim_direction * reach, hit_radius)
	AbilityTargets.hurt_all(_caster, targets, damage)
	for target_health in targets:
		Poisoned.apply_to(target_health, poison_per_tick, seconds_between_ticks, poison_seconds)
	AbilityTargets.knock_back_all(targets, start, knockback_speed)
