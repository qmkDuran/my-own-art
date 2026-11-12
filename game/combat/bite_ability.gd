class_name BiteAbility
extends Ability
## Bite: a clear wind-up (head pulls back, jaw glows), a short lunge, then a hit check in a front arc. A bite started
## from hiding, or while the target has not noticed the biter, is an ambush (bonus damage and a stagger).

var ambush: bool = false


func _init(owner: Creature) -> void:
	super(owner, Tuning.f("bite", "windup"), Tuning.f("bite", "lunge_time"), Tuning.f("bite", "recovery"),
			Tuning.f("bite", "cooldown"))


## True when the target stands inside the bite's reach and front arc right now.
func in_reach(target: Creature) -> bool:
	var offset: Vector3 = target.global_position - creature.global_position
	if absf(offset.y) > Tuning.f("bite", "max_height_gap"):
		return false
	var flat := Vector3(offset.x, 0.0, offset.z)
	if flat.length() > Tuning.f("bite", "range"):
		return false
	var half_arc: float = deg_to_rad(Tuning.f("bite", "arc_degrees") * 0.5)
	return flat.length() < Creature.BODY_RADIUS or creature.forward().angle_to(flat) <= half_arc


func _on_start() -> void:
	ambush = creature.ambush_ready()
	creature.announce_attack()


func _on_release() -> void:
	var speed: float = Tuning.f("bite", "lunge_distance") / Tuning.f("bite", "lunge_time")
	creature.lunge(creature.forward() * speed, Tuning.f("bite", "lunge_time"))


func _on_active_end() -> void:
	var target: Creature = creature.opponent
	if target != null and not target.is_dead() and in_reach(target):
		target.take_hit(Tuning.f("bite", "damage"), creature, ambush, "bite")
