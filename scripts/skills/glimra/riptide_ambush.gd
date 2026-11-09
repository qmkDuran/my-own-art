class_name RiptideAmbush
extends TimedAbility
## Ripfin's second Active (its signature move): it vanishes underground and bursts up under
## every Soaked enemy in turn, biting each and throwing it up into the air (Airborne). With
## no soaked enemy around it bursts up under the nearest one. Can't be hit meanwhile.

const SPRAY: Array[Color] = [ApolloPalette.CORK, ApolloPalette.CORK_DARK, ApolloPalette.SKY, ApolloPalette.SKY_LIGHT, ApolloPalette.WHITE]
const MAX_TARGETS := 6
const RECOVERY := 0.25

@export var reach: float = 130.0
## Seconds per burst: under the ground, then up.
@export var seconds_per_burst: float = 0.2
@export var damage: int = 2
@export var launch_seconds: float = 1.6

var _queue: Array[Health] = []
var _bursts_done: int = 0

var _pass_through := EnemyPassThrough.new()


func _begin() -> void:
	_queue = _soaked_targets()
	if _queue.is_empty():
		var nearest := _nearest_target()
		if nearest != null:
			_queue.append(nearest)
	_bursts_done = 0
	wind_up = 0.0
	duration = _queue.size() * seconds_per_burst + RECOVERY
	_pass_through.start(_caster as PhysicsBody2D)


func makes_caster_invulnerable() -> bool:
	return is_casting and _bursts_done < _queue.size()


func can_be_cancelled() -> bool:
	return false


func cancel() -> void:
	super.cancel()
	_pass_through.stop()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not is_casting:
		return
	var due := mini(_queue.size(), floori(_time_casting / seconds_per_burst + 0.5))
	while _bursts_done < due:
		_burst_under(_queue[_bursts_done])
		_bursts_done += 1
	if _bursts_done >= _queue.size() and _time_casting >= duration - RECOVERY:
		_pass_through.stop()


func _burst_under(target_health: Health) -> void:
	if target_health == null or target_health.is_dead():
		return
	var enemy := target_health.get_parent() as Node2D
	_caster.global_position = (enemy.global_position + Vector2(0, 3)).round()
	(_caster as FrontViewCreature).animator.replay_animation("signature")
	var world := _caster.get_parent()
	var spray := PixelDebris.spray(world, enemy.global_position, SPRAY, 22, Vector2.UP, 90.0)
	spray.speed_range = Vector2(60, 150)
	var one: Array[Health] = [target_health]
	AbilityTargets.hurt_all(_caster, one, damage, HitFeel.Weight.HEAVY, 2)
	SetUp.apply(target_health, SetUp.LAUNCHED, launch_seconds)


func _soaked_targets() -> Array[Health]:
	var soaked: Array[Health] = []
	for target_health in AbilityTargets.within(self, _caster.global_position, reach):
		if SetUp.has(target_health.get_parent(), SetUp.SOAKED) and soaked.size() < MAX_TARGETS:
			soaked.append(target_health)
	return soaked


func _nearest_target() -> Health:
	var nearest: Health = null
	var nearest_distance := reach
	for target_health in AbilityTargets.within(self, _caster.global_position, reach):
		var distance := (target_health.get_parent() as Node2D).global_position.distance_to(_caster.global_position)
		if distance < nearest_distance:
			nearest = target_health
			nearest_distance = distance
	return nearest


func guide_line() -> String:
	return "Bursts up under every Soaked enemy within %d px: %d dmg each, throws them Airborne (%.1f s)." % [reach, damage, launch_seconds]


func set_up_status() -> String:
	return SetUp.LAUNCHED
