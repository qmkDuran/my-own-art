class_name Undertow
extends TimedAbility
## Ripfin's Active Skill: it dives into the ground (only its fin shows, it can't be hit),
## swims to the enemy nearest the cursor, surfaces behind it and bites; the splash leaves
## every enemy around Soaked.
## The wind-up is the swim; its length follows the distance.

const SPRAY: Array[Color] = [ApolloPalette.CORK, ApolloPalette.CORK_DARK, ApolloPalette.SKY, ApolloPalette.SKY_LIGHT]
const BEHIND_DISTANCE := 12.0
const SURFACE_ANIMATION := "basic"
const SWIM_ANIMATION := "submerged"
const RECOVERY := 0.25
## Seconds between the dirt puffs its fin kicks up.
const WAKE_SECONDS := 0.05

## How far it looks for prey from the cursor, and the farthest it swims, in pixels.
@export var search_radius: float = 60.0
@export var max_distance: float = 120.0
@export var swim_speed: float = 300.0
@export var damage: int = 2
@export var soak_seconds: float = 4.0
@export var bite_radius: float = 18.0
## The splash when it surfaces soaks every enemy this close.
@export var soak_radius: float = 34.0

var _surface_spot: Vector2
var _wake_left: float = 0.0

var _pass_through := EnemyPassThrough.new()


func _begin() -> void:
	animation_name = SWIM_ANIMATION
	var aim_point := (_caster.get_node("PlayerInput") as PlayerInput).get_aim_point()
	_surface_spot = _spot_behind_prey(aim_point)
	wind_up = maxf(0.08, _caster.global_position.distance_to(_surface_spot) / swim_speed)
	duration = wind_up + RECOVERY
	_pass_through.start(_caster as PhysicsBody2D)
	_splash(_caster.global_position, 12)


func caster_velocity() -> Vector2:
	if _has_landed:
		return Vector2.ZERO
	return (_surface_spot - _caster.global_position) / maxf(0.016, wind_up - _time_casting)


func makes_caster_invulnerable() -> bool:
	return not _has_landed


func can_be_cancelled() -> bool:
	return false


func cancel() -> void:
	super.cancel()
	_pass_through.stop()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if is_casting and not _has_landed:
		_wake_left -= delta
		if _wake_left <= 0.0:
			_wake_left = WAKE_SECONDS
			var wake := PixelDebris.spray(_caster.get_parent(), _caster.global_position, SPRAY, 3, Vector2.UP, 160.0)
			wake.speed_range = Vector2(15, 40)


func _land() -> void:
	_pass_through.stop()
	_caster.global_position = _surface_spot.round()
	animation_name = SURFACE_ANIMATION
	_splash(_surface_spot, 22)
	for splashed in AbilityTargets.within(self, _surface_spot, soak_radius):
		SetUp.apply(splashed, SetUp.SOAKED, soak_seconds)
	var targets := AbilityTargets.within(self, _surface_spot, bite_radius)
	AbilityTargets.hurt_all(_caster, targets, damage, HitFeel.Weight.HEAVY, 2)
	var lines := _caster.get_node_or_null("SpeedLines") as SpeedLines
	if lines != null:
		lines.play_for(0.12, Vector2.UP)


## Behind the enemy nearest `aim_point` (as seen from Ripfin), or toward the cursor.
func _spot_behind_prey(aim_point: Vector2) -> Vector2:
	var start := _caster.global_position
	var prey: Node2D = null
	var best := search_radius
	for target_health in AbilityTargets.within(self, aim_point, search_radius):
		var enemy := target_health.get_parent() as Node2D
		var distance := enemy.global_position.distance_to(aim_point)
		if distance <= best and enemy.global_position.distance_to(start) <= max_distance:
			prey = enemy
			best = distance
	if prey == null:
		return start + (aim_point - start).limit_length(max_distance)
	var through := (prey.global_position - start)
	through = through.normalized() if through.length() > 1.0 else Vector2.RIGHT
	return prey.global_position + through * BEHIND_DISTANCE


func _splash(at: Vector2, amount: int) -> void:
	var spray := PixelDebris.spray(_caster.get_parent(), at, SPRAY, amount, Vector2.UP, 120.0)
	spray.speed_range = Vector2(40, 120)
	Shockwave.spawn(HitFeel.RING_SCENE, _caster.get_parent(), at, 12.0, 0.25, ApolloPalette.SKY_LIGHT)

