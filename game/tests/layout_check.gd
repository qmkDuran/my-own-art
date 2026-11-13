class_name LayoutCheck
extends RefCounted
## Static layout checks for the collision suite: does each solid asset's collision box match its visible mesh at
## walking height (no walking into visible walls, no big invisible walls), do any two solid things interpenetrate,
## does anything float or sink, do the townsfolk's walking routes cross anything solid. Fills report lines and
## failures.

const OUTSIDE_TOLERANCE: float = 0.3
const OUTSIDE_SHARE: float = 0.05
const EMPTY_WARN: float = 0.6
const EMPTY_FAIL: float = 1.1
const OCCUPANCY_CELL: float = 0.25
const PERIMETER_STEP: float = 0.25
const OVERLAP_FAIL: float = 0.25
const FLOAT_TOLERANCE: float = 0.12
const ROUTE_STEP: float = 0.25
const ROUTE_RADIUS: float = 0.25
const ROUTE_HEIGHT: float = 0.9
const SEAT_CLEARANCE: float = 0.9
const NOT_GROUNDED: Array[String] = ["hanging_lantern", "bridge"]
const COPLANAR: float = 0.005

var m: Main
var report: Array[String] = []
var failures: Array[String] = []
var _first_blocked: String = ""


func _init(main: Main) -> void:
	m = main


func run() -> void:
	_clipping()
	_overlaps()
	_grounding()
	_npc_routes()
	_coplanar_tops()


## Solid placed assets (not the backdrop) with their collision shape.
func solids() -> Array[StaticBody3D]:
	var out: Array[StaticBody3D] = []
	for node: Node3D in m.town.placed:
		if node is StaticBody3D and not node.get_meta("backdrop", false):
			out.append(node)
	return out


static func shape_of(body: StaticBody3D) -> CollisionShape3D:
	for child: Node in body.get_children():
		if child is CollisionShape3D:
			return child
	return null


## The world-space vertices of a placed asset's meshes at walking height.
static func band_vertices(body: Node3D) -> PackedVector3Array:
	var low: float = Tuning.f("town", "collision_band_low") + body.global_position.y
	var high: float = Tuning.f("town", "collision_band_high") + body.global_position.y
	var out := PackedVector3Array()
	for node: Node in body.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node
		for surface: int in mesh.mesh.get_surface_count():
			for vertex: Vector3 in mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:
				var point: Vector3 = mesh.global_transform * vertex
				if point.y >= low and point.y <= high:
					out.append(point)
	return out


func _clipping() -> void:
	var worst_empty: float = 0.0
	for body: StaticBody3D in solids():
		var shape: CollisionShape3D = shape_of(body)
		var half: Vector3 = (shape.shape as BoxShape3D).size * 0.5
		var to_box: Transform3D = shape.global_transform.affine_inverse()
		var cells: Dictionary = {}
		var outside: int = 0
		var vertices: PackedVector3Array = band_vertices(body)
		for point: Vector3 in vertices:
			var local: Vector3 = to_box * point
			if absf(local.x) > half.x + OUTSIDE_TOLERANCE or absf(local.z) > half.z + OUTSIDE_TOLERANCE:
				outside += 1
			cells[Vector2i(int(floor(local.x / OCCUPANCY_CELL)), int(floor(local.z / OCCUPANCY_CELL)))] = true
		if outside > vertices.size() * OUTSIDE_SHARE:
			failures.append("%s at %s: %d visible vertices outside its collision box" % [body.name, body.position,
				outside])
		var empty: float = _largest_empty_edge(half, cells)
		worst_empty = maxf(worst_empty, empty)
		if empty > EMPTY_FAIL:
			failures.append("%s at %s: invisible wall %.2f m from the mesh" % [body.name, body.position, empty])
		elif empty > EMPTY_WARN:
			report.append("note: %s at %s has %.2f m of empty box edge" % [body.name, body.position, empty])
	report.append("clipping: %d solid assets checked, worst empty box edge %.2f m" % [solids().size(), worst_empty])


## How far the box's edge strays from the visible mesh: the largest distance from a point on the box outline to
## the nearest occupied cell.
func _largest_empty_edge(half: Vector3, cells: Dictionary) -> float:
	var worst: float = 0.0
	var corners: Array[Vector2] = [Vector2(-half.x, -half.z), Vector2(half.x, -half.z), Vector2(half.x, half.z),
		Vector2(-half.x, half.z)]
	for side: int in 4:
		var a: Vector2 = corners[side]
		var b: Vector2 = corners[(side + 1) % 4]
		var steps: int = maxi(1, int(a.distance_to(b) / PERIMETER_STEP))
		for index: int in steps + 1:
			worst = maxf(worst, _distance_to_cells(a.lerp(b, float(index) / steps), cells))
	return worst


func _distance_to_cells(at: Vector2, cells: Dictionary) -> float:
	var centre := Vector2i(int(floor(at.x / OCCUPANCY_CELL)), int(floor(at.y / OCCUPANCY_CELL)))
	for ring: int in int(EMPTY_FAIL * 2.0 / OCCUPANCY_CELL):
		for dx: int in range(-ring, ring + 1):
			for dz: int in range(-ring, ring + 1):
				if maxi(absi(dx), absi(dz)) == ring and cells.has(centre + Vector2i(dx, dz)):
					return maxf(ring - 1, 0) * OCCUPANCY_CELL
	return EMPTY_FAIL * 2.0


