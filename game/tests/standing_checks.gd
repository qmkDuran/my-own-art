class_name StandingChecks
extends RefCounted
## Collision checks on where people can stand: nobody walks or jumps into the canal (probes hop at its edges, the
## bridge aside), nobody stands in mid-air on a prop (probes hop at every prop from four sides; wherever one ends
## up standing on a prop, its feet must be within 5 cm of the prop's visible top), and the player and the
## townsfolk stand on the floor.

const CANAL_XS: Array[float] = [-46.0, -38.0, -30.0, -22.0, -14.0, -7.0, 7.0, 14.0, 22.0, 28.0]
const QUAYS: Array[Vector2] = [Vector2(12.4, 13.8), Vector2(21.6, 20.2)]
const CANAL_MIDDLE: float = 17.0
const HOP_SECONDS: float = 2.5
const PROP_GAP: float = 0.9
const STAND_TOLERANCE: float = 0.05
const ON_GROUND: float = 0.1
const FOOT_RADIUS: float = 0.25
const FLOOR_TOLERANCE: float = 0.05
const SINK: float = -0.3

var suite: Node
var m: Main
var report: Array[String] = []
var failures: Array[String] = []


func _init(owner_suite: Node, main: Main) -> void:
	suite = owner_suite
	m = main


func run() -> void:
	await _canal_holds()
	await _props_hold()
	await _grounding()


func _probe(at: Vector3, goal: Vector3) -> ProbeBody:
	var probe := ProbeBody.new()
	m.add_child(probe)
	probe.global_position = at + Vector3.UP * ProbeBody.INSET
	probe.goal = goal
	probe.hopping = true
	return probe


func _canal_holds() -> void:
	var probes: Array[ProbeBody] = []
	for x: float in CANAL_XS:
		for quay: Vector2 in QUAYS:
			var probe: ProbeBody = _probe(Vector3(x, 0.0, quay.x), Vector3(x, 0.0, CANAL_MIDDLE))
			probe.set_meta("edge", quay.y)
			probes.append(probe)
	await suite.get_tree().create_timer(HOP_SECONDS).timeout
	var wet: int = 0
	for probe: ProbeBody in probes:
		var edge: float = probe.get_meta("edge")
		var inside: bool = absf(probe.global_position.z - CANAL_MIDDLE) < absf(edge - CANAL_MIDDLE)
		if inside or probe.global_position.y < SINK:
			wet += 1
			failures.append("canal: a hopping probe got into the canal at %s" % probe.global_position)
		probe.queue_free()
	report.append("canal: %d probes hopped at the canal's edges, %d got in" % [probes.size(), wet])


func _props_hold() -> void:
	var probes: Array[ProbeBody] = []
	for node: Node3D in m.town.placed:
		if not node is StaticBody3D or m.town.houses.has(node):
			continue
		var box: AABB = m.library.collision_box(node.get_meta("asset"), node.get_meta("scale"))
		for side: int in 4:
			var out: Vector3 = Vector3.FORWARD.rotated(Vector3.UP, TAU * side / 4.0)
			var reach: float = maxf(box.size.x, box.size.z) * 0.5 + PROP_GAP
			var probe: ProbeBody = _probe(node.global_position + out * reach, node.global_position)
			probe.set_meta("prop", node)
			probes.append(probe)
	await suite.get_tree().create_timer(HOP_SECONDS).timeout
	var floating: int = 0
	for probe: ProbeBody in probes:
		var prop: Node3D = probe.get_meta("prop")
		var feet: float = probe.global_position.y
		if probe.is_on_floor() and feet > prop.global_position.y + ON_GROUND:
			var top: float = _mesh_top_under(prop, probe.global_position)
			if absf(feet - top) > STAND_TOLERANCE:
				floating += 1
				failures.append("props: standing on %s with feet %.2f m above its visible top" % [prop.name,
					feet - top])
		probe.queue_free()
	report.append("props: %d probes hopped at %d props, %d stood in mid-air" % [probes.size(), probes.size() / 4,
		floating])


## The highest visible point of a prop under a foot (within a foot's radius).
static func _mesh_top_under(prop: Node3D, at: Vector3) -> float:
	var top: float = -INF
	for node: Node in prop.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node
		for surface: int in mesh.mesh.get_surface_count():
			for vertex: Vector3 in mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:
				var point: Vector3 = mesh.global_transform * vertex
				if Vector2(point.x - at.x, point.z - at.z).length() < FOOT_RADIUS:
					top = maxf(top, point.y)
	return top


## The player and every townsperson walking about stand on the floor (within 5 cm).
func _grounding() -> void:
	m.player.global_position = Vector3(-20.0, ProbeBody.INSET, 0.0)
	for frame: int in 20:
		await suite.get_tree().physics_frame
	var people: Array[Node3D] = [m.player]
	for person: Townsperson in m.townsfolk:
		if person.seat_bench == null:
			people.append(person)
	for person: Node3D in people:
		var floor_y: float = _floor_under(person.global_position)
		var gap: float = person.global_position.y - floor_y
		report.append("grounding: %s stands %.3f m above the floor" % [person.name, gap])
		if absf(gap) > FLOOR_TOLERANCE:
			failures.append("%s floats or sinks %.2f m off the floor" % [person.name, gap])


func _floor_under(at: Vector3) -> float:
	var query := PhysicsRayQueryParameters3D.create(at + Vector3.UP, at + Vector3.DOWN * 2.0, Layers.WORLD)
	query.exclude = [m.player.get_rid()]
	var hit: Dictionary = m.get_world_3d().direct_space_state.intersect_ray(query)
	while not hit.is_empty() and (hit["collider"] as Node).get_meta("invisible_wall", false):
		query.exclude = query.exclude + [(hit["collider"] as CollisionObject3D).get_rid()]
		hit = m.get_world_3d().direct_space_state.intersect_ray(query)
	return float(hit["position"].y) if not hit.is_empty() else -INF
