class_name SenseMove
extends Move
## Senses, the counter to hiding. Keen Ears: for a while every sound in a much wider radius is noticed (pinged on
## screen for the player). Scent Trail: shows where the target walked in the last few seconds. Echo Pulse: reveals
## every hidden creature nearby for a moment, including the user, with a loud ping.


func _on_release() -> void:
	match String(spec["mode"]):
		"hearing":
			creature.effects.add("hearing", number("value"), number("duration"))
		"scent":
			creature.sensed.emit("scent", _scent_points())
		"echo":
			_echo()


func _scent_points() -> Array:
	var target: Creature = creature.opponent
	if target == null:
		return []
	return target.trail_since(number("trail_age")).filter(func(point: Vector3) -> bool:
		return point.distance_to(creature.global_position) <= number("radius"))


func _echo() -> void:
	var radius: float = number("radius")
	creature.stealth.expose(number("duration"))
	NoiseBus.emit_noise(creature, creature.global_position, radius, "echo")
	var ping: Color = Tuning.color(Tuning.creatures["glow"]["sense"])
	AreaFx.spawn(creature.get_parent(), creature.global_position, radius, ping)
	var target: Creature = creature.opponent
	if target != null and target.global_position.distance_to(creature.global_position) <= radius:
		target.stealth.expose(number("duration"))
		creature.sensed.emit("echo", [target.global_position])
