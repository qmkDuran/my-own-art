class_name Props
## Builds the solid props of the woods: trees (trunk plus pine or leafy canopy), boulders and fallen logs. Trunks,
## rocks and logs are obstacles (they block movement, sight and spit); canopies only stop the camera.

const TRUNK_RADIUS: float = 0.32
const TRUNK_HEIGHT: float = 7.0
const TRUNK_TAPER: float = 0.7
const PINE_TIERS: int = 3
const PINE_BASE_HEIGHT: float = 2.6
const PINE_TIER_RADIUS: float = 2.1
const PINE_TIER_HEIGHT: float = 2.6
const PINE_TIER_RISE: float = 1.45
const PINE_TIER_SHRINK: float = 0.28
const LEAFY_BLOBS: int = 3
const LEAFY_BASE_HEIGHT: float = 4.6
const LEAFY_RADIUS: float = 1.9
const LEAFY_SPREAD: float = 1.1
const CANOPY_LUMP: float = 0.14
const ROCK_LUMP: float = 0.18
const ROCK_SINK: float = 0.25
const CANOPY_COLLIDER_SHARE: float = 0.8
const ROUND_SEGMENTS: int = 9
const ROUND_RINGS: int = 5
const CONE_SEGMENTS: int = 8
const LOG_SEGMENTS: int = 10
const LOG_CAP_SHARE: float = 0.86
const LOG_CAP_THICKNESS: float = 0.02
const LEAFY_SQUASH: float = 1.7
const LEAFY_MIN_SIZE: float = 0.75
const LEAFY_MAX_LIFT: float = 0.8
const PINE_COLORS: Array[String] = ["pine", "pine_light"]
const LEAF_COLORS: Array[String] = ["leaf", "leaf_light", "leaf_warm"]


static func tree(ground: Vector3, kind: String, scale: float, rng: RandomNumberGenerator) -> StaticBody3D:
	var body: StaticBody3D = _obstacle_body("Tree", ground)
	body.rotation.y = rng.randf() * TAU
	var trunk := CylinderMesh.new()
	trunk.top_radius = TRUNK_RADIUS * scale * TRUNK_TAPER
	trunk.bottom_radius = TRUNK_RADIUS * scale
	trunk.height = TRUNK_HEIGHT * scale
	_add_view(body, trunk, WoodsMaterials.solid("bark"), Vector3(0, trunk.height * 0.5, 0))
	var trunk_shape := CylinderShape3D.new()
	trunk_shape.radius = TRUNK_RADIUS * scale
	trunk_shape.height = trunk.height
	_add_shape(body, trunk_shape, Vector3(0, trunk.height * 0.5, 0))
	var canopy := StaticBody3D.new()
	canopy.collision_layer = Layers.CANOPY
	canopy.collision_mask = 0
	body.add_child(canopy)
	if kind == "pine":
		_pine_canopy(canopy, scale, rng)
	else:
		_leafy_canopy(canopy, scale, rng)
	return body


static func rock(ground: Vector3, size: Vector3, rng: RandomNumberGenerator) -> StaticBody3D:
	var body: StaticBody3D = _obstacle_body("Rock", ground + Vector3(0, size.y * (0.5 - ROCK_SINK), 0))
	body.rotation.y = rng.randf() * TAU
	var sphere := SphereMesh.new()
	sphere.radial_segments = ROUND_SEGMENTS
	sphere.rings = ROUND_RINGS
	var mesh: ArrayMesh = FlatMesh.lumpy(sphere, rng, ROCK_LUMP)
	var view: MeshInstance3D = _add_view(body, mesh, WoodsMaterials.solid("rock"), Vector3.ZERO)
	view.scale = size
	var shape := ConvexPolygonShape3D.new()
	var points := PackedVector3Array()
	for v: Vector3 in mesh.get_faces():
		points.append(v * size)
	shape.points = points
	_add_shape(body, shape, Vector3.ZERO)
	return body


