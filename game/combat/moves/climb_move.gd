class_name ClimbMove
extends Move
## Climb: up a climbable (marked) tree into its crown, hidden among the leaves, a perch for spitting down. Use it
## again to drop down. Climbing shakes the leaves, and while up there the creature cannot walk.


func perched() -> bool:
	return creature.traversal.mode == Traversal.Mode.PERCHED


func start() -> bool:
	if perched():
		drop_down()
		return true
	return super()


func _on_release() -> void:
	var trunk: Vector3 = creature.woods.climbable_near(creature.global_position, number("reach"))
	if trunk == Vector3.INF:
		return
	creature.woods.shake_tree_at(trunk)
	creature.traversal.perch = trunk + Vector3.UP * number("perch_height")
	creature.traversal.enter(Traversal.Mode.PERCHED)
	creature.global_position = creature.traversal.perch
	creature.velocity = Vector3.ZERO


func drop_down() -> void:
	creature.woods.shake_tree_at(creature.traversal.perch)
	creature.traversal.enter(Traversal.Mode.GROUND)
	creature.global_position = creature.traversal.perch + creature.forward() * Props.TRUNK_RADIUS * DROP_CLEARANCE


const DROP_CLEARANCE: float = 4.0
