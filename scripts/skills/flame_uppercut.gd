class_name FlameUppercut
extends SkillAction
## Flame Uppercut: a rising punch that bursts into a fan of flame in front of the caster,
## hitting every enemy in the arc hard and knocking them away.
##
## Timeline: a short wind-up (a dodge can still cancel it), then the burst lands all at once,
## then a short recovery with feet planted. Keep the "uppercut" animation's frame timings
## (CreatureAnimator.ANIMATION_SETTINGS) in sync with `wind_up` and `duration`.

## Seconds from pressing the key to the flame bursting out (the cocked-fist frame).
@export var wind_up: float = 0.16
## Seconds the whole move takes, start to recovery.
@export var duration: float = 0.45
## How far the flame reaches from the caster's feet, in pixels.
@export var reach: float = 26.0
## How wide the flame fans out, in degrees.
@export var arc_degrees: float = 100.0
## Damage dealt to each enemy in the arc.
@export var damage: int = 3
## Speed enemies are thrown back at, in pixels per second (a jab gives about 120).
@export var knockback_speed: float = 260.0
## How far the caster steps into the punch during the wind-up, in pixels.
@export var lunge_distance: float = 3.0
## How high the caster's sprite rises with the punch, in pixels.
@export var rise_height: float = 3.0
## Seconds the rise lasts after the burst (up and back down).
@export var rise_time: float = 0.26
## Height of the fist above the caster's feet, where the flame starts (negative is up).
@export var fist_height: float = -7.0
## Group whose members the flame can hurt (each needs a child node named "Health").
@export var target_group: String = "enemies"
## Enemies whose body is this close to the arc's edge still get hit, in pixels.
@export var target_radius: float = 4.0

@export_group("Feel")
@export var screen_shake: ScreenShake
## Camera shake when the flame bursts: strength in pixels and length in seconds.
@export var shake_strength: float = 2.0
@export var shake_duration: float = 0.14

var _caster: Node2D = null
var _aim_direction: Vector2 = Vector2.RIGHT
var _time_casting: float = 0.0
var _has_burst: bool = false


func _physics_process(delta: float) -> void:
	if is_casting:
		_advance(delta)


func start(caster: Node2D, aim_direction: Vector2) -> void:
	super.start(caster, aim_direction)
	_caster = caster
	_aim_direction = aim_direction.normalized()
	_time_casting = 0.0
	_has_burst = false


## A dodge can cancel the wind-up, but once the flame is out you're committed.
func can_be_cancelled() -> bool:
	return not _has_burst


func caster_velocity() -> Vector2:
	if _has_burst:
		return Vector2.ZERO
	return _aim_direction * (lunge_distance / wind_up)


## The sprite pops up a few pixels with the punch and lands again: the "uppercut".
func caster_lift() -> float:
	if not _has_burst:
		return 0.0
	var rise_progress := clampf((_time_casting - wind_up) / rise_time, 0.0, 1.0)
	return sin(PI * rise_progress) * rise_height


func _advance(delta: float) -> void:
	_time_casting += delta
	if not _has_burst and _time_casting >= wind_up:
		_has_burst = true
		_burst()
	if _time_casting >= duration:
		is_casting = false


func _burst() -> void:
	_spawn_flame_arc()
	_hit_enemies_in_arc()
	if screen_shake != null:
		screen_shake.shake(shake_strength, shake_duration)


func _spawn_flame_arc() -> void:
	var flame := FlameArc.new()
	# Added to the world, not the caster, so the flame stays where it burst.
	_caster.get_parent().add_child(flame)
	flame.global_position = (_caster.global_position + Vector2(0, fist_height)).round()
	flame.play(_aim_direction, reach, arc_degrees)


func _hit_enemies_in_arc() -> void:
	for target: Node2D in get_tree().get_nodes_in_group(target_group):
		if not _is_in_arc(target.global_position):
			continue
		var target_health: Health = target.get_node_or_null("Health")
		if target_health == null:
			continue
		target_health.take_damage(damage, _caster.global_position)
		_knock_back(target)


## Measured from the caster's feet to the target's feet (like the jab), so height doesn't matter.
func _is_in_arc(target_position: Vector2) -> bool:
	var to_target := target_position - _caster.global_position
	var distance := to_target.length()
	if distance > reach + target_radius:
		return false
	# Enemies right on top of the caster always get hit, whatever the angle.
	if distance <= target_radius:
		return true
	var half_arc := deg_to_rad(arc_degrees) / 2.0
	var angle_off_aim := absf(_aim_direction.angle_to(to_target))
	# The body's width lets enemies at the arc's edge count, a bit more when close.
	var edge_allowance := asin(minf(1.0, target_radius / distance))
	return angle_off_aim <= half_arc + edge_allowance


## Enemies that know how (a `knock_back(velocity)` method) are thrown away from the caster,
## harder than their usual hit reaction. Others keep their normal reaction.
func _knock_back(target: Node2D) -> void:
	if not target.has_method("knock_back"):
		return
	var away := target.global_position - _caster.global_position
	if away.length() < 0.1:
		away = _aim_direction
	target.call("knock_back", away.normalized() * knockback_speed)
