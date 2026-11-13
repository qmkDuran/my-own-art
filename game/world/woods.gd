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
## Spots grown during a fight get ids from here up, so they never clash with the layout's remembered spots.
const DYNAMIC_SPOT_IDS: int = 1000

var shape: TerrainShape
var features: WoodsFeatures
var spawner: WoodsSpawner
var hiding_spots: Array[HidingSpot] = []
var cover_objects: Array[Dictionary] = []
var patrol_points: Array[Vector3] = []
var tree_spots: Array[Vector3] = []
var player_spawn: Vector3
var bot_spawn: Vector3
var half_size: float
var _region: NavigationRegion3D
var _tree_art: Dictionary = {}
var _forest_art: ForestArt
var _hollow_spots: Array[HidingSpot] = []
var _rng := RandomNumberGenerator.new()


func build() -> void:
	var layout: Dictionary = Tuning.woods
	_rng.seed = int(layout["seed"])
	half_size = float(layout["arena_half_size"])
	shape = TerrainShape.new(layout["terrain"])
	features = WoodsFeatures.new(layout, ground_at)
	spawner = WoodsSpawner.new(self)
	_region = NavigationRegion3D.new()
	_region.name = "Navigation"
	add_child(_region)
	_region.add_child(TerrainBuilder.build(shape, layout["terrain"], layout["clearings"], features))
	_add_trees(ForestScatter.new(layout, shape, _rng).plan())
	_add_rocks_and_logs(layout)
	_add_hollow_logs(layout)
	_add_walls()
	_add_hiding_spots(layout)
	Atmosphere.build(self, shape)
	Water.build(self, self)
	Undergrowth.build(self, self, _rng)
	AmbientLife.build(self, self)
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


func soft_at(point: Vector3) -> bool:
	return features.soft_at(point)


func water_at(point: Vector3) -> bool:
	return features.water_at(point)


func climbable_near(point: Vector3, reach: float) -> Vector3:
	return features.climbable_near(point, reach)


## Soft soil near a point (a ground point in the nearest patch), or Vector3.INF.
func soft_spot_near(point: Vector3, reach: float) -> Vector3:
	var centre: Vector2 = features.soft_centre_near(point, reach)
	return Vector3.INF if centre == Vector2.INF else ground_at(centre)


func jump_spots_near(point: Vector3, reach: float) -> Array[Dictionary]:
	return features.jump_spots_near(point, reach)


## Leaves shake when something climbs: a quick wobble of the tree's crown.
func shake_tree_at(trunk: Vector3) -> void:
	for key: Vector3 in _tree_art:
		if Vector2(key.x - trunk.x, key.z - trunk.z).length() < Props.TRUNK_RADIUS * 2.0:
			_forest_art.shake(_tree_art[key])


func ignite_at(point: Vector3) -> void:
	spawner.ignite_at(point)


func ignite_around(centre: Vector3, radius: float) -> void:
	spawner.ignite_around(centre, radius)


func douse_at(point: Vector3) -> void:
	spawner.douse_at(point)


func spawn_mud(at: Vector3) -> void:
	spawner.spawn_mud(at)


func spawn_smoke(at: Vector3, size: float, lifetime: float) -> void:
	spawner.spawn_smoke(at, size, lifetime)


func spawn_wall(at: Vector3, facing: Vector3, width: float, lifetime: float) -> void:
	spawner.spawn_wall(at, facing, width, lifetime)


func spawn_grass(at: Vector3, size: float, lifetime: float) -> void:
	spawner.spawn_grass(at, size, lifetime)


func add_hiding_spot(spot: HidingSpot) -> void:
	spot.spot_id = hiding_spots.size() + DYNAMIC_SPOT_IDS
	hiding_spots.append(spot)
	get_node("HidingSpots").add_child(spot)


func remove_hiding_spot(spot: HidingSpot) -> void:
	hiding_spots.erase(spot)
	if is_instance_valid(spot):
		spot.queue_free()


func _add_trees(trees: Array[Dictionary]) -> void:
	_forest_art = ForestArt.new()
	_forest_art.setup(int(Tuning.woods["seed"]))
	add_child(_forest_art)
	var every: int = int(Tuning.woods["trees"]["climbable_every"])
	var inner: float = float(Tuning.woods["trees"]["ring_from"])
	for index: int in trees.size():
		var tree: Dictionary = trees[index]
		var ground: Vector3 = ground_at(tree["pos"])
		var scale: float = float(tree["scale"])
		var climbable: bool = index % every == 0 and maxf(absf(ground.x), absf(ground.z)) < inner
		_region.add_child(Props.tree_body(ground, tree["kind"], scale))
		var art_index: int = _forest_art.add_tree(ground, tree["kind"], scale, _rng.randf() * TAU, climbable)
		tree_spots.append(ground)
		cover_objects.append({ "pos": ground, "radius": Props.TRUNK_RADIUS * scale })
		if climbable:
			features.climbable.append(ground)
			_tree_art[ground] = art_index
	_forest_art.finish()


func _add_rocks_and_logs(layout: Dictionary) -> void:
	for rock: Dictionary in layout["rocks"]:
		var size := Vector3(float(rock["size"][0]), float(rock["size"][1]), float(rock["size"][2]))
		var ground: Vector3 = ground_at(Tuning.vec2(rock["pos"]))
		_region.add_child(Props.rock(ground, size, _rng))
		cover_objects.append({ "pos": ground, "radius": minf(size.x, size.z) * 0.5 })
	for log_spec: Dictionary in layout["logs"]:
		var centre: Vector2 = Tuning.vec2(log_spec["pos"])
		var half: Vector2 = Vector2.from_angle(-deg_to_rad(float(log_spec["yaw"]))) * float(log_spec["length"]) * 0.5
		_region.add_child(Props.fallen_log(ground_at(centre - half), ground_at(centre + half),
				float(layout["log_radius"])))


## Hollow logs: solid shells to crawl into, each with a hiding spot in its middle.
func _add_hollow_logs(layout: Dictionary) -> void:
	var radius: float = float(layout["hollow_log_radius"])
	for log_spec: Dictionary in layout["hollow_logs"]:
		var centre: Vector2 = Tuning.vec2(log_spec["pos"])
		var half: Vector2 = Vector2.from_angle(-deg_to_rad(float(log_spec["yaw"]))) * float(log_spec["length"]) * 0.5
		_region.add_child(Props.hollow_log(ground_at(centre - half), ground_at(centre + half), radius))
		var inside := HidingSpot.new()
		inside.setup("log", radius + Creature.BODY_RADIUS)
		inside.position = ground_at(centre)
		_hollow_spots.append(inside)


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
	hiding_spots.append_array(_hollow_spots)
	var density: float = float(layout["grass_blades_per_m2"])
	for patch: Dictionary in layout["grass"]:
		var ground: Vector3 = ground_at(Tuning.vec2(patch["pos"]))
		hiding_spots.append(Foliage.tall_grass(ground, float(patch["radius"]), density, _rng, shape))
	for index: int in hiding_spots.size():
		hiding_spots[index].spot_id = index
		holder.add_child(hiding_spots[index])


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
