class_name ZephootGustShot
extends Node
## A Zephoot's attack: it puffs up for a moment (the wind-up), glints at the last moment,
## then blows one slow gust orb toward where the player is standing.
##
## The Zephoot decides when to start it and plays the pose; this does the timing, the
## glint and the orb.

## The orb it blows.
@export var orb_scene: PackedScene
## It only shoots when the player is at most this far away, in pixels.
@export var shooting_range: float = 150.0
## Seconds it holds the puffed-up pose before the orb comes out (the player's warning).
@export var wind_up: float = 0.6
## It glints this many seconds before firing (the last-moment cue, like the toad's).
@export var glint_before: float = 0.12
@export var glint_color: Color = ApolloPalette.SKY_LIGHT
## Seconds from one shot to the next.
@export var seconds_between_shots: float = 2.2
## Seconds after it first notices the player before it may shoot.
@export var first_shot_delay: float = 1.0
## Where the orb leaves its beak, relative to its feet (x, y on the ground; height is the
## orb's own sprite offset).
@export var muzzle_offset: Vector2 = Vector2(0, 2)
## Flashes the Zephoot for the glint.
@export var hit_flash: HitFlash

var _seconds_until_ready: float = 0.0
var _has_glinted: bool = false
var _has_fired: bool = false

@onready var zephoot: Node2D = get_parent()


func _ready() -> void:
	_seconds_until_ready = first_shot_delay


func count_down(delta: float) -> void:
	_seconds_until_ready = maxf(0.0, _seconds_until_ready - delta)


## Ready again and the player is within range.
func should_shoot() -> bool:
	var player := PlayerFinder.find(self)
	if player == null or _seconds_until_ready > 0.0:
		return false
	return zephoot.global_position.distance_to(player.global_position) <= shooting_range


func start() -> void:
	_has_glinted = false
	_has_fired = false


## Call every frame of the wind-up with the seconds since it started.
## True once the orb is out (the wind-up is over).
func update(seconds_winding_up: float) -> bool:
	var time_to_fire := wind_up - seconds_winding_up
	if not _has_glinted and time_to_fire <= glint_before:
		_has_glinted = true
		hit_flash.flash(glint_color)
	if not _has_fired and time_to_fire <= 0.0:
		_has_fired = true
		_fire()
	return _has_fired


## Called off (e.g. it got hit, or enemies were paused): it may try again soon.
func cancel() -> void:
	_seconds_until_ready = maxf(_seconds_until_ready, glint_before)


func _fire() -> void:
	_seconds_until_ready = seconds_between_shots - wind_up
	var player := PlayerFinder.find(self)
	if orb_scene == null or player == null:
		return
	var orb: GustOrb = orb_scene.instantiate()
	zephoot.get_parent().add_child(orb)
	orb.global_position = zephoot.global_position + muzzle_offset
	orb.launch(player.global_position - orb.global_position)
