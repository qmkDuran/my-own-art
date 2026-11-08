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
var _has_dripped: bool = false

## Toxic green droplets that fly off the tip when the tongue snaps out.
@export var droplet_color: Color = ApolloPalette.GREEN_LIGHT


func _ready() -> void:
	retract_now()


func lash(direction: Vector2, reach: float, duration: float) -> void:
	_direction = direction.normalized()
	_reach = reach
	_duration = duration
	_elapsed = 0.0
	_is_lashing = true
	_has_dripped = false
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
	if not _has_dripped and _extension() >= 1.0:
		_has_dripped = true
		_spray_droplets(to_global(_tip_position()))
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


## A few droplets flick off the tip at full reach. Added to the world so they don't follow the tongue.
func _spray_droplets(at: Vector2) -> void:
	var droplets := CPUParticles2D.new()
	droplets.one_shot = true
	droplets.explosiveness = 0.9
	droplets.amount = 5
	droplets.lifetime = 0.35
	droplets.direction = _direction
	droplets.spread = 50.0
	droplets.initial_velocity_min = 20.0
	droplets.initial_velocity_max = 45.0
	droplets.gravity = Vector2(0, 160)
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([droplet_color, Color(droplet_color, 0.0)])
	droplets.color_ramp = ramp
	owner.get_parent().add_child(droplets)
	droplets.global_position = at
	droplets.emitting = true
	get_tree().create_timer(0.6).timeout.connect(droplets.queue_free)
