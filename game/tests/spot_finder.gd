class_name SpotFinder
extends RefCounted
## Finds places in the generated woods that suit a test: an open spot with a clear view of a point, or a tree
## with open ground on one side (to shoot at) and room behind it (to hide a target).

const DIRECTIONS: int = 16
const MAX_SLOPE_DROP: float = 1.2
const INNER_LIMIT: float = 34.0
const NAVMESH_TOLERANCE: float = 0.3
const TRUNK_CLEARANCE: float = 0.6
const SAME_SPOT: float = 0.1
const HIDING_CLEARANCE: float = 1.0

var m: Main


func _init(match_root: Main) -> void:
	m = match_root


## A spot `distance` from the target with a clear line of sight to it, on walkable open ground.
func open_view_spot(target: Vector3, distance: float) -> Vector2:
	for k: int in DIRECTIONS:
		var spot: Vector2 = Stage.ground_xz(target) + Vector2.from_angle(TAU * k / DIRECTIONS) * distance
		if _walkable(spot, target.y) and _clear(m.woods.ground_at(spot), target):
			return spot
	return Vector2.INF


## {tree, shooter, behind}: a trunk with a clear shooting spot in front and a hiding spot right behind it.
func tree_shot(range_to_tree: float, behind_distance: float) -> Dictionary:
	for tree: Vector3 in m.woods.tree_spots:
		if maxf(absf(tree.x), absf(tree.z)) > INNER_LIMIT:
			continue
		for k: int in DIRECTIONS:
			var direction: Vector2 = Vector2.from_angle(TAU * k / DIRECTIONS)
			var shooter: Vector2 = Stage.ground_xz(tree) + direction * range_to_tree
			var behind: Vector2 = Stage.ground_xz(tree) - direction * behind_distance
			if _walkable(shooter, tree.y) and _walkable(behind, tree.y) and _only_tree_between(shooter, tree, behind):
				return { "tree": tree, "shooter": shooter, "behind": behind }
	return {}


func _only_tree_between(shooter: Vector2, tree: Vector3, behind: Vector2) -> bool:
	var chest: Vector3 = Vector3.UP * Tuning.f("perception", "chest_height")
	var from: Vector3 = m.woods.ground_at(shooter) + chest
	var toward: Vector3 = (tree - m.woods.ground_at(shooter)).normalized()
	if not _clear(m.woods.ground_at(shooter), tree - toward * TRUNK_CLEARANCE):
		return false
	var query := PhysicsRayQueryParameters3D.create(from, m.woods.ground_at(behind) + chest, Layers.SIGHT_BLOCKERS)
	var hit: Dictionary = m.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return false
	return Stage.ground_xz(hit["collider"].global_position).distance_to(Stage.ground_xz(tree)) < SAME_SPOT


func _walkable(spot: Vector2, near_height: float) -> bool:
	if maxf(absf(spot.x), absf(spot.y)) > INNER_LIMIT:
		return false
	var ground: Vector3 = m.woods.ground_at(spot)
	var off_navmesh: bool = m.woods.on_navmesh(ground).distance_to(ground) > NAVMESH_TOLERANCE
	if absf(ground.y - near_height) > MAX_SLOPE_DROP or off_navmesh:
		return false
	for hiding: HidingSpot in m.woods.hiding_spots:
		if Stage.ground_xz(hiding.global_position).distance_to(spot) < hiding.radius + HIDING_CLEARANCE:
			return false
	return true


func _clear(from_ground: Vector3, to: Vector3) -> bool:
	var chest: Vector3 = Vector3.UP * Tuning.f("perception", "chest_height")
	return Sight.clear(m.get_world_3d(), from_ground + chest, to + chest)
