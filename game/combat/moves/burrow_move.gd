class_name BurrowMove
extends Move
## Burrow: dig into soft soil (never rock), travel underground unseen, then use it again to pop up with a hit all
## around. Underground the soil rumbles: a dust trail and noise follow the burrower, and a Ground Thump hits it. It
## pops up by itself when the time runs out.

var _under_left: float = 0.0


func underground() -> bool:
	return creature.traversal.mode == Traversal.Mode.UNDERGROUND


func start() -> bool:
	if underground():
		pop_up()
		return true
	return super()


func tick(delta: float) -> void:
	super(delta)
	if underground():
		_under_left -= delta
		if _under_left <= 0.0:
			pop_up()


func _on_release() -> void:
	creature.traversal.enter(Traversal.Mode.UNDERGROUND)
	_under_left = number("duration")


func pop_up() -> void:
	creature.traversal.enter(Traversal.Mode.GROUND)
	creature.announce_attack(Tuning.f("noise", "attack_radius"))
	AreaFx.spawn(creature.get_parent(), creature.global_position, number("pop_radius"),
			Tuning.color(Tuning.creatures["glow"][spec["glow"]]))
	var target: Creature = creature.opponent
	if target == null or target.is_dead():
		return
	if Vector2(target.global_position.x - creature.global_position.x,
			target.global_position.z - creature.global_position.z).length() <= number("pop_radius"):
		target.take_hit(number("pop_damage") * creature.effects.value("damage_out", 1.0), creature, ambush, id)
