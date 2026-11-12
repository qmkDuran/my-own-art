class_name SnareState
extends BotState
## Snare: with the player out of sight, the bot sets its own snare where the player is likely to walk: at the edge of
## the player's favourite hiding spot if it has learned one, otherwise on the way between the player's last known
## spot and itself. Same move, same rules as the player's (one at a time, a second to set, noisy).


func enter() -> void:
	stop_looking()
	mover().go_to(_snare_spot(), true)


func tick(_delta: float) -> void:
	if bot().trap.busy():
		return
	if not bot().trap.is_ready():
		done = true
	elif mover().arrived():
		bot().try_trap()


func committed() -> bool:
	return bot().trap.busy()


func _snare_spot() -> Vector3:
	var favourite: HidingSpot = _favourite_spot()
	if favourite != null:
		brain.bark("It sets a snare by the %s you like." % ("tall grass" if favourite.kind == "grass" else "bush"))
		var toward_me: Vector3 = (bot().global_position - favourite.global_position).normalized()
		return favourite.global_position + toward_me * (favourite.radius + Tuning.f("bot", "snare_offset"))
	return senses().last_known_position.lerp(bot().global_position, 0.5)


func _favourite_spot() -> HidingSpot:
	if brain.memory_use() <= 0.0 or not brain.model.has_favourite():
		return null
	var best: HidingSpot = null
	for spot: HidingSpot in brain.woods.hiding_spots:
		if best == null or brain.model.favourite_weight(spot) > brain.model.favourite_weight(best):
			best = spot
	return best
