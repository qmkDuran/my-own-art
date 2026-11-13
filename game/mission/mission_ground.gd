class_name MissionGround
extends Node3D
## The Gloomwood's ground from data/mission.json: a mossy forest floor, a winding dirt path from town through the
## gate to the boss's ring, a rise with ruins on it (a raised block with ramps), boulders and fallen logs for cover,
## broken brick walls, and the woods' edge: invisible walls hidden behind rows of dense trees (the gate's opening
## left free).

const FLOOR_SHADER: Shader = preload("res://shaders/forest_floor.gdshader")
const PATH_SHADER: Shader = preload("res://shaders/path_dirt.gdshader")
const FLOOR_THICKNESS: float = 1.0
const PATH_LIFT: float = 0.02
const MEADOW_DROP: float = 0.06
const EDGE_HEIGHT: float = 10.0
const EDGE_WIDTH: float = 0.6
const ROCK: Color = Color(0.2, 0.21, 0.2)
const BARK: Color = Color(0.2, 0.13, 0.08)
const EARTH: Color = Color(0.16, 0.12, 0.09)
const ROCK_SQUASH: Vector3 = Vector3(1.0, 0.7, 0.9)
const ROCK_BOX: Vector3 = Vector3(1.5, 1.3, 1.4)
const LOG_RADIUS: float = 0.35
const JITTER: float = 0.3
const ROCK_VARIETY: float = 0.1

var _rng := RandomNumberGenerator.new()


func build(library: AssetLibrary) -> void:
	name = "MissionGround"
	var spec: Dictionary = Tuning.doc("mission")
	_rng.seed = int(spec["edge_trees"]["seed"])
	_floor(spec["floor"])
	_path(spec["path"])
	_plateau(spec["plateau"])
	for rock: Array in spec["rocks"]:
		_rock(Vector3(float(rock[0]), 0.0, float(rock[1])), float(rock[2]))
	for log_spec: Array in spec["logs"]:
		_log(Vector3(float(log_spec[0]), 0.0, float(log_spec[1])), deg_to_rad(float(log_spec[2])), float(log_spec[3]))
	for wall: Array in spec["walls"]:
		var size := Vector3(float(wall[3]), float(wall[4]), float(wall[5]))
		var holder: Node3D = Blocks.box(self, Vector3(float(wall[0]), float(wall[1]) + size.y * 0.5, float(wall[2])),
			size, SurfaceMaterials.stone("bricks"), true)
		holder.rotation.y = deg_to_rad(float(wall[6]))
	_edge(spec["boundary"], library, spec["edge_trees"])


func _floor(rect: Array) -> void:
	var size := Vector2(float(rect[2]) - float(rect[0]), float(rect[3]) - float(rect[1]))
	var centre := Vector3(float(rect[0]) + size.x * 0.5, 0.0, float(rect[1]) + size.y * 0.5)
	var plane := PlaneMesh.new()
	plane.size = size
	var material := ShaderMaterial.new()
	material.shader = FLOOR_SHADER
	plane.material = material
	var mesh := MeshInstance3D.new()
	mesh.mesh = plane
	mesh.position = centre
	add_child(mesh)
	var body: Node3D = Blocks.box(self, centre - Vector3.UP * FLOOR_THICKNESS * 0.5, Vector3(size.x, FLOOR_THICKNESS,
		size.y), null, true)
	Blocks.mark_surface(body, "grass")


## The path: one soft-edged dirt strip per leg, laid on whichever ground is under it.
func _path(spec: Dictionary) -> void:
	var points: Array = spec["points"]
	var material := ShaderMaterial.new()
	material.shader = PATH_SHADER
	material.set_shader_parameter("dirt", Tuning.color(spec["color"]))
	material.set_shader_parameter("edge", float(spec["edge"]))
	for index: int in points.size() - 1:
		var a: Vector3 = Tuning.point(points[index])
		var b: Vector3 = Tuning.point(points[index + 1])
		var strip := PlaneMesh.new()
		strip.size = Vector2(float(spec["width"]), a.distance_to(b) + float(spec["width"]))
		strip.material = material
		var mesh := MeshInstance3D.new()
		mesh.mesh = strip
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mesh)
		var middle: Vector3 = (a + b) * 0.5
		mesh.position = Vector3(middle.x, ground_height(middle) + PATH_LIFT * (1 + index % 2), middle.z)
		mesh.basis = Basis.looking_at(a.direction_to(b), Vector3.UP)


## The ground height at a point (the town's cobbles and the woods' floor at 0, the meadow a little lower).
static func ground_height(at: Vector3) -> float:
	var floor_rect: Array = Tuning.doc("mission")["floor"]
	var bounds: Array = Tuning.doc("town")["bounds"]
	for rect: Array in [floor_rect, bounds]:
		if at.x >= float(rect[0]) and at.x <= float(rect[2]) and at.z >= float(rect[1]) and at.z <= float(rect[3]):
			return 0.0
	return -MEADOW_DROP


