class_name Woods
extends Node3D
## The arena: terrain, trees, rocks, logs, hiding spots, light and a baked navmesh, built from data/woods.json. It
## also answers questions about itself (ground height, cover objects, patrol points, hiding spots).

const AGENT_RADIUS: float = 0.5
const AGENT_HEIGHT: float = 1.2
const AGENT_MAX_CLIMB: float = 0.4
const AGENT_MAX_SLOPE: float = 38.0
const NAV_CELL_SIZE: float = 0.25
const NAV_CELL_HEIGHT: float = 0.1
const NAV_VERTICAL_SPAN: float = 30.0
const WALL_HEIGHT: float = 12.0
const WALL_THICKNESS: float = 1.0

var shape: TerrainShape
var hiding_spots: Array[HidingSpot] = []
var cover_objects: Array[Dictionary] = []
var patrol_points: Array[Vector3] = []
var tree_spots: Array[Vector3] = []
var player_spawn: Vector3
var bot_spawn: Vector3
var half_size: float
var _region: NavigationRegion3D
var _rng := RandomNumberGenerator.new()


func build() -> void:
	var layout: Dictionary = Tuning.woods
	_rng.seed = int(layout["seed"])
	half_size = float(layout["arena_half_size"])
	shape = TerrainShape.new(layout["terrain"])
	_region = NavigationRegion3D.new()
	_region.name = "Navigation"
	add_child(_region)
	_region.add_child(TerrainBuilder.build(shape, layout["terrain"], layout["clearings"]))
	_add_trees(ForestScatter.new(layout, shape, _rng).plan())
	_add_rocks_and_logs(layout)
	_add_walls()
	_add_hiding_spots(layout)
	Atmosphere.build(self, shape)
	for point: Array in layout["patrol_points"]:
		patrol_points.append(ground_at(Tuning.vec2(point)))
	player_spawn = ground_at(Tuning.vec2(layout["player_spawn"]))
	bot_spawn = ground_at(Tuning.vec2(layout["bot_spawn"]))
	_bake_navigation()


func ground_at(spot: Vector2) -> Vector3:
	return Vector3(spot.x, shape.height(spot.x, spot.y), spot.y)


func nav_map() -> RID:
	return get_world_3d().navigation_map


## The navmesh point closest to a world position (used to keep AI targets reachable). Before the navigation map
## has synced (the first physics frame) the point is returned as it is.
func on_navmesh(point: Vector3) -> Vector3:
	if NavigationServer3D.map_get_iteration_id(nav_map()) == 0:
		return point
	return NavigationServer3D.map_get_closest_point(nav_map(), point)


func _add_trees(trees: Array[Dictionary]) -> void:
	for tree: Dictionary in trees:
		var ground: Vector3 = ground_at(tree["pos"])
		_region.add_child(Props.tree(ground, tree["kind"], float(tree["scale"]), _rng))
		tree_spots.append(ground)
		cover_objects.append({ "pos": ground, "radius": Props.TRUNK_RADIUS * float(tree["scale"]) })


func _add_rocks_and_logs(layout: Dictionary) -> void:
	for rock: Dictionary in layout["rocks"]:
		var size := Vector3(float(rock["size"][0]), float(rock["size"][1]), float(rock["size"][2]))
		var ground: Vector3 = ground_at(Tuning.vec2(rock["pos"]))
		_region.add_child(Props.rock(ground, size, _rng))
		cover_objects.append({ "pos": ground, "radius": minf(size.x, size.z) * 0.5 })
	for log_spec: Dictionary in layout["logs"]:
		var ground: Vector3 = ground_at(Tuning.vec2(log_spec["pos"]))
		_region.add_child(Props.fallen_log(ground, float(log_spec["length"]), float(layout["log_radius"]),
				float(log_spec["yaw"])))


func _add_walls() -> void:
	var walls := StaticBody3D.new()
	walls.name = "ArenaEdge"
	walls.collision_layer = Layers.OBSTACLE
	walls.collision_mask = 0
	_region.add_child(walls)
	var length: float = half_size * 2.0 + WALL_THICKNESS * 2.0
	for side: Vector3 in [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]:
		var box := BoxShape3D.new()
		var along_x: bool = absf(side.z) > 0.0
		box.size = Vector3(length if along_x else WALL_THICKNESS, WALL_HEIGHT, WALL_THICKNESS if along_x else length)
		var collider := CollisionShape3D.new()
		collider.shape = box
		collider.position = side * (half_size + WALL_THICKNESS * 0.5)
		walls.add_child(collider)


func _add_hiding_spots(layout: Dictionary) -> void:
	var holder := Node3D.new()
	holder.name = "HidingSpots"
	add_child(holder)
	for bush: Dictionary in layout["bushes"]:
		var ground: Vector3 = ground_at(Tuning.vec2(bush["pos"]))
		hiding_spots.append(Foliage.bush(ground, float(bush["radius"]), _rng))
	var density: float = float(layout["grass_blades_per_m2"])
	for patch: Dictionary in layout["grass"]:
		var ground: Vector3 = ground_at(Tuning.vec2(patch["pos"]))
		hiding_spots.append(Foliage.tall_grass(ground, float(patch["radius"]), density, _rng, shape))
	for spot: HidingSpot in hiding_spots:
		holder.add_child(spot)


func _bake_navigation() -> void:
	var mesh := NavigationMesh.new()
	mesh.agent_radius = AGENT_RADIUS
	mesh.agent_height = AGENT_HEIGHT
	mesh.agent_max_climb = AGENT_MAX_CLIMB
	mesh.agent_max_slope = AGENT_MAX_SLOPE
	mesh.cell_size = NAV_CELL_SIZE
	mesh.cell_height = NAV_CELL_HEIGHT
	mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	mesh.geometry_collision_mask = Layers.SIGHT_BLOCKERS
	mesh.filter_baking_aabb = AABB(Vector3(-half_size, -NAV_VERTICAL_SPAN, -half_size),
			Vector3(half_size * 2.0, NAV_VERTICAL_SPAN * 2.0, half_size * 2.0))
	_region.navigation_mesh = mesh
	_region.bake_navigation_mesh(false)
