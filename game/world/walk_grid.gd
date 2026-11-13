class_name WalkGrid
extends RefCounted
## A grid over the town of the places a person can stand (a floor below, room for the player's capsule) and which
## of them can be walked to from a starting point (neighbours connect when the floor height changes gently, so
## steps and ramps count). The spawner uses it so walking creatures only appear where they can reach the player;
## the tests use it to check the player is always on walkable ground.

const RAY_TOP: float = 14.0
const RAY_BOTTOM: float = -4.0
const MAX_STEP: float = 0.35
const LIFT: float = 0.06
const NEIGHBOURS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

var cell: float = 0.5
var origin: Vector2 = Vector2.ZERO
var size: Vector2i = Vector2i.ZERO
var floors: Dictionary = {}
var reachable: Dictionary = {}


## Surveys the walk bounds from data/town.json and floods out from the start point.
func build(world: World3D, start: Vector3) -> void:
	var bounds: Array = Tuning.doc("town")["walk_bounds"]
	cell = Tuning.f("town", "grid_cell")
	origin = Vector2(float(bounds[0]), float(bounds[1]))
	size = Vector2i(int((float(bounds[2]) - origin.x) / cell), int((float(bounds[3]) - origin.y) / cell))
	var space: PhysicsDirectSpaceState3D = world.direct_space_state
	for x: int in size.x:
		for z: int in size.y:
			var height: float = _floor_at(space, centre_of(Vector2i(x, z)))
			if not is_nan(height) and _fits(space, centre_of(Vector2i(x, z)), height):
				floors[Vector2i(x, z)] = height
	_flood(cell_of(start))


func cell_of(at: Vector3) -> Vector2i:
	return Vector2i(int(floor((at.x - origin.x) / cell)), int(floor((at.z - origin.y) / cell)))


func centre_of(index: Vector2i) -> Vector3:
	return Vector3(origin.x + (index.x + 0.5) * cell, 0.0, origin.y + (index.y + 0.5) * cell)


func is_reachable(at: Vector3) -> bool:
	return reachable.has(cell_of(at))


## The floor height of a reachable cell (NAN when the spot can't be reached).
func floor_at(at: Vector3) -> float:
	return float(floors.get(cell_of(at), NAN)) if is_reachable(at) else NAN


## Like floor_at, but also accepts a spot up to two cells from reachable ground (a body pressed into a narrow
## corner stands where a whole cell would not fit); of the nearby floors, the one closest to the body's height.
func floor_near(at: Vector3) -> float:
	var centre: Vector2i = cell_of(at)
	var best: float = NAN
	for dx: int in range(-2, 3):
		for dz: int in range(-2, 3):
			var index: Vector2i = centre + Vector2i(dx, dz)
			if reachable.has(index) and (is_nan(best) or absf(float(floors[index]) - at.y) < absf(best - at.y)):
				best = float(floors[index])
	return best


func _floor_at(space: PhysicsDirectSpaceState3D, at: Vector3) -> float:
	var ray := PhysicsRayQueryParameters3D.create(at + Vector3.UP * RAY_TOP, at + Vector3.UP * RAY_BOTTOM, Layers.WORLD)
	var hit: Dictionary = space.intersect_ray(ray)
	return NAN if hit.is_empty() else float((hit["position"] as Vector3).y)


func _fits(space: PhysicsDirectSpaceState3D, at: Vector3, height: float) -> bool:
	var capsule := CapsuleShape3D.new()
	capsule.radius = Tuning.f("player", "capsule_radius")
	capsule.height = Tuning.f("player", "capsule_height")
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.collision_mask = Layers.WORLD
	query.transform = Transform3D(Basis(), Vector3(at.x, height + capsule.height * 0.5 + LIFT, at.z))
	return space.intersect_shape(query, 1).is_empty()


func _flood(start: Vector2i) -> void:
	reachable.clear()
	if not floors.has(start):
		return
	var queue: Array[Vector2i] = [start]
	reachable[start] = true
	while not queue.is_empty():
		var here: Vector2i = queue.pop_back()
		for step: Vector2i in NEIGHBOURS:
			var next: Vector2i = here + step
			if not floors.has(next) or reachable.has(next):
				continue
			if absf(float(floors[next]) - float(floors[here])) < MAX_STEP:
				reachable[next] = true
				queue.append(next)
