class_name MarksmanRailShot
extends Node
## A Warden Marksman's attack: kneeling, he tracks the player with a dashed lock-on line, the
## line freezes (blinking) for a moment, then a solid rail beam fires along it (RailBeam).
## The beam stops at the first wall or obstacle (LineOfSight), so breaking line of sight, or
## stepping off the frozen line, or dodging through it, saves the player.
##
## The Marksman decides when to start it and plays the poses; this does the timing, the
## lines and the hit.

## Seconds the lock-on line tracks the player.
@export var track_time: float = 1.0
## Seconds it then stays frozen before the shot.
@export var lock_time: float = 0.25
@export var damage: int = 2
## How far the beam goes, in pixels; he only starts aiming at a player within `aim_range`.
@export var beam_range: float = 240.0
@export var aim_range: float = 190.0
## How close to the beam the player's body must be to get hit, in pixels.
@export var hit_width: float = 5.0
## Seconds from one shot until he may aim again.
@export var seconds_between_shots: float = 2.5
## Seconds after he first notices the player before the first shot.
@export var first_shot_delay: float = 1.0
## Where the beam leaves his kneeling rod's barrel, relative to his feet.
@export var muzzle_offset: Vector2 = Vector2(3, -10)
## Flashes him as the line freezes (the last cue).
@export var hit_flash: HitFlash
@export var lock_flash_color: Color = ApolloPalette.SKY_LIGHT

var _seconds_until_ready: float = 0.0
var _beam: RailBeam
var _aim_direction: Vector2 = Vector2.DOWN
var _is_locked: bool = false

@onready var marksman: Node2D = get_parent()


func _ready() -> void:
	_seconds_until_ready = first_shot_delay


func count_down(delta: float) -> void:
	_seconds_until_ready = maxf(0.0, _seconds_until_ready - delta)


## Ready again, and the player is within aiming range with nothing in the way.
func should_shoot() -> bool:
	var player := PlayerFinder.find(self)
	if player == null or _seconds_until_ready > 0.0:
		return false
	var target := _aim_point(player)
	return _muzzle().distance_to(target) <= aim_range and LineOfSight.is_clear(marksman, _muzzle(), target)


## Total seconds from kneeling to the shot.
func aim_time() -> float:
	return track_time + lock_time


func start() -> void:
	_is_locked = false
	_beam = RailBeam.spawn(marksman.get_parent())
	_track()


## Call every frame of the aim with the seconds since it started. True once he has fired.
func update(seconds_aiming: float) -> bool:
	if seconds_aiming < track_time:
		_track()
		return false
	if not _is_locked:
		_is_locked = true
		_beam.lock()
		hit_flash.flash(lock_flash_color)
	if seconds_aiming < aim_time():
		return false
	_fire()
	return true


## Called off (e.g. he got hit): the line goes out.
func cancel() -> void:
	if is_instance_valid(_beam):
		_beam.queue_free()
	_beam = null
	_seconds_until_ready = maxf(_seconds_until_ready, lock_time)


## True when the player's body is on the beam from `from` to `to`.
static func is_on_beam(player: Node2D, from: Vector2, to: Vector2, width: float) -> bool:
	var body := _aim_point(player)
	return body.distance_to(Geometry2D.get_closest_point_to_segment(body, from, to)) <= width


func _track() -> void:
	var player := PlayerFinder.find(self)
	if player != null:
		_aim_direction = _muzzle().direction_to(_aim_point(player))
	_beam.set_line(_muzzle(), _beam_end())


func _fire() -> void:
	_seconds_until_ready = seconds_between_shots
	var beam_end := _beam_end()
	_beam.set_line(_muzzle(), beam_end)
	_beam.fire()
	_beam = null
	var player := PlayerFinder.find(self)
	if player != null and is_on_beam(player, _muzzle(), beam_end, hit_width):
		PlayerHit.try_to_hurt(player, damage, marksman.global_position)


## Where the beam stops: its full range, or the first wall in the way.
func _beam_end() -> Vector2:
	return LineOfSight.reach(marksman, _muzzle(), _muzzle() + _aim_direction * beam_range)


func _muzzle() -> Vector2:
	return marksman.global_position + muzzle_offset


static func _aim_point(player: Node2D) -> Vector2:
	return player.global_position + Vector2(0, Creature.BODY_HEIGHT)
