class_name CaptainAttack
extends Node2D
## One of the Warden Captain's attacks: a wind-up (telegraphed, with super armour), a glint
## just before it lands, the release, then a short follow-through.
##
## The Captain decides which attack to start and plays its pose; each attack does its own
## timing, telegraph and hit by overriding `_is_wanted`, `_on_start`, `_on_wind_up`,
## `_release` and `_on_finish`. A Node2D so telegraphs can be drawn around the Captain's feet.

## The pose the Captain plays (one of his sprite sheets).
@export var animation: String = "idle"
## Seconds from the start to the release, before phase 2 speeds it up.
@export var wind_up: float = 0.6
## Seconds he holds the pose after the release.
@export var follow_through: float = 0.3
## Seconds he stands recovering afterwards: the player's punish window (shorter in phase 2).
@export var recovery_time: float = 0.6
## The pose he holds while recovering (e.g. "stagger": bent over his rod after a slam).
@export var recovery_animation: String = "idle"
## Seconds before this attack can be used again.
@export var cooldown: float = 3.0
## Seconds after the fight starts before it's first ready.
@export var first_use_delay: float = 1.0
## He glints this many seconds before the release (the last-moment cue).
@export var glint_before: float = 0.12
@export var glint_color: Color = ApolloPalette.SKY_LIGHT
## Only used in phase 2 (e.g. the chip pulse).
@export var phase_two_only: bool = false
## Flashes the Captain for the glint.
@export var hit_flash: HitFlash

## The wind-up for the attack in progress (shorter in phase 2).
var current_wind_up: float = 0.0

var _seconds_until_ready: float = 0.0
var _has_glinted: bool = false
var _has_released: bool = false

@onready var captain: Node2D = get_parent()


func _ready() -> void:
	_seconds_until_ready = first_use_delay


func count_down(delta: float) -> void:
	_seconds_until_ready = maxf(0.0, _seconds_until_ready - delta)


## Ready, allowed in this phase, and the player is where this attack wants them.
func is_ready(is_phase_two: bool, distance_to_player: float) -> bool:
	if _seconds_until_ready > 0.0 or (phase_two_only and not is_phase_two):
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


## True while the attack is still winding up (the Captain has super armour then).
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
