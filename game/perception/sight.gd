class_name Sight
## Line-of-sight test shared by the bot's eyes, the player's view, the lock-on and cover finding: trees, rocks,
## logs and the ground block it; bushes and grass do not (hiding is a separate rule).


static func clear(world: World3D, from: Vector3, to: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(from, to, Layers.SIGHT_BLOCKERS)
	return world.direct_space_state.intersect_ray(query).is_empty()
