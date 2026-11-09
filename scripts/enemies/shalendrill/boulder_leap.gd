class_name BoulderLeap
extends BossAttack
## The Shalendrill's leap, its answer to a player who keeps away: it crouches while a red
## circle fills on the ground where the player stood (locked when the crouch starts), then
## bounds through the air and lands on it like a dropped boulder. Anyone in the circle is
## hurt, thrown out and staggered. Leave the circle (walk or dodge) before it lands. In the
## air it can't be hit and passes over the player; it lands heavily (the punish window).

## The landing circle: its fill's opacity as the crouch goes on (start, end), and its outline's.
const FILL_ALPHA := Vector2(0.1, 0.3)
const OUTLINE_ALPHA := 0.8
## The landing: its ring's spread time and colour, and the screen shake.
const LANDING_RING_SECONDS := 0.3
const LANDING_RING_COLOR := Color(ApolloPalette.GREY_LIGHT, 0.8)
const LANDING_SHAKE_STRENGTH := 3.0
const LANDING_SHAKE_SECONDS := 0.3

## It leaps when the player is between these distances, in pixels.
@export var leap_range: Vector2 = Vector2(64, 170)
## Seconds in the air.
@export var flight_time: float = 0.6
## Highest the sprite rises during the leap, in pixels.
@export var arc_height: float = 22.0
@export var landing_radius: float = 28.0
@export var damage: int = 2
@export var push_speed: float = 200.0
@export var push_time: float = 0.25
## Seconds the landing staggers the player (a boss's stronger Stone stagger).
@export var stagger_time: float = 0.5
@export var screen_shake: ScreenShake
@export var dust_scene: PackedScene
@export var shockwave_scene: PackedScene

var _target: Vector2
var _take_off: Vector2
var _wind_up_progress: float = 0.0
var _is_airborne: bool = false
var _flight_progress: float = 0.0


func movement_velocity(_seconds_attacking: float) -> Vector2:
	if not _is_airborne:
		return Vector2.ZERO
	return (_target - _take_off) / flight_time


func _is_wanted(distance_to_player: float) -> bool:
	return distance_to_player >= leap_range.x and distance_to_player <= leap_range.y


func _on_start() -> void:
	var player := PlayerFinder.find(self)
	_target = player.global_position if player != null else boss.global_position
	_wind_up_progress = 0.0
	_flight_progress = 0.0
	follow_through = flight_time + 0.1


func _on_wind_up(progress: float) -> void:
	_wind_up_progress = progress


func update(seconds_attacking: float) -> void:
	super.update(seconds_attacking)
	if not _is_airborne:
		return
	_flight_progress = clampf((seconds_attacking - current_wind_up) / flight_time, 0.0, 1.0)
	boss.sprite.lift(sin(PI * _flight_progress) * arc_height)
	if _flight_progress >= 1.0:
		_land()


func _release() -> void:
	_take_off = boss.global_position
	_set_airborne(true)
	DustPuff.spawn(dust_scene, boss.get_parent(), boss.global_position)


func _land() -> void:
	_set_airborne(false)
	DustPuff.spawn(dust_scene, boss.get_parent(), boss.global_position)
	if shockwave_scene != null:
		Shockwave.spawn(shockwave_scene, boss.get_parent(), boss.global_position, landing_radius, LANDING_RING_SECONDS, LANDING_RING_COLOR)
	if screen_shake != null:
		screen_shake.shake(LANDING_SHAKE_STRENGTH, LANDING_SHAKE_SECONDS)
	var player := PlayerFinder.find(self)
	if player == null:
		return
	var from_boss := player.global_position - boss.global_position
	if from_boss.length() > landing_radius or not PlayerHit.try_to_hurt(player, damage, boss.global_position):
		return
	var away := from_boss.normalized() if from_boss.length() > 0.1 else Vector2.DOWN
	PlayerHit.shove(player, away * push_speed, push_time)
	Staggered.apply_to(PlayerHit.health_of(player), stagger_time)


## Called off mid-air (e.g. the player fell): it comes down where it is, harmlessly.
func _on_finish() -> void:
	if _is_airborne:
		_set_airborne(false)
	_wind_up_progress = 0.0


func _set_airborne(airborne: bool) -> void:
	_is_airborne = airborne
	boss.health.is_invulnerable = airborne
	if not airborne:
		boss.sprite.lift(0.0)
	var player := PlayerFinder.find(self) as PhysicsBody2D
	if player == null:
		return
	if airborne:
		boss.add_collision_exception_with(player)
	else:
		boss.remove_collision_exception_with(player)


func _process(_delta: float) -> void:
	if _is_airborne or (is_winding_up() and _wind_up_progress > 0.0):
		queue_redraw()


func _draw() -> void:
	var showing := (is_winding_up() and _wind_up_progress > 0.0) or _is_airborne
	if not showing:
		return
	var centre := to_local(_target)
	var fill_share := _wind_up_progress * 0.5 + _flight_progress * 0.5
	draw_circle(centre, landing_radius, Color(TelegraphPainter.DANGER_COLOR, lerpf(FILL_ALPHA.x, FILL_ALPHA.y, fill_share)))
	draw_circle(centre, landing_radius * fill_share, Color(TelegraphPainter.DANGER_COLOR, FILL_ALPHA.y))
	var pulse := TelegraphPainter.pulse(_wind_up_progress * current_wind_up + _flight_progress)
	draw_arc(centre, landing_radius, 0.0, TAU, 40, TelegraphPainter.outline_color(pulse, OUTLINE_ALPHA), TelegraphPainter.OUTLINE_WIDTH)
