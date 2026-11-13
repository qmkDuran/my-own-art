class_name SubmergeMove
extends Move
## Submerge: slip under the water of the stream or pond and swim hidden (use again to surface). Slow, no attacks,
## and a line of bubbles follows the swimmer. It surfaces by itself when out of breath or out of water.

var _under_left: float = 0.0


func submerged() -> bool:
	return creature.traversal.mode == Traversal.Mode.SUBMERGED


func start() -> bool:
	if submerged():
		creature.traversal.enter(Traversal.Mode.GROUND)
		return true
	return super()


func tick(delta: float) -> void:
	super(delta)
	if submerged():
		_under_left -= delta
		if _under_left <= 0.0 or not creature.woods.water_at(creature.global_position):
			creature.traversal.enter(Traversal.Mode.GROUND)


func _on_release() -> void:
	creature.traversal.enter(Traversal.Mode.SUBMERGED)
	_under_left = number("duration")
