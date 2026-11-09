class_name GruntiteCharge
extends Node
## A Gruntite's charge: it locks onto where the player is, winds up (crest bristles and eyes
## go red, then head down with a hoof scrape and a puff of dust), then thunders in a straight
## line for a fixed distance. Ramming the player hurts and throws them hard; a dodge passes
## through it. The Gruntite stops early if it hits a wall.
##
## The Gruntite decides when to start and plays the pose; this does the timing, the
## direction, the distance and the hit.

## It only charges when the player is between these distances, in pixels (closest, farthest).
@export var charge_range: Vector2 = Vector2(40, 90)
## Seconds of wind-up before it charges (the attack sheet's two wind-up frames).
@export var wind_up: float = 0.8
## Seconds into the wind-up when its head goes down and the hoof scrapes (the dust puff).
@export var scrape_at: float = 0.4
## Charging speed, as a multiple of its walking speed.
@export var speed_multiplier: float = 3.0
## How far one charge goes, in pixels.
@export var charge_distance: float = 90.0
## How close its body must come to the player's to ram them, in pixels.
@export var hit_radius: float = 9.0
@export var damage: int = 2
## Speed the player is thrown at, in pixels per second (a strong knockback).
@export var push_speed: float = 230.0
## Seconds the push controls the player.
@export var push_time: float = 0.3
## Seconds after a charge before it can charge again.
@export var cooldown: float = 1.5
## The dust kicked up by the hoof scrape (and by a bonk).
@export var dust_scene: PackedScene

var direction: Vector2 = Vector2.DOWN

var _seconds_until_ready: float = 0.0
var _has_scraped: bool = false
var _has_hit: bool = false
var _start_position: Vector2

@onready var gruntite: CharacterBody2D = get_parent()


func count_down(delta: float) -> void:
	_seconds_until_ready = maxf(0.0, _seconds_until_ready - delta)


## Ready again and the player is at charging range.
func should_charge() -> bool:
	var player := PlayerFinder.find(self)
	if player == null or _seconds_until_ready > 0.0:
		return false
	var distance_squared := gruntite.global_position.distance_squared_to(player.global_position)
	return distance_squared >= charge_range.x * charge_range.x and distance_squared <= charge_range.y * charge_range.y


## True when the player is too close to charge at (it backs off to make room).
func is_player_too_close() -> bool:
	var player := PlayerFinder.find(self)
	if player == null:
		return false
	return gruntite.global_position.distance_squared_to(player.global_position) < charge_range.x * charge_range.x


## Locks the direction toward the player: the charge goes there, wherever they move.
func start_wind_up() -> void:
	_has_scraped = false
	var player := PlayerFinder.find(self)
	if player != null and player.global_position != gruntite.global_position:
		direction = gruntite.global_position.direction_to(player.global_position)


## Call every frame of the wind-up with the seconds since it started.
func update_wind_up(seconds_winding_up: float) -> void:
	if not _has_scraped and seconds_winding_up >= scrape_at:
		_has_scraped = true
		kick_up_dust()


## Off it goes. It runs through the player's body (the hit is checked by distance), so
## a dodging player can leap through it.
func start_charge(walk_speed: float) -> Vector2:
	_has_hit = false
	_start_position = gruntite.global_position
	_set_passes_through_player(true)
	return direction * walk_speed * speed_multiplier


## True once it has gone the full distance.
func has_gone_full_distance() -> bool:
	return gruntite.global_position.distance_squared_to(_start_position) >= charge_distance * charge_distance


## Rams the player if they're in the way. True on the frame it lands.
func try_to_ram_player() -> bool:
	var player := PlayerFinder.find(self)
	if _has_hit or player == null:
		return false
	if gruntite.global_position.distance_squared_to(player.global_position) > hit_radius * hit_radius:
		return false
	if not PlayerHit.try_to_hurt(player, damage, gruntite.global_position):
		return false  # leaping through it
	_has_hit = true
	PlayerHit.shove(player, direction * push_speed, push_time)
	return true


## The charge is over (or called off): it can't charge again until the cooldown passes.
func finish() -> void:
	_set_passes_through_player(false)
	_seconds_until_ready = cooldown


func kick_up_dust() -> void:
	DustPuff.spawn(dust_scene, gruntite.get_parent(), gruntite.global_position)


func _set_passes_through_player(passes: bool) -> void:
	var player := PlayerFinder.find(self) as PhysicsBody2D
	if player == null:
		return
	if passes:
		gruntite.add_collision_exception_with(player)
	else:
		gruntite.remove_collision_exception_with(player)
