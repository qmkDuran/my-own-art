class_name CloseRangeAttack
extends Node
## What the close-range area attacks share (a Bramole's root slam, a Brinelob's claw snap, a
## Rimoth's frost puff): a wind-up with the attack's reach shown on the ground (ReachMarker)
## and a glint at the last moment, then a strike that hits the player if they're still within
## reach (a dodge passes through) and, on a hit, brings the attack's status effect.
##
## The enemy decides when to start it and plays its poses; this does the timing, the
## telegraph and the hit. Each attack overrides:
##   _marker_color()          -> the colour its reach is shown in
##   _show_strike()           -> its strike effect (roots, a splash, a frost ring)
##   _afflict(player_health)  -> its status effect on a player it hit

## It strikes once the player is this close, in pixels; the strike reaches as far.
@export var reach: float = 24.0
## Seconds of warning before the strike.
@export var wind_up: float = 0.5
@export var damage: int = 1
## Seconds from one strike until it may start the next.
@export var seconds_between: float = 1.6
## It glints this many seconds before striking (the last-moment cue to dodge).
@export var glint_before: float = 0.12
@export var glint_color: Color = ApolloPalette.WHITE
@export var hit_flash: HitFlash
@export var reach_marker: ReachMarker

var _seconds_until_ready: float = 0.0
var _has_glinted: bool = false

@onready var attacker: Node2D = get_parent()


func count_down(delta: float) -> void:
	_seconds_until_ready = maxf(0.0, _seconds_until_ready - delta)


## Ready again and the player is within reach.
func should_strike() -> bool:
	return _seconds_until_ready <= 0.0 and _is_player_within_reach()


func start() -> void:
	_has_glinted = false
	reach_marker.show_reach(reach, _marker_color())


## Call every frame of the wind-up with the seconds since it started.
func update(seconds_winding_up: float) -> void:
	reach_marker.set_progress(seconds_winding_up / wind_up)
	if not _has_glinted and wind_up - seconds_winding_up <= glint_before:
		_has_glinted = true
		hit_flash.flash(glint_color)


## The strike: its effect, and the hit if the player is still within reach.
func strike() -> void:
	reach_marker.hide_reach()
	_seconds_until_ready = seconds_between
	_show_strike()
	var player := PlayerFinder.find(self)
	if player == null or not _is_player_within_reach():
		return
	if PlayerHit.try_to_hurt(player, damage, attacker.global_position):
		_afflict(PlayerHit.health_of(player))


## Called off (e.g. enemies were paused): it may try again soon.
func cancel() -> void:
	reach_marker.hide_reach()
	_seconds_until_ready = maxf(_seconds_until_ready, glint_before)


func _is_player_within_reach() -> bool:
	var player := PlayerFinder.find(self)
	return player != null and attacker.global_position.distance_to(player.global_position) <= reach


# --- For each attack to fill in --------------------------------------------

func _marker_color() -> Color:
	return ApolloPalette.WHITE


func _show_strike() -> void:
	pass


func _afflict(_player_health: Health) -> void:
	pass
