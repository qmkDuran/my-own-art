class_name BossAttack
extends Node2D
## One of a boss's attacks (a child of the Boss): a wind-up (telegraphed, with super armour),
## a glint just before it lands, the release, then a short follow-through.
##
## The Boss decides which attack to start and plays its pose; each attack does its own
## timing, telegraph and hit by overriding `_is_wanted`, `_on_start`, `_on_wind_up`,
## `_release` and `_on_finish`. A brawler's moves can also move the boss while they play out
## (`movement_velocity`) and change the punish window that follows (`recovery_seconds`,
## `recovery_pose`). A Node2D so telegraphs can be drawn around the boss's feet.

## The pose the boss plays (one of its sprite sheets).
@export var animation: String = "idle"
## Seconds from the start to the release, before phase 2 speeds it up.
@export var wind_up: float = 0.6
## Seconds the boss holds the pose after the release.
@export var follow_through: float = 0.3
## Seconds the boss stands recovering afterwards: the player's punish window (shorter in phase 2).
@export var recovery_time: float = 0.6
## The pose the boss holds while recovering (e.g. the Captain's "stagger": bent over his rod after a slam).
@export var recovery_animation: String = "idle"
## Seconds before this attack can be used again.
@export var cooldown: float = 3.0
## Seconds after the fight starts before it's first ready.
@export var first_use_delay: float = 1.0
## The boss glints this many seconds before the release (the last-moment cue).
@export var glint_before: float = 0.12
@export var glint_color: Color = ApolloPalette.SKY_LIGHT
## Only used in phase 2 (e.g. the chip pulse).
@export var phase_two_only: bool = false
## Flashes the boss for the glint.
@export var hit_flash: HitFlash

## The wind-up for the attack in progress (shorter in phase 2).
var current_wind_up: float = 0.0
## Set by the Boss before each start: phase-2 versions of a move can do more.
var is_phase_two: bool = false

var _seconds_until_ready: float = 0.0
var _has_glinted: bool = false
var _has_released: bool = false

@onready var boss: Boss = get_parent()


func _ready() -> void:
	_seconds_until_ready = first_use_delay


func count_down(delta: float) -> void:
	_seconds_until_ready = maxf(0.0, _seconds_until_ready - delta)


## A fresh fight (e.g. after the player fell): waits `first_use_delay` again.
func start_over() -> void:
	_seconds_until_ready = first_use_delay


## Ready, allowed in this phase, and the player is where this attack wants them.
func is_ready(in_phase_two: bool, distance_to_player: float) -> bool:
	if _seconds_until_ready > 0.0 or (phase_two_only and not in_phase_two):
		return false
	return _is_wanted(distance_to_player)


## Seconds the whole attack takes.
func duration() -> float:
	return current_wind_up + follow_through


## Starts the attack; `wind_up_scale` below 1 makes the wind-up faster (phase 2).
func start(wind_up_scale: float) -> void:
	current_wind_up = wind_up * wind_up_scale
	_has_glinted = false
	_has_released = false
	_on_start()
	queue_redraw()


## True while the attack is still winding up (the boss has super armour then).
func is_winding_up() -> bool:
	return not _has_released


## Call every frame of the attack with the seconds since it started.
func update(seconds_attacking: float) -> void:
	var time_to_release := current_wind_up - seconds_attacking
	if not _has_released:
		_on_wind_up(clampf(seconds_attacking / maxf(current_wind_up, 0.01), 0.0, 1.0))
	if not _has_glinted and time_to_release <= glint_before:
		_has_glinted = true
		if hit_flash != null:
			hit_flash.flash(glint_color)
	if not _has_released and time_to_release <= 0.0:
		_has_released = true
		_release()
	queue_redraw()


## The attack is over or called off: it can't be used again until its cooldown has passed.
func finish() -> void:
	_has_released = true
	_seconds_until_ready = cooldown
	_on_finish()
	queue_redraw()


## The boss's velocity during the attack (e.g. the arc of a leap); still by default.
func movement_velocity(_seconds_attacking: float) -> Vector2:
	return Vector2.ZERO


## Seconds of punish window after this attack, before phase 2 shortens it.
func recovery_seconds() -> float:
	return recovery_time


## The pose the boss holds while recovering.
func recovery_pose() -> String:
	return recovery_animation


# --- For each attack to fill in -------------------------------------------

func _is_wanted(_distance_to_player: float) -> bool:
	return true


func _on_start() -> void:
	pass


## `progress` runs from 0 to 1 over the wind-up.
func _on_wind_up(_progress: float) -> void:
	pass


func _release() -> void:
	pass


func _on_finish() -> void:
	pass
