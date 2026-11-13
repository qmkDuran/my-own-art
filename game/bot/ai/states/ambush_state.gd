class_name AmbushState
extends BotState
## Ambush: the player is likely coming this way. The bot sneaks to the best concealed spot near where the player is
## predicted to pass (ideally in a bush, across its usual escape route) and waits, still and quiet. If the player
## comes within lunge reach without facing it, it strikes. Gives up after a while or once spotted.

var _waited: float = 0.0
var _struck: bool = false


func enter() -> void:
	_waited = 0.0
	_struck = false
	done = not go_to_tactical("ambush", brain.predicted_target(), true)


func exit() -> void:
	stop_looking()


func tick(delta: float) -> void:
	if _struck:
		done = not bot().busy()
		return
	if not mover().arrived():
		return
	_waited += delta
	look_at_point(brain.predicted_target())
	var clue: Vector3 = senses().last_known_position
	if senses().sees_target and distance_to_clue() <= Tuning.f("bot", "strike_engage_range"):
		bot().aim_point = clue
		look_at_point(clue)
		_struck = use_role("melee") or use_role("area")
	elif senses().target_facing_me() or _waited > Tuning.f("bot", "ambush_wait"):
		done = true
