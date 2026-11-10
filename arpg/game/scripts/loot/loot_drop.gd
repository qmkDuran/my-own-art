class_name LootDrop
extends RefCounted
## Where drops land: in a neat ring around the source, only on open ground — never inside a wall, prop, wreck,
## the chasm or a fire, and never right under Michael's feet (so a click there stays a move).

const RING0: float = 26.0
const RING_STEP: float = 18.0
const PER_RING: int = 6
const CLEAR_OF_MICHAEL: float = 30.0
const CLEAR_OF_FIRE: float = 46.0
const PROBE_RADIUS: float = 16.0          # room for Michael to stand by it


static func drop(world: Node2D, at: Vector2, items: Array) -> void:
	var spots: Array[Vector2] = free_spots(world, at, items.size())
	for i: int in items.size():
		GroundItem.spawn(world, spots[i], items[i])


static func free_spots(world: Node2D, at: Vector2, n: int) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var michael: Node2D = world.get_tree().get_first_node_in_group("michael")
	for ring: int in 6:
		var count: int = PER_RING * (ring + 1)
		for k: int in count:
			var a: float = TAU * k / count + ring * 0.4
			var p: Vector2 = at + Vector2(cos(a), sin(a) * 0.6) * (RING0 + RING_STEP * ring)
			if _ok(world, p, out, michael):
				out.append(p)
				if out.size() >= n:
					return out
	while out.size() < n:
		out.append(at)
	return out


static func _ok(world: Node2D, p: Vector2, taken: Array[Vector2], michael: Node2D) -> bool:
	if michael != null and p.distance_to(michael.global_position) < CLEAR_OF_MICHAEL:
		return false
	for t: Vector2 in taken:
		if t.distance_to(p) < 16.0:
			return false
	for f: Array in GameData.zone["fires"]:
		if p.distance_to(SceneData.vec(f)) < CLEAR_OF_FIRE:
			return false
	var q := PhysicsShapeQueryParameters2D.new()
	var c := CircleShape2D.new()
	c.radius = PROBE_RADIUS
	q.shape = c
	q.transform = Transform2D(0.0, p)
	q.collision_mask = 1
	return world.get_world_2d().direct_space_state.intersect_shape(q, 1).is_empty()