func _plateau(spec: Dictionary) -> void:
	var centre: Vector3 = Tuning.vec3(spec["center"])
	var size: Vector3 = Tuning.vec3(spec["size"])
	var holder: Node3D = Blocks.box(self, centre + Vector3.UP * size.y * 0.5, size, SurfaceMaterials.stone("bricks"),
		true)
	Blocks.mark_surface(holder, "cobbles")
	var earth: StandardMaterial3D = Outskirts.flat(EARTH)
	for ramp: Array in spec["ramps"]:
		var from := Vector3(float(ramp[0]), float(ramp[1]), float(ramp[2]))
		var to := Vector3(float(ramp[3]), float(ramp[4]), float(ramp[5]))
		var body: StaticBody3D = Blocks.ramp(self, from, to, float(ramp[6]))
		var mesh := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = ((body.get_child(0) as CollisionShape3D).shape as BoxShape3D).size
		box.material = earth
		mesh.mesh = box
		body.add_child(mesh)


func _rock(at: Vector3, size: float) -> void:
	var sphere := SphereMesh.new()
	sphere.radius = size * 0.5
	sphere.height = size
	sphere.material = Outskirts.flat(ROCK)
	var mesh := MeshInstance3D.new()
	mesh.mesh = sphere
	mesh.scale = ROCK_SQUASH * (1.0 + _rng.randf_range(-1.0, 1.0) * ROCK_VARIETY)
	mesh.rotation.y = _rng.randf() * TAU
	var box := Vector3(size, size * ROCK_SQUASH.y, size * ROCK_SQUASH.z) * ROCK_BOX * 0.5
	var holder: Node3D = Blocks.box(self, at + Vector3.UP * box.y * 0.5, box, null, true)
	holder.add_child(mesh)


func _log(at: Vector3, yaw: float, length: float) -> void:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = LOG_RADIUS
	cylinder.bottom_radius = LOG_RADIUS
	cylinder.height = length
	cylinder.material = Outskirts.flat(BARK)
	var mesh := MeshInstance3D.new()
	mesh.mesh = cylinder
	mesh.rotation.z = PI * 0.5
	var holder: Node3D = Blocks.box(self, at + Vector3.UP * LOG_RADIUS, Vector3(length, LOG_RADIUS * 2.0,
		LOG_RADIUS * 2.0), null, true)
	holder.rotation.y = yaw
	holder.add_child(mesh)


## The woods' edge: an invisible wall along each boundary edge (the last one is the gate's opening), behind rows
## of trees: Meshy trees in front, simple dark trees behind.
func _edge(boundary: Array, library: AssetLibrary, spec: Dictionary) -> void:
	var points: Array[Vector3] = []
	for point: Array in boundary:
		points.append(Tuning.point(point))
	var centre := Vector3.ZERO
	for point: Vector3 in points:
		centre += point / points.size()
	var near: Array[Transform3D] = []
	var far: Array[Transform3D] = []
	for index: int in points.size() - 1:
		var a: Vector3 = points[index]
		var b: Vector3 = points[index + 1]
		Blocks.wall_between(self, a, b, EDGE_HEIGHT, EDGE_WIDTH, null)
		var out: Vector3 = a.direction_to(b).cross(Vector3.UP)
		if out.dot((a + b) * 0.5 - centre) < 0.0:
			out = -out
		_tree_row(a, b, out, spec, near, far)
	var meshy: Dictionary = Outskirts.meshy_tree(library)
	var front: MultiMeshInstance3D = Outskirts.trees(meshy["mesh"], near)
	front.material_override = meshy["material"]
	Outskirts.bake_offset(front, meshy["offset"])
	add_child(front)
	add_child(Outskirts.trees(Outskirts.lollipop_tree(float(spec["height"])), far))


func _tree_row(a: Vector3, b: Vector3, out: Vector3, spec: Dictionary, near: Array[Transform3D],
		far: Array[Transform3D]) -> void:
	var rows: Array = spec["rows"]
	var count: int = int(a.distance_to(b) / float(spec["spacing"]))
	for row: int in rows.size():
		for index: int in count + 1:
			var along: float = (index + _rng.randf_range(-JITTER, JITTER)) / maxf(count, 1.0)
			var at: Vector3 = a.lerp(b, clampf(along, 0.0, 1.0)) + out * float(rows[row])
			var size: float = _rng.randf_range(float(spec["scale_min"]), float(spec["scale_max"]))
			var placed := Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * size), at)
			if row < int(spec["meshy_rows"]):
				near.append(placed)
			else:
				far.append(placed)
