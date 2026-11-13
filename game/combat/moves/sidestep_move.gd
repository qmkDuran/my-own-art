class_name SidestepMove
extends Move
## Sidestep: a short quick hop to the side, untouchable while it lasts (a lighter, faster cousin of the roll).


func _on_release() -> void:
	var side: Vector3 = creature.move_intent.normalized() if creature.move_intent.length() > 0.0 \
			else creature.forward().cross(Vector3.UP)
	creature.dash(side * number("distance") / maxf(active_time, Ability.MIN_TIME), active_time)
	creature.effects.add("evade", 1.0, active_time)
