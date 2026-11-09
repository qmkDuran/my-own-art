class_name RimothFrostPuff
extends CloseRangeAttack
## A Rimoth's answer to being cornered: when the player gets right up close it beats its wings
## (the tell), then puffs a ring of frost. A player it hits is chilled (Chilled: they walk
## slower for a moment). See CloseRangeAttack for the telegraph and the hit.

## Share of their speed a chilled player keeps, and for how many seconds.
@export var chill_speed_share: float = 0.85
@export var chill_time: float = 1.5
## The frost ring when it puffs.
@export var frost_ring_scene: PackedScene
@export var frost_ring_time: float = 0.2


func _marker_color() -> Color:
	return StatusColors.CHILL


func _show_strike() -> void:
	if frost_ring_scene != null:
		Shockwave.spawn(frost_ring_scene, attacker.get_parent(), attacker.global_position, reach, frost_ring_time, StatusColors.CHILL)


func _afflict(player_health: Health) -> void:
	Chilled.apply_to(player_health, chill_speed_share, chill_time)
