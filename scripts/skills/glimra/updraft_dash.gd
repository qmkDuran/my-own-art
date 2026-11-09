class_name UpdraftDash
extends TimedAbility
## Zephoot's signature: an updraft bursts where it stands (hurting and scattering enemies
## around it), then it rides the wind toward the cursor, untouchable while it flies.
## The wind-up is the dash itself.

@export var dash_distance: float = 76.0
## How high it rises during the dash, in pixels.
@export var rise_height: float = 6.0
@export var burst_radius: float = 26.0
@export var damage: int = 1
@export var knockback_speed: float = 180.0
## The rings shown at take-off and arrival.
@export var ring_scene: PackedScene


func _begin() -> void:
	var take_off := _caster.global_position
	var targets := AbilityTargets.within(self, take_off, burst_radius)
	AbilityTargets.hurt_all(_caster, targets, damage)
	AbilityTargets.knock_back_all(targets, take_off, knockback_speed)
	_ring(take_off, burst_radius, ApolloPalette.SKY_LIGHT)
	GaleCone.spawn(_caster.get_parent(), _body_position(), Vector2.UP, burst_radius * 0.8, 120.0)


func caster_velocity() -> Vector2:
	return Vector2.ZERO if _has_landed else _aim_direction * (dash_distance / wind_up)


func caster_lift() -> float:
	return 0.0 if _has_landed else sin(PI * _wind_up_progress()) * rise_height


func makes_caster_invulnerable() -> bool:
	return not _has_landed


func can_be_cancelled() -> bool:
	return false


func _land() -> void:
	_ring(_caster.global_position, 10.0, ApolloPalette.WHITE)


func _ring(at: Vector2, radius: float, color: Color) -> void:
	if ring_scene != null:
		Shockwave.spawn(ring_scene, _caster.get_parent(), at, radius, 0.25, color)
