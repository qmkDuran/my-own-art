class_name Visibility
## The one set of seeing and hearing rules for both creatures. Concealed (bush, grass, smoke, a tree crown) means
## invisible beyond the reveal distance unless the watcher saw it go in; burrowed or submerged means invisible at any
## distance; a sense move's exposure overrides both. Dirt in the eyes shortens sight; Keen Ears lengthens hearing.

const BLIND_SIGHT_SHARE: float = 0.25


static func hides(target: Creature, distance: float, watched_spot: HidingSpot) -> bool:
	if not target.stealth.hides_at(distance):
		return false
	if target.traversal.deep():
		return true
	var spot: HidingSpot = target.stealth.current_spot()
	return spot == null or spot != watched_spot


static func sight_range(viewer: Creature, base_range: float) -> float:
	return base_range * (BLIND_SIGHT_SHARE if viewer.effects.has("blind") else 1.0)


## Does this listener hear a sound of this radius from there?
static func hears(listener: Creature, origin: Vector3, radius: float) -> bool:
	return listener.global_position.distance_to(origin) <= radius * listener.effects.value("hearing", 1.0)
