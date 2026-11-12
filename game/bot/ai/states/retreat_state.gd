class_name RetreatState
extends BotState
## Retreat: badly hurt, the bot breaks off and slips away to the refuge farthest from the player that the player
## cannot see (often a bush), and rests there until it has healed. Cornered up close, it fights back.

func enter() -> void:
	brain.since_retreat = 0.0
	stop_looking()
	mover().go_to(_refuge(), false)


func tick(_delta: float) -> String:
	if bot().health.fraction() >= Tuning.f("bot", "recover_health_fraction"):
		return "patrol"
	if senses().sees_target and distance_to_target() <= Tuning.f("bot", "cornered_distance"):
		return "fight"
	if mover().arrived() and senses().sees_target:
		mover().go_to(_refuge(), false)
	return ""


func _refuge() -> Vector3:
	var best: Vector3 = bot().global_position
	var best_score: float = -INF
	var eye: Vector3 = target().eye_position()
	var chest: Vector3 = Vector3.UP * Tuning.f("perception", "chest_height")
	for spot: Vector3 in _candidates():
		var score: float = spot.distance_to(target().global_position)
		if not Sight.clear(bot().get_world_3d(), eye, spot + chest):
			score += Tuning.f("bot", "retreat_hidden_bonus")
		if score > best_score:
			best_score = score
			best = spot
	return best


func _candidates() -> Array[Vector3]:
	var spots: Array[Vector3] = brain.woods.patrol_points.duplicate()
	for hiding: HidingSpot in brain.woods.hiding_spots:
		spots.append(hiding.global_position)
	return spots
