class_name ZephootFloat
extends Node
## How a Zephoot floats: its cloud hovers above its shadow and bobs gently, and it keeps a
## comfortable distance from the player, backing off when they come close and drifting in
## when they're far (both around walls and obstacles via PathMover), with a slow sideways
## drift in between. Changes of speed are gentle, like a cloud.
##
## The Zephoot calls `drift_and_bob` every frame and asks which way and how fast to float.

@export_group("Keeping distance")
## It likes to stay between these distances from the player, in pixels (closest, farthest).
@export var preferred_distance: Vector2 = Vector2(70, 110)
## Floating speed, in pixels per second. Slower than the player, so it can be caught.
@export var float_speed: float = 34.0
## Sideways drift while it's at a comfortable distance, in pixels per second.
@export var drift_speed: float = 8.0
## Seconds before the sideways drift changes direction.
@export var drift_turn_time: float = 2.5
## How quickly it changes speed, in pixels per second squared (gentle, like a cloud).
@export var float_acceleration: float = 120.0

@export_group("Hovering")
## How high the cloud floats above its shadow, in pixels.
@export var hover_height: float = 3.0
## How far it bobs up and down, in pixels.
@export var bob_height: float = 1.0
## Seconds for one bob up and down.
@export var bob_period: float = 1.6

@export_group("Parts")
@export var sprite: SingleViewAnimator
@export var path_mover: PathMover

var _drift_sign: float = 1.0
var _seconds_until_drift_turn: float = 0.0
var _seconds_hovering: float = 0.0

@onready var zephoot: Node2D = get_parent()


func _ready() -> void:
	_drift_sign = 1.0 if randf() < 0.5 else -1.0
	_seconds_hovering = randf() * bob_period


## Call at the start of every frame: bobs the cloud and now and then turns the sideways drift.
func drift_and_bob(delta: float) -> void:
	_seconds_hovering += delta
	sprite.lift(hover_height + sin(TAU * _seconds_hovering / bob_period) * bob_height)
	_seconds_until_drift_turn -= delta
	if _seconds_until_drift_turn <= 0.0:
		_seconds_until_drift_turn = drift_turn_time
		_drift_sign = -_drift_sign


## Away from the player when they're too close, toward them when too far, and a slow
## sideways drift in between, as a share of `float_speed`. Zero without a player.
func preferred_direction() -> Vector2:
	var player := PlayerFinder.find(self)
	if player == null:
		return Vector2.ZERO
	if not RangeKeeping.is_in_band(zephoot, player, preferred_distance):
		return RangeKeeping.direction(path_mover, zephoot, player, preferred_distance)
	var to_player := player.global_position - zephoot.global_position
	return to_player.normalized().orthogonal() * _drift_sign * (drift_speed / float_speed)


## `current` eased toward `target_velocity` at the cloud's gentle acceleration.
func eased_velocity(current: Vector2, target_velocity: Vector2, delta: float) -> Vector2:
	return current.move_toward(target_velocity, float_acceleration * delta)


## True when it's moving faster than its idle drift (it then shows its moving pose).
func is_moving(current: Vector2) -> bool:
	return current.length() > drift_speed
