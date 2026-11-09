class_name ToadTongueAttack
extends Node
## A toad's attack: it holds its puffed-up pose (the warning), glints just before striking,
## then lashes its tongue (ToadTongue). The player is hurt if they're still in the way when
## the tongue is fully out.
##
## Like most trash mobs, the toad mainly telegraphs with its pose (the held puff); the one
## quick glint is the final cue. The toad decides when to start it and plays the pose; this
## does the timing, the glint and the hit.
## The lash is the toad's signature attack, so a lash that lands also poisons (Poisoned);
## nothing else the toad does carries poison (see DESIGN.md, "Enemy status effects").

## How far the tongue reaches, in pixels. The toad attacks once the player is this close.
@export var tongue_reach: float = 40.0
## Seconds of warning before the tongue comes out (the attack animation's first frame).
@export var puff_time: float = 0.80
## The toad glints once this many seconds before the tongue fires (the last-moment cue to dodge).
@export var glint_before_strike: float = 0.12
## Colour of that glint.
@export var glint_color: Color = ApolloPalette.LIME_PALE
## Seconds the tongue is out (the rest of the attack animation).
@export var lash_time: float = 0.32
## How close to the tongue the player's body must be to get hit, in pixels.
@export var tongue_hit_radius: float = 5.0
@export var tongue_damage: int = 1
@export_group("Poison")
## Damage each poison tick deals (mild by default; elites and bosses may raise it).
@export var poison_damage_per_tick: int = 1
## Seconds between poison ticks.
@export var poison_tick_interval: float = 1.5
## Seconds the poison lasts (3s at 1.5s a tick: 2 ticks).
@export var poison_duration: float = 3.0
@export_group("")
@export var tongue: ToadTongue
## Flashes the toad for the glint.
@export var hit_flash: HitFlash

var _lash_direction: Vector2 = Vector2.DOWN
var _has_glinted: bool = false
var _has_hit_this_lash: bool = false

@onready var toad: Node2D = get_parent()


## Where the tongue aims: the player's body, not their feet.
static func aim_point(player: Node2D) -> Vector2:
	return player.global_position + Vector2(0, Creature.BODY_HEIGHT)


## Starts the warning; the tongue will go toward `to_player`.
func start_puff(to_player: Vector2) -> void:
	_has_glinted = false
	_lash_direction = to_player.normalized()


## Call every frame of the puff with the seconds left before the strike.
func update_puff(seconds_left: float) -> void:
	if not _has_glinted and seconds_left <= glint_before_strike:
		_has_glinted = true
		hit_flash.flash(glint_color)


func lash() -> void:
	_has_hit_this_lash = false
	tongue.lash(_lash_direction, tongue_reach, lash_time)


## Call every frame of the lash: the hit is checked once, the moment the tongue is fully out.
func update_lash() -> void:
	if tongue.is_fully_extended() and not _has_hit_this_lash:
		_has_hit_this_lash = true
		_try_to_hit_player()


## Called off (e.g. it got hit): the tongue snaps back at once.
func cancel() -> void:
	tongue.retract_now()


func _try_to_hit_player() -> void:
	var player := PlayerFinder.find(self)
	if player == null or not tongue.reaches(aim_point(player), tongue_hit_radius):
		return
	if PlayerHit.try_to_hurt(player, tongue_damage, toad.global_position):
		Poisoned.apply_to(PlayerHit.health_of(player), poison_damage_per_tick, poison_tick_interval, poison_duration)
