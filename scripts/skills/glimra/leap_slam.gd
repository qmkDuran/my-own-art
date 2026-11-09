class_name LeapSlam
extends TimedAbility
## Toxlop's signature: a big frog leap toward the cursor (enemy attacks pass under it), then
## a slam that hurts and throws back every enemy around the landing spot.
## The wind-up is the time in the air.

## Farthest the leap goes, in pixels.
@export var max_distance: float = 64.0
## How high the leap peaks, in pixels.
@export var leap_height: float = 14.0
@export var slam_radius: float = 30.0
@export var damage: int = 2
@export var knockback_speed: float = 210.0
## The ring shown when it lands.
@export var ring_scene: PackedScene
@export var screen_shake: ScreenShake

var _leap_speed: float = 0.0


func _begin() -> void:
	var player_input := _caster.get_node("PlayerInput") as PlayerInput
	var leap_distance := minf(max_distance, _caster.global_position.distance_to(player_input.get_aim_point()))
	_leap_speed = leap_distance / wind_up


func caster_velocity() -> Vector2:
	return Vector2.ZERO if _has_landed else _aim_direction * _leap_speed


func caster_lift() -> float:
	return 0.0 if _has_landed else sin(PI * _wind_up_progress()) * leap_height


func makes_caster_invulnerable() -> bool:
	return not _has_landed


## Once airborne you're committed (a dodge can't cut a leap short).
func can_be_cancelled() -> bool:
	return false


func _land() -> void:
	var landing := _caster.global_position
	var targets := AbilityTargets.within(self, landing, slam_radius)
	AbilityTargets.hurt_all(_caster, targets, damage)
	AbilityTargets.knock_back_all(targets, landing, knockback_speed)
	if ring_scene != null:
		Shockwave.spawn(ring_scene, _caster.get_parent(), landing, slam_radius, 0.3, ApolloPalette.GREEN_LIGHT)
		Shockwave.spawn(ring_scene, _caster.get_parent(), landing, slam_radius * 0.6, 0.22, ApolloPalette.LIME_PALE)
	if screen_shake != null:
		screen_shake.shake(2.0, 0.16)
