class_name RollingThicket
extends TimedAbility
## Mossdillo's second Active (its signature move): it curls into a ball and rolls toward the
## cursor, bowling through every enemy in the way. Rooted enemies take double damage, are
## torn free and sent flying into the enemies around them, which get hit too.
## The wind-up is the roll; it can't be hit while rolling.

const LEAVES: Array[Color] = [ApolloPalette.GREEN, ApolloPalette.GREEN_LIGHT, ApolloPalette.CORK]
const TRAIL_SECONDS := 0.04

@export var roll_distance: float = 120.0
@export var hit_radius: float = 11.0
@export var damage: int = 2
@export var rooted_multiplier: int = 2
@export var knockback_speed: float = 150.0
@export var bowled_speed: float = 320.0
## How close to a bowled enemy another must be to get knocked down by it, in pixels.
@export var bowling_radius: float = 22.0
@export var bowling_damage: int = 1

var _struck: Array[Health] = []
var _trail_left: float = 0.0
var _pass_through := EnemyPassThrough.new()


func _begin() -> void:
	_struck.clear()
	_pass_through.start(_caster as PhysicsBody2D)
	var lines := _caster.get_node_or_null("SpeedLines") as SpeedLines
	if lines != null:
		lines.play_for(wind_up, _aim_direction)


func caster_velocity() -> Vector2:
	return Vector2.ZERO if _has_landed else _aim_direction * (roll_distance / wind_up)


func makes_caster_invulnerable() -> bool:
	return not _has_landed


func can_be_cancelled() -> bool:
	return false


func cancel() -> void:
	super.cancel()
	_pass_through.stop()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not is_casting or _has_landed:
		return
	for target_health in AbilityTargets.within(self, _caster.global_position, hit_radius):
		if not _struck.has(target_health):
			_struck.append(target_health)
			_bowl(target_health)
	_trail_left -= delta
	if _trail_left <= 0.0:
		_trail_left = TRAIL_SECONDS
		PixelDebris.spray(_caster.get_parent(), _caster.global_position, LEAVES, 3, -_aim_direction, 90.0)


func _land() -> void:
	_pass_through.stop()
	Shockwave.spawn(HitFeel.RING_SCENE, _caster.get_parent(), _caster.global_position, 16.0, 0.25, ApolloPalette.GREEN_LIGHT)


func _bowl(target_health: Health) -> void:
	var enemy := target_health.get_parent() as Node2D
	var one: Array[Health] = [target_health]
	if not SetUp.has(enemy, SetUp.ROOTED):
		AbilityTargets.hurt_all(_caster, one, damage, HitFeel.Weight.LIGHT, 2)
		AbilityTargets.knock_back_all(one, _caster.global_position, knockback_speed)
		return
	SetUp.consume(enemy, SetUp.ROOTED)
	AbilityTargets.hurt_all(_caster, one, damage * rooted_multiplier, HitFeel.Weight.HEAVY, 3)
	if enemy.has_method("knock_back"):
		enemy.call("knock_back", _aim_direction * bowled_speed)
	var pins: Array[Health] = []
	for other_health in AbilityTargets.within(self, enemy.global_position, bowling_radius):
		if other_health != target_health and not _struck.has(other_health):
			pins.append(other_health)
			_struck.append(other_health)
	if not pins.is_empty():
		ElementStrike.hit(_caster, pins, bowling_damage, HitFeel.Weight.LIGHT, 2)
		AbilityTargets.knock_back_all(pins, enemy.global_position, knockback_speed)
