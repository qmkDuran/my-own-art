class_name MarksmanRailShot
extends Node
## A Warden Marksman's attack: kneeling, he tracks the player with a dashed lock-on line, the
## line freezes (blinking) for a moment, then a solid rail beam fires along it (RailBeam).
## The beam stops at the first wall or obstacle (LineOfSight), so breaking line of sight, or
## stepping off the frozen line, or dodging through it, saves the player.
##
## The beam's line is aimed and measured on the ground, feet to feet; it is drawn from his
## barrel straight through the middle of the player's body (CreatureBody), whatever his size.
##
## The Marksman decides when to start it and plays the poses; this does the timing, the
## lines and the hit.

## Closer than this, the drawn beam's rise is worked out as if he were this far (no
## near-vertical beams at point-blank range).
const MIN_AIM_DISTANCE := 24.0
## Beyond the player, the drawn beam keeps rising at most to this share of his distance.
const MAX_RISE_SHARE := 2.0

## Seconds the lock-on line tracks the player.
@export var track_time: float = 1.0
## Seconds it then stays frozen before the shot.
@export var lock_time: float = 0.25
@export var damage: int = 2
## How far the beam goes, in pixels; he only starts aiming at a player within `aim_range`.
@export var beam_range: float = 240.0
@export var aim_range: float = 190.0
## How close to the beam's line on the ground the player's feet must be to get hit, in pixels
## (about the player's own half-width).
@export var hit_width: float = 7.0
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
## Along the ground, feet to feet.
var _aim_direction: Vector2 = Vector2.DOWN
## The player's body height and distance (on the ground) when last tracked: the drawn beam
## rises from the barrel to that height at that distance.
var _aim_height: float = 0.0
var _aim_distance: float = 1.0
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
	var target := player.global_position
	return _ground_start().distance_to(target) <= aim_range and LineOfSight.is_clear(marksman, _ground_start(), target)


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


## True when the player's feet are on the beam's ground line from `from` to `to`.
static func is_on_beam(player: Node2D, from: Vector2, to: Vector2, width: float) -> bool:
	var feet := player.global_position
	return feet.distance_to(Geometry2D.get_closest_point_to_segment(feet, from, to)) <= width


func _track() -> void:
	var player := PlayerFinder.find(self)
	if player != null and player.global_position != _ground_start():
		_aim_direction = _ground_start().direction_to(player.global_position)
		_aim_height = CreatureBody.height_of(player)
		_aim_distance = maxf(MIN_AIM_DISTANCE, _ground_start().distance_to(player.global_position))
	_beam.set_line(_muzzle(), _drawn(_beam_end()))


func _fire() -> void:
	_seconds_until_ready = seconds_between_shots
	var beam_end := _beam_end()
	_beam.set_line(_muzzle(), _drawn(beam_end))
	_beam.fire()
	_beam = null
	var player := PlayerFinder.find(self)
	if player != null and is_on_beam(player, _ground_start(), beam_end, hit_width):
		PlayerHit.try_to_hurt(player, damage, marksman.global_position)


## Where the beam stops on the ground: its full range, or the first wall in the way.
func _beam_end() -> Vector2:
	return LineOfSight.reach(marksman, _ground_start(), _ground_start() + _aim_direction * beam_range)


## Where `ground_point` on the beam's line is drawn: on the straight line from the barrel
## through the middle of the player's body (no steeper than MAX_RISE_SHARE beyond him).
func _drawn(ground_point: Vector2) -> Vector2:
	var share := minf(_ground_start().distance_to(ground_point) / _aim_distance, MAX_RISE_SHARE)
	return ground_point + Vector2(0, lerpf(muzzle_offset.y, _aim_height, share))


## The barrel, as drawn.
func _muzzle() -> Vector2:
	return marksman.global_position + muzzle_offset


## The point on the ground under the barrel, where the beam's line starts.
func _ground_start() -> Vector2:
	return marksman.global_position + Vector2(muzzle_offset.x, 0)
