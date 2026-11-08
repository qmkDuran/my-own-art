class_name ToadTongue
extends Line2D
## The toad's tongue: shoots out of the mouth toward a direction, holds, then snaps back.
##
## Drawn in code so it can point anywhere, even though the toad sprite only faces the camera.

## Where the mouth is, relative to the toad's feet.
@export var mouth_offset: Vector2 = Vector2(0, -5)

## Share of the lash spent shooting out, and the share by which it has fully extended + held.
const SHOOT_OUT_SHARE := 0.35
const HOLD_UNTIL_SHARE := 0.55

var _direction: Vector2 = Vector2.DOWN
var _reach: float = 0.0
var _duration: float = 0.0
var _elapsed: float = 0.0
var _is_lashing: bool = false


func _ready() -> void:
	retract_now()


func lash(direction: Vector2, reach: float, duration: float) -> void:
	_direction = direction.normalized()
	_reach = reach
	_duration = duration
	_elapsed = 0.0
	_is_lashing = true
	visible = true


func retract_now() -> void:
	_is_lashing = false
	visible = false
	clear_points()


func is_fully_extended() -> bool:
	return _is_lashing and _extension() >= 1.0


## True if the tongue passes within hit_radius of the point (world coordinates).
func reaches(point: Vector2, hit_radius: float) -> bool:
	if not _is_lashing:
		return false
	var mouth := to_global(mouth_offset)
	var tip := to_global(_tip_position())
	var closest := Geometry2D.get_closest_point_to_segment(point, mouth, tip)
	return closest.distance_to(point) <= hit_radius


func _process(delta: float) -> void:
	if not _is_lashing:
		return

	_elapsed += delta
	points = PackedVector2Array([mouth_offset, _tip_position()])
	if _elapsed >= _duration:
		retract_now()


func _tip_position() -> Vector2:
	return mouth_offset + _direction * _reach * _extension()


## How far out the tongue is right now: 0 = in the mouth, 1 = full reach.
func _extension() -> float:
	var progress := clampf(_elapsed / _duration, 0.0, 1.0)
	if progress < SHOOT_OUT_SHARE:
		return progress / SHOOT_OUT_SHARE
	if progress < HOLD_UNTIL_SHARE:
		return 1.0
	return 1.0 - (progress - HOLD_UNTIL_SHARE) / (1.0 - HOLD_UNTIL_SHARE)