func _overlaps() -> void:
	var boxes: Array[CollisionShape3D] = []
	for body: StaticBody3D in solids():
		boxes.append(shape_of(body))
	var count: int = 0
	for i: int in boxes.size():
		for j: int in range(i + 1, boxes.size()):
			var depth: float = Obb2d.overlap(boxes[i], boxes[j])
			if depth > OVERLAP_FAIL and _heights_meet(boxes[i], boxes[j]):
				count += 1
				failures.append("overlap %.2f m: %s at %s and %s at %s" % [depth, boxes[i].get_parent().name,
					(boxes[i].get_parent() as Node3D).position, boxes[j].get_parent().name,
					(boxes[j].get_parent() as Node3D).position])
	report.append("overlaps: %d pairs of solid assets interpenetrate" % count)


func _heights_meet(a: CollisionShape3D, b: CollisionShape3D) -> bool:
	var a_half: float = (a.shape as BoxShape3D).size.y * 0.5
	var b_half: float = (b.shape as BoxShape3D).size.y * 0.5
	return absf(a.global_position.y - b.global_position.y) < a_half + b_half


func _grounding() -> void:
	var space: PhysicsDirectSpaceState3D = m.get_world_3d().direct_space_state
	var bad: int = 0
	for node: Node3D in m.town.placed:
		if node.get_meta("backdrop", false) or NOT_GROUNDED.has(node.get_meta("asset", "")):
			continue
		var from: Vector3 = node.global_position + Vector3.UP * WalkGrid.RAY_TOP
		var ray := PhysicsRayQueryParameters3D.create(from, node.global_position + Vector3.DOWN, Layers.WORLD)
		if node is StaticBody3D:
			ray.exclude = [(node as StaticBody3D).get_rid()]
		var hit: Dictionary = space.intersect_ray(ray)
		while not hit.is_empty() and (hit["collider"] as Node).get_meta("invisible_wall", false):
			ray.exclude = ray.exclude + [(hit["collider"] as CollisionObject3D).get_rid()]
			hit = space.intersect_ray(ray)
		var floor_y: float = (hit["position"] as Vector3).y if not hit.is_empty() else -INF
		if absf(floor_y - node.global_position.y) > FLOAT_TOLERANCE:
			bad += 1
			failures.append("%s at %s: base %.2f but the floor under it is %.2f" % [node.name, node.position,
				node.global_position.y, floor_y])
	report.append("grounding: %d assets float or sink" % bad)


## No visible box may have its top exactly on the street plane: the two would z-fight (flicker).
func _coplanar_tops() -> void:
	var fighting: int = 0
	for node: Node in m.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node
		if not mesh.mesh is BoxMesh or not mesh.is_visible_in_tree():
			continue
		var top: float = mesh.global_position.y + (mesh.mesh as BoxMesh).size.y * 0.5 * mesh.global_basis.y.length()
		if absf(top) < COPLANAR and absf(mesh.global_basis.y.normalized().y) > 0.99:
			fighting += 1
	report.append("z-fighting: %d boxes with their top on the street plane" % fighting)
	if fighting > 0:
		failures.append("%d visible boxes sit exactly on the street plane (z-fighting)" % fighting)


func _npc_routes() -> void:
	var space: PhysicsDirectSpaceState3D = m.get_world_3d().direct_space_state
	for spec: Dictionary in Tuning.doc("npcs")["townsfolk"]:
		var points: Array[Vector3] = [Tuning.point(spec["start"])]
		var seats: Array[Vector3] = []
		for step: Dictionary in spec["routine"]:
			if step.has("to"):
				points.append(Tuning.point(step["to"]))
			if step.has("at"):
				seats.append(Tuning.point(step["at"]))
		points.append(points[0])
		var blocked: int = 0
		for index: int in points.size() - 1:
			blocked += _blocked_points(space, points[index], points[index + 1], seats)
		report.append("route %s: %d blocked samples" % [spec["name"], blocked])
		if blocked > 0:
			report.append("  first blocked sample of %s: %s" % [spec["name"], _first_blocked])
			failures.append("%s's route crosses something solid at %d sample points" % [spec["name"], blocked])


func _blocked_points(space: PhysicsDirectSpaceState3D, a: Vector3, b: Vector3, seats: Array[Vector3]) -> int:
	var ball := SphereShape3D.new()
	ball.radius = ROUTE_RADIUS
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = ball
	query.collision_mask = Layers.WORLD
	var blocked: int = 0
	var steps: int = maxi(1, int(a.distance_to(b) / ROUTE_STEP))
	for index: int in steps + 1:
		var at: Vector3 = a.lerp(b, float(index) / steps)
		if _near_seat(at, seats):
			continue
		query.transform = Transform3D(Basis(), Vector3(at.x, ROUTE_HEIGHT, at.z))
		var hits: Array[Dictionary] = space.intersect_shape(query, 1)
		if not hits.is_empty():
			if blocked == 0:
				_first_blocked = "%s (%s)" % [at, (hits[0]["collider"] as Node).get_parent().name]
			blocked += 1
	return blocked


static func _near_seat(at: Vector3, seats: Array[Vector3]) -> bool:
	for seat: Vector3 in seats:
		if Vector2(seat.x - at.x, seat.z - at.z).length() < SEAT_CLEARANCE:
			return true
	return false
