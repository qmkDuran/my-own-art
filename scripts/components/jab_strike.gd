class_name JabStrike
extends RefCounted
## A jab landing (MeleeAttack's punches; the finisher lands its own, see SpinningHook):
## the impact effect where the fist lands, and damage to every target along the punch.
##
## The punch hits from the attacker's body out to full reach, so targets slightly closer or
## further than the fist still get hit. It is measured on the ground, from the attacker's
## feet to each target's feet, so bodies of any height meet; the impact is drawn at fist
## height. Damage goes through CritRoll.


## Lands `jab` toward `direction`. Returns the Health of every target hit.
static func land(jab: MeleeAttack, direction: Vector2) -> Array[Health]:
	var punch_start := jab.attacker.global_position
	var punch_end := punch_start + direction * jab.reach
	_spawn_impact(jab, punch_end + Vector2(0, jab.fist_height), direction)
	return _damage_targets_along(jab, punch_start, punch_end)


static func _spawn_impact(jab: MeleeAttack, fist_position: Vector2, direction: Vector2) -> void:
	if jab.impact_effect == null:
		return
	var impact: Node2D = jab.impact_effect.instantiate()
	# Added to the world, not the attacker, so the effect stays where the hit landed.
	jab.attacker.get_parent().add_child(impact)
	impact.global_position = fist_position
	impact.rotation = direction.angle()


static func _damage_targets_along(jab: MeleeAttack, punch_start: Vector2, punch_end: Vector2) -> Array[Health]:
	var struck: Array[Health] = []
	var hit_radius_squared := jab.hit_radius * jab.hit_radius
	for target: Node2D in jab.get_tree().get_nodes_in_group(jab.target_group):
		var feet := target.global_position
		var closest := Geometry2D.get_closest_point_to_segment(feet, punch_start, punch_end)
		if feet.distance_squared_to(closest) > hit_radius_squared:
			continue
		var target_health: Health = Health.of(target)
		if target_health != null:
			CritRoll.deal_damage(jab.attacker, target_health, jab.damage)
			struck.append(target_health)
	return struck
