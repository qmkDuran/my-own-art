class_name BrinelobClawSnap
extends CloseRangeAttack
## A Brinelob's attack: it throws its claws wide (the wind-up), then claps them shut with a
## splash. A player it hits is soaked (Soaked: they walk slower for a moment).
## See CloseRangeAttack for the telegraph and the hit.

## Share of their speed a soaked player keeps, and for how many seconds.
@export var soak_speed_share: float = 0.8
@export var soak_time: float = 1.5
## The splash ring when the claws clap.
@export var splash_scene: PackedScene
@export var splash_time: float = 0.2


func _marker_color() -> Color:
	return StatusColors.SOAK_LIGHT


func _show_strike() -> void:
	if splash_scene != null:
		Shockwave.spawn(splash_scene, attacker.get_parent(), attacker.global_position + Vector2(0, -4), reach, splash_time, StatusColors.SOAK_LIGHT)


func _afflict(player_health: Health) -> void:
	Soaked.apply_to(player_health, soak_speed_share, soak_time)
