class_name MeleeMove
extends Move
## Close-range strikes (Snap, Rush Strike, Leaping Strike, Tail Sweep, Ram, Rake): a lunge (an arc through the air
## for a pounce), then a hit check in the move's reach and arc. Some stagger or knock back.


func _on_release() -> void:
	var speed: float = number("lunge") / maxf(active_time, Ability.MIN_TIME)
	var lunge: Vector3 = creature.forward() * speed + Vector3.UP * float(spec.get("lift", 0.0))
	if float(spec.get("lift", 0.0)) > 0.0:
		creature.launch(lunge)
	elif number("lunge") > 0.0:
		creature.lunge(lunge, active_time)


func _on_active_end() -> void:
	var target: Creature = creature.opponent
	if target == null or target.is_dead() or not in_reach(target):
		return
	if target.take_hit(damage_now(), creature, ambush, id):
		apply_on_hit(target)
		if spec.has("stagger"):
			target.stagger(number("stagger"))
		if spec.has("knockback"):
			var away: Vector3 = target.global_position - creature.global_position
			target.lunge(Vector3(away.x, 0.0, away.z).normalized() * number("knockback"), active_time)


## True when the target is inside the reach and arc right now (and not underground).
func in_reach(target: Creature) -> bool:
	if target.traversal.mode == Traversal.Mode.UNDERGROUND:
		return false
	var offset: Vector3 = target.global_position - creature.global_position
	if absf(offset.y) > Tuning.f("attack_rules", "max_height_gap"):
		return false
	var flat := Vector3(offset.x, 0.0, offset.z)
	if flat.length() > number("range"):
		return false
	var half_arc: float = deg_to_rad(number("arc_deg") * 0.5)
	return flat.length() < Creature.BODY_RADIUS or creature.forward().angle_to(flat) <= half_arc
