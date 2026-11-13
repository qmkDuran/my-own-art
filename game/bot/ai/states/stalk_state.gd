class_name StalkState
extends BotState
## Stalk: the bot sees the player, and the player's creature is not facing it. It sneaks in (slow and quiet),
## aiming to come from behind, and opens with a strike: an ambush if the player has not noticed it. Done after the
## strike, or when the player turns toward it or slips out of sight.

const BEHIND_DISTANCE: float = 1.5

var _struck: bool = false


func enter() -> void:
	_struck = false
	stop_looking()


func exit() -> void:
	stop_looking()


func tick(_delta: float) -> void:
	if _struck:
		done = not bot().busy()
		return
	if senses().target_facing_me() or not senses().sees_target:
		done = true
		return
	var clue: Vector3 = senses().last_known_position
	if distance_to_clue() <= Tuning.f("bot", "strike_engage_range"):
		mover().stop()
		bot().aim_point = clue
		look_at_point(clue)
		_struck = use_role("melee") or use_role("area")
	else:
		mover().go_to(clue - target().forward() * BEHIND_DISTANCE, true)
