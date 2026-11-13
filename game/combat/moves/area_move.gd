class_name AreaMove
extends Move
## Moves that hit everything in a radius (or a cone in front): Ground Thump, Twirl, Kick Dirt, Menace, Dizzy Dance,
## Kindle. They may deal damage, apply an effect, reach burrowers, or set grass alight.


func _on_release() -> void:
	var centre: Vector3 = creature.global_position
	AreaFx.spawn(creature.get_parent(), centre, number("radius"), Tuning.color(Tuning.creatures["glow"][spec["glow"]]))
	if spec.get("ignite", false) and creature.woods != null:
		creature.woods.ignite_around(centre, number("radius"))
	var target: Creature = creature.opponent
	if target == null or target.is_dead() or not in_area(target):
		return
	var hit: bool = true
	if number("damage") > 0.0:
		hit = target.take_hit(damage_now(), creature, ambush, id)
	if hit:
		apply_on_hit(target)


func in_area(target: Creature) -> bool:
	if target.traversal.mode == Traversal.Mode.UNDERGROUND and not spec.get("hits_underground", false):
		return false
	var offset: Vector3 = target.global_position - creature.global_position
	var flat := Vector3(offset.x, 0.0, offset.z)
	if flat.length() > number("radius") or absf(offset.y) > Tuning.f("attack_rules", "max_height_gap"):
		return false
	var in_arc: bool = creature.forward().angle_to(flat) <= deg_to_rad(number("arc_deg") * 0.5)
	return in_arc or flat.length() < Creature.BODY_RADIUS
