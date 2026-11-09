class_name HandlerRodShove
extends Node
## A Handler's rod shove, used when the player gets too close: he raises the rod while red
## energy gathers into it, glints at the last moment, then slams it into the ground. The
## shockwave hurts the player and knocks them back, unless they dodge through it.
##
## The Handler decides when to start it and plays the pose; this does the timing and the hit.

## Seconds the slam's ring takes to spread.
const SHOCKWAVE_SECONDS := 0.2

## If the player stays this close (pixels), he shoves them away.
@export var trigger_distance: float = 22.0
## How far the shockwave reaches, in pixels.
@export var shockwave_radius: float = 30.0
## Seconds the rod glows before the shockwave (the player's chance to dodge).
@export var wind_up: float = 0.5
## Seconds he stays in the pose after the shockwave.
@export var follow_through: float = 0.15
## He glints this many seconds before the shockwave (the last-moment cue).
@export var glint_before: float = 0.12
@export var glint_color: Color = ApolloPalette.RED_LIGHT
## Colour of the slam's shockwave ring.
@export var shockwave_color: Color = Color(ApolloPalette.RED_LIGHT, 0.9)
## Where the rod hits the ground, relative to his feet. The shockwave starts here.
@export var slam_point: Vector2 = Vector2(0, -2)
@export var damage: int = 1
## Speed the player is knocked back at, in pixels per second.
@export var push_speed: float = 170.0
## Seconds the push controls the player.
@export var push_time: float = 0.25
## Seconds before he can shove again.
@export var cooldown: float = 2.5
## The ring effect shown when he shoves.
@export var shockwave_scene: PackedScene
## The red energy gathering into the rod tip.
@export var charge_particles: ChargeParticles
## Flashes the Handler for the glint.
@export var hit_flash: HitFlash

var _seconds_until_ready: float = 0.0
var _has_released: bool = false
var _has_glinted: bool = false

@onready var handler: Node2D = get_parent()


func count_down(delta: float) -> void:
	_seconds_until_ready = maxf(0.0, _seconds_until_ready - delta)


## Ready again and the player is within reach.
func should_shove() -> bool:
	var player := PlayerFinder.find(self)
	if player == null or _seconds_until_ready > 0.0:
		return false
	return handler.global_position.distance_squared_to(player.global_position) <= trigger_distance * trigger_distance


## Seconds the whole shove takes, wind-up and follow-through.
func duration() -> float:
	return wind_up + follow_through


func start() -> void:
	_has_released = false
	_has_glinted = false
	charge_particles.start_charging()


## Call every frame of the shove with the seconds since it started.
func update(seconds_shoving: float) -> void:
	var time_to_release := wind_up - seconds_shoving
	if not _has_glinted and time_to_release <= glint_before:
		_has_glinted = true
		hit_flash.flash(glint_color)
	if not _has_released and time_to_release <= 0.0:
		_has_released = true
		_release_shockwave()


## The shove is over: it can't be used again until the cooldown has passed.
func finish() -> void:
	_seconds_until_ready = cooldown


func _release_shockwave() -> void:
	charge_particles.stop_charging()
	_spawn_shockwave_effect()
	var player := PlayerFinder.find(self)
	if player == null:
		return
	var from_slam := player.global_position - (handler.global_position + slam_point)
	if from_slam.length() > shockwave_radius:
		return

	if not PlayerHit.try_to_hurt(player, damage, handler.global_position):
		return  # dodged through it
	var direction := from_slam.normalized() if from_slam.length() > 0.1 else Vector2.DOWN
	PlayerHit.shove(player, direction * push_speed, push_time)


func _spawn_shockwave_effect() -> void:
	if shockwave_scene == null:
		return
	Shockwave.spawn(shockwave_scene, handler.get_parent(), handler.global_position + slam_point, shockwave_radius, SHOCKWAVE_SECONDS, shockwave_color)
