class_name LineOfSight
extends RefCounted
## Whether walls and obstacles stand between two points (e.g. a Warden Marksman's rail beam).
## Bodies in the enemies group and the player don't count: only the world blocks a line.


## How far from `from` toward `to` a line gets before something solid stops it: `to` when
## nothing does, otherwise the point where it's blocked.
static func reach(world_node: Node2D, from: Vector2, to: Vector2) -> Vector2:
	var query := PhysicsRayQueryParameters2D.create(from, to)
	query.exclude = _see_through(world_node)
	var hit := world_node.get_world_2d().direct_space_state.intersect_ray(query)
	return hit["position"] if not hit.is_empty() else to


## True when nothing solid stands between `from` and `to`.
static func is_clear(world_node: Node2D, from: Vector2, to: Vector2) -> bool:
	return reach(world_node, from, to).is_equal_approx(to)


static func _see_through(world_node: Node2D) -> Array[RID]:
	var see_through: Array[RID] = []
	var tree := world_node.get_tree()
	for body in tree.get_nodes_in_group(EnemyReactions.ENEMIES_GROUP) + tree.get_nodes_in_group(PlayerFinder.GROUP):
		if body is CollisionObject2D:
			see_through.append((body as CollisionObject2D).get_rid())
	return see_through
