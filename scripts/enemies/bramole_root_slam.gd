class_name BramoleRootSlam
extends CloseRangeAttack
## A Bramole's attack: claws up while its bud opens (the wind-up), then it slams its claws
## down and roots burst out around it (RootSnare). A player inside the snare is rooted
## (Rooted: they can't walk or dodge for a moment, but can still jab); a small tangle of roots
## holds their feet meanwhile. See CloseRangeAttack for the telegraph and the hit.

## Seconds a snared player is rooted.
@export var root_time: float = 0.8
## Radius of the tangle of roots at a rooted player's feet, in pixels.
@export var tangle_radius: float = 6.0
## Seconds the snare's roots stay out before crumbling.
@export var snare_hold_time: float = 0.15


func _marker_color() -> Color:
	return StatusColors.ROOT_LIGHT


func _show_strike() -> void:
	RootSnare.spawn(attacker.get_parent(), attacker.global_position, reach, snare_hold_time)


func _afflict(player_health: Health) -> void:
	if Rooted.apply_to(player_health, root_time):
		var player := player_health.get_parent() as Node2D
		RootSnare.spawn(attacker.get_parent(), player.global_position, tangle_radius, root_time)
