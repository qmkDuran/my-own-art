class_name Props
## Builds the solid props of the woods: tree bodies (the trunk collider, plus a crown collider that only stops the
## camera; trees are drawn by ForestArt), mossy boulders, fallen logs and hollow logs you can crawl into. Trunks,
## rocks and logs are obstacles: they block movement, sight and shots.

const TRUNK_RADIUS: float = 0.32
const ROCK_LUMP: float = 0.18
const ROCK_SINK: float = 0.25
const ROUND_SEGMENTS: int = 9
const ROUND_RINGS: int = 5
const LOG_SEGMENTS: int = 10
const LOG_SINK: float = 0.8
const LOG_CAP_SHARE: float = 0.86
const LOG_CAP_THICKNESS: float = 0.02
const MOSS_SHARE: float = 0.85
const MOSS_HEIGHT: float = 0.35
const MOSS_LIFT: float = 0.32
const HOLLOW_WALL: float = 0.18
const HOLLOW_SEGMENTS: int = 14


static func tree_body(ground: Vector3, kind: String, scale: float) -> StaticBody3D:
	var body: StaticBody3D = _obstacle_body("Tree", ground)
	var trunk := CylinderShape3D.new()
	trunk.radius = TRUNK_RADIUS * scale
	trunk.height = TreeShapes.trunk_height(kind) * scale
	_add_shape(body, trunk, Vector3(0, trunk.height * 0.5, 0))
	var crown := StaticBody3D.new()
	crown.collision_layer = Layers.CANOPY
	crown.collision_mask = 0
	body.add_child(crown)
	var ball := SphereShape3D.new()
	var spec: Vector2 = TreeShapes.crown_ball(kind)
	ball.radius = spec.y * scale
	_add_shape(crown, ball, Vector3(0, spec.x * scale, 0))
	return body


static func rock(ground: Vector3, size: Vector3, rng: RandomNumberGenerator) -> StaticBody3D:
	var body: StaticBody3D = _obstacle_body("Rock", ground + Vector3(0, size.y * (0.5 - ROCK_SINK), 0))
	body.rotation.y = rng.randf() * TAU
	var sphere := SphereMesh.new()
	sphere.radial_segments = ROUND_SEGMENTS
	sphere.rings = ROUND_RINGS
	var mesh: ArrayMesh = FlatMesh.lumpy(sphere, rng, ROCK_LUMP)
	_add_view(body, mesh, WoodsMaterials.solid("rock"), Vector3.ZERO).scale = size
	var moss_mesh: ArrayMesh = FlatMesh.lumpy(sphere, rng, ROCK_LUMP)
	var moss_at := Vector3(0, size.y * MOSS_LIFT, 0)
	var moss: MeshInstance3D = _add_view(body, moss_mesh, WoodsMaterials.solid("moss_rock"), moss_at)
	moss.scale = Vector3(size.x * MOSS_SHARE, size.y * MOSS_HEIGHT, size.z * MOSS_SHARE)
	var shape := ConvexPolygonShape3D.new()
	var points := PackedVector3Array()
	for v: Vector3 in mesh.get_faces():
		points.append(v * size)
	shape.points = points
	_add_shape(body, shape, Vector3.ZERO)
	return body


## A log lying from one ground point to another, following the slope and sunk a little so nothing fits under it.
static func fallen_log(from: Vector3, to: Vector3, radius: float) -> StaticBody3D:
	var length: float = from.distance_to(to)
	var body: StaticBody3D = _obstacle_body("Log", (from + to) * 0.5 + Vector3.UP * radius * LOG_SINK)
	var lying: Basis = _lying(to - from)
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = length
	cylinder.radial_segments = LOG_SEGMENTS
	_add_view(body, cylinder, WoodsMaterials.solid("bark_dark"), Vector3.ZERO).basis = lying
	for end: float in [-1.0, 1.0]:
		var cap := CylinderMesh.new()
		cap.top_radius = radius * LOG_CAP_SHARE
		cap.bottom_radius = radius * LOG_CAP_SHARE
		cap.height = LOG_CAP_THICKNESS
		_add_view(body, cap, WoodsMaterials.solid("log_end"), lying.y * end * length * 0.5).basis = lying
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = length
	_add_shape(body, shape, Vector3.ZERO).basis = lying
	return body


## A big hollow log lying on the ground: open at both ends, walls and roof solid, room inside for a creature.
static func hollow_log(from: Vector3, to: Vector3, radius: float) -> StaticBody3D:
	var length: float = from.distance_to(to)
	var body: StaticBody3D = _obstacle_body("HollowLog", (from + to) * 0.5 + Vector3.UP * radius * LOG_SINK)
	var lying: Basis = _lying(to - from)
	var shell := CylinderMesh.new()
	shell.top_radius = radius
	shell.bottom_radius = radius
	shell.height = length
	shell.radial_segments = HOLLOW_SEGMENTS
	shell.cap_top = false
	shell.cap_bottom = false
	var material: StandardMaterial3D = WoodsMaterials.solid("bark_dark").duplicate()
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_add_view(body, shell, material, Vector3.ZERO).basis = lying
	var across: Vector3 = lying.y.cross(Vector3.UP).normalized()
	for side: float in [-1.0, 1.0]:
		_wall(body, across * side * radius, lying, length, Vector3(HOLLOW_WALL, radius * 2.0, length))
	_wall(body, Vector3.UP * radius, lying, length, Vector3(radius * 2.0, HOLLOW_WALL, length))
	return body


static func _wall(body: StaticBody3D, at: Vector3, lying: Basis, length: float, size: Vector3) -> void:
	var box := BoxShape3D.new()
	box.size = Vector3(size.x, size.y, length)
	var collider: CollisionShape3D = _add_shape(body, box, at)
	collider.basis = Basis(lying.y.cross(Vector3.UP).normalized(), Vector3.UP, lying.y).orthonormalized()


## A basis whose Y axis lies along `along` (cylinders are built along Y).
static func _lying(along: Vector3) -> Basis:
	var axis: Vector3 = along.normalized()
	var side: Vector3 = axis.cross(Vector3.UP).normalized()
	return Basis(side, axis, side.cross(axis))


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