static func fallen_log(ground: Vector3, length: float, radius: float, yaw_degrees: float) -> StaticBody3D:
	var body: StaticBody3D = _obstacle_body("Log", ground + Vector3(0, radius, 0))
	body.rotation.y = deg_to_rad(yaw_degrees)
	var lying := Basis(Vector3.FORWARD, PI * 0.5)
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = length
	cylinder.radial_segments = LOG_SEGMENTS
	_add_view(body, cylinder, WoodsMaterials.solid("bark_dark"), Vector3.ZERO).basis = lying
	for side: float in [-1.0, 1.0]:
		var cap := CylinderMesh.new()
		cap.top_radius = radius * LOG_CAP_SHARE
		cap.bottom_radius = radius * LOG_CAP_SHARE
		cap.height = LOG_CAP_THICKNESS
		_add_view(body, cap, WoodsMaterials.solid("log_end"), Vector3(side * length * 0.5, 0, 0)).basis = lying
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = length
	var collider: CollisionShape3D = _add_shape(body, shape, Vector3.ZERO)
	collider.basis = lying
	return body


static func _pine_canopy(canopy: StaticBody3D, scale: float, rng: RandomNumberGenerator) -> void:
	var material: StandardMaterial3D = WoodsMaterials.solid(PINE_COLORS[rng.randi() % PINE_COLORS.size()])
	for tier: int in PINE_TIERS:
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = PINE_TIER_RADIUS * scale * (1.0 - tier * PINE_TIER_SHRINK)
		cone.height = PINE_TIER_HEIGHT * scale
		cone.radial_segments = CONE_SEGMENTS
		var y: float = (PINE_BASE_HEIGHT + tier * PINE_TIER_RISE) * scale + cone.height * 0.5
		_add_view(canopy, FlatMesh.lumpy(cone, rng, CANOPY_LUMP), material, Vector3(0, y, 0))
	var shape := SphereShape3D.new()
	shape.radius = PINE_TIER_RADIUS * scale * CANOPY_COLLIDER_SHARE
	_add_shape(canopy, shape, Vector3(0, (PINE_BASE_HEIGHT + PINE_TIER_RISE) * scale, 0))


static func _leafy_canopy(canopy: StaticBody3D, scale: float, rng: RandomNumberGenerator) -> void:
	var material: StandardMaterial3D = WoodsMaterials.solid(LEAF_COLORS[rng.randi() % LEAF_COLORS.size()])
	var centre := Vector3(0, LEAFY_BASE_HEIGHT * scale, 0)
	for blob: int in LEAFY_BLOBS:
		var sphere := SphereMesh.new()
		sphere.radius = LEAFY_RADIUS * scale * rng.randf_range(LEAFY_MIN_SIZE, 1.0)
		sphere.height = sphere.radius * LEAFY_SQUASH
		sphere.radial_segments = ROUND_SEGMENTS
		sphere.rings = ROUND_RINGS
		var angle: float = TAU * blob / LEAFY_BLOBS + rng.randf()
		var offset := Vector3(cos(angle), rng.randf_range(0.0, LEAFY_MAX_LIFT), sin(angle)) * LEAFY_SPREAD * scale
		_add_view(canopy, FlatMesh.lumpy(sphere, rng, CANOPY_LUMP), material, centre + offset)
	var shape := SphereShape3D.new()
	shape.radius = LEAFY_RADIUS * scale * CANOPY_COLLIDER_SHARE
	_add_shape(canopy, shape, centre)


static func _obstacle_body(label: String, at: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = label
	body.collision_layer = Layers.OBSTACLE
	body.collision_mask = 0
	body.position = at
	return body


static func _add_view(parent: Node3D, mesh: Mesh, material: Material, at: Vector3) -> MeshInstance3D:
	var view := MeshInstance3D.new()
	view.mesh = mesh
	view.material_override = material
	view.position = at
	parent.add_child(view)
	return view


static func _add_shape(parent: CollisionObject3D, shape: Shape3D, at: Vector3) -> CollisionShape3D:
	var collider := CollisionShape3D.new()
	collider.shape = shape
	collider.position = at
	parent.add_child(collider)
	return collider
