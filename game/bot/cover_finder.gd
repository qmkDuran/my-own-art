class_name CoverFinder
## Picks a hiding place from a ranged threat: the nearest spot behind a tree trunk or boulder, on the navmesh, that
## the threat has no line of sight to and that is not right next to the threat.

const NAVMESH_TOLERANCE: float = 1.0


static func find(woods: Woods, from: Vector3, threat: Vector3) -> Vector3:
	var best: Vector3 = Vector3.INF
	var best_distance: float = INF
	var chest: Vector3 = Vector3.UP * Tuning.f("perception", "chest_height")
	for cover: Dictionary in woods.cover_objects:
		var centre: Vector3 = cover["pos"]
		if centre.distance_to(from) > Tuning.f("bot", "cover_search_radius"):
			continue
		var spot: Vector3 = _behind(woods, centre, float(cover["radius"]), threat)
		if spot == Vector3.INF or spot.distance_to(threat) < Tuning.f("bot", "cover_min_distance"):
			continue
		if Sight.clear(woods.get_world_3d(), threat, spot + chest):
			continue
		if from.distance_to(spot) < best_distance:
			best_distance = from.distance_to(spot)
			best = spot
	return best


static func _behind(woods: Woods, centre: Vector3, radius: float, threat: Vector3) -> Vector3:
	var away: Vector3 = Vector3(centre.x - threat.x, 0.0, centre.z - threat.z).normalized()
	var wanted: Vector3 = centre + away * (radius + Creature.BODY_RADIUS + Tuning.f("bot", "cover_gap"))
	var spot: Vector3 = woods.on_navmesh(wanted)
	return spot if spot.distance_to(wanted) <= NAVMESH_TOLERANCE else Vector3.INF
