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
## The swim never takes less than this, so even a dive in place reads as one.
const MIN_SWIM_SECONDS := 0.08
## Shortest time left the swim speed is worked out over (about one frame), so it never
## divides by zero on the last frame.
const MIN_STEER_SECONDS := 0.016
## Seconds between the dirt puffs its fin kicks up.
const WAKE_SECONDS := 0.05
const WAKE_PIXELS := 3
const DIVE_SPLASH_PIXELS := 12
const SURFACE_SPLASH_PIXELS := 22
const SPLASH_RING_RADIUS := 12.0
const SURFACE_SPEED_LINES_SECONDS := 0.12
## Poise each bite drains.
const POISE_DAMAGE := 2

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
	_surface_spot = _spot_behind_prey(_aim_point())
	wind_up = maxf(MIN_SWIM_SECONDS, _caster.global_position.distance_to(_surface_spot) / swim_speed)
	duration = wind_up + RECOVERY
	_pass_through.start(_caster)
	_splash(_caster.global_position, DIVE_SPLASH_PIXELS)


func caster_velocity() -> Vector2:
	if _has_landed:
		return Vector2.ZERO
	return (_surface_spot - _caster.global_position) / maxf(MIN_STEER_SECONDS, wind_up - _time_casting)


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
		_kick_up_wake(delta)


func _kick_up_wake(delta: float) -> void:
	_wake_left -= delta
	if _wake_left > 0.0:
		return
	_wake_left = WAKE_SECONDS
	var wake := PixelDebris.spray(_caster.get_parent(), _caster.global_position, SPRAY, WAKE_PIXELS, Vector2.UP, 160.0)
	wake.speed_range = Vector2(15, 40)


func _land() -> void:
	_pass_through.stop()
	_caster.global_position = _surface_spot.round()
	animation_name = SURFACE_ANIMATION
	_splash(_surface_spot, SURFACE_SPLASH_PIXELS)
	for splashed in AbilityTargets.within(self, _surface_spot, soak_radius):
		SetUp.apply(splashed, SetUp.SOAKED, soak_seconds)
	var targets := AbilityTargets.within(self, _surface_spot, bite_radius)
	ElementStrike.hit(_caster, targets, damage, HitFeel.Weight.HEAVY, POISE_DAMAGE)
	SpeedLines.play_on(_caster, SURFACE_SPEED_LINES_SECONDS, Vector2.UP)


## Behind the enemy nearest `aim_point` (as seen from Ripfin), or toward the cursor.
func _spot_behind_prey(aim_point: Vector2) -> Vector2:
	var origin := _caster.global_position
	var prey: Node2D = null
	var best := search_radius
	for target_health in AbilityTargets.within(self, aim_point, search_radius):
		var enemy := target_health.get_parent() as Node2D
		var distance := enemy.global_position.distance_to(aim_point)
		if distance <= best and enemy.global_position.distance_to(origin) <= max_distance:
			prey = enemy
			best = distance
	if prey == null:
		return _toward(aim_point, max_distance)
	var through := prey.global_position - origin
	through = through.normalized() if through.length() > 1.0 else Vector2.RIGHT
	return prey.global_position + through * BEHIND_DISTANCE


func _splash(at: Vector2, amount: int) -> void:
	var spray := PixelDebris.spray(_caster.get_parent(), at, SPRAY, amount, Vector2.UP, 120.0)
	spray.speed_range = Vector2(40, 120)
	Shockwave.spawn(HitFeel.RING_SCENE, _caster.get_parent(), at, SPLASH_RING_RADIUS, 0.25, ApolloPalette.SKY_LIGHT)


func guide_line() -> String:
	return "Swims under the enemy nearest the cursor, bites from behind (%d dmg). The splash Soaks enemies within %d px (%d s)." % [damage, soak_radius, soak_seconds]


func set_up_status() -> String:
	return SetUp.SOAKED
