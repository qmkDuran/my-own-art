extends Node
## --collision [--long]: the collision and clipping suite. Walls hold (probes run into every solid thing from 8
## directions), a random-walk sweep of the whole town (always on walkable ground, never inside geometry, never
## below the floor, never stuck), the bridge and the steps crossed both ways, the camera never inside a building,
## the old man's seat, walking creatures kept out of houses, spawn spots reachable, plus the static layout checks.
## Prints COLLISION PASS or COLLISION FAIL lines.

const DIRECTIONS: int = 8
const APPROACH_GAP: float = 1.5
const CHARGE_SECONDS: float = 1.5
const SWEEP_PROBES: int = 40
const SWEEP_SECONDS: float = 20.0
const LONG_SWEEP_SECONDS: float = 180.0
const CHECK_EVERY: float = 0.25
## Stuck means no way out: a still probe tries each of the 8 directions in turn for STUCK_SECONDS.
const STUCK_SECONDS: float = 2.0
const STUCK_MOVE: float = 0.25
const BELOW_FLOOR: float = 0.2
const CROSSINGS: Array = [
	["bridge north to south", Vector3(0, 0, 11), Vector3(0, 0, 23.5)],
	["bridge south to north", Vector3(0, 0, 23.5), Vector3(0, 0, 11)],
	["steps up", Vector3(30, 0, 22.25), Vector3(47, 6, 22.25)],
	["steps down", Vector3(47, 6, 22.25), Vector3(30, 0, 22.25)],
]
const CROSS_SECONDS: float = 10.0
const ARRIVE: float = 0.8
const CAMERA_SPOTS: Array = [[-15.0, -2.6, 0.0], [-20.0, 2.6, 180.0], [14.0, -1.2, 0.0], [20.0, 1.2, 180.0],
	[3.0, -9.6, 0.0], [-11.0, 0.0, -90.0]]
const SEAT_TOLERANCE: float = 0.05
const SEAT_FACING: float = 0.9
const HIPS: String = "Hips"
const SPAWN_SAMPLES: int = 60
const SEED: int = 20261113

var m: Main
var failures: Array[String] = []
var report: Array[String] = []
var grid: WalkGrid


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	await get_tree().create_timer(0.5).timeout
	m = Main.current
	m.controller.enabled = false
	seed(SEED)
	grid = WalkGrid.new()
	grid.build(m.get_world_3d(), Tuning.point(Tuning.doc("town")["player_start"]["at"]))
	report.append("walk grid: %d standable cells, %d reachable" % [grid.floors.size(), grid.reachable.size()])
	var layout := LayoutCheck.new(m)
	layout.run()
	report.append_array(layout.report)
	failures.append_array(layout.failures)
	await _walls_hold()
	await _sweep()
	await _crossings()
	await _camera_probes()
	_seat_pose()
	var standing := StandingChecks.new(self, m)
	await standing.run()
	report.append_array(standing.report)
	failures.append_array(standing.failures)
	await _walkers_stay_out()
	_spawn_reachability()
	for line: String in report:
		print("COLLISION ", line)
	for failure: String in failures:
		print("COLLISION FAIL ", failure)
	if failures.is_empty():
		print("COLLISION PASS")
	get_tree().quit(0 if failures.is_empty() else 1)


func _probe(at: Vector3) -> ProbeBody:
	var probe := ProbeBody.new()
	m.add_child(probe)
	probe.global_position = at
	return probe


## Every solid box (houses, props, walls, parapets, railings), approached from 8 directions at run speed.
func _walls_hold() -> void:
	var probes: Array[ProbeBody] = []
	var skipped: int = 0
	for shape: CollisionShape3D in _solid_boxes():
		var half: Vector3 = (shape.shape as BoxShape3D).size * 0.5
		for index: int in DIRECTIONS:
			var angle: float = TAU * index / DIRECTIONS
			var local := Vector3(cos(angle) * (half.x + APPROACH_GAP), 0.0, sin(angle) * (half.z + APPROACH_GAP))
			var start: Vector3 = shape.global_transform * local
			var floor_y: float = grid.floor_at(start)
			if is_nan(floor_y):
				skipped += 1
				continue
			var probe: ProbeBody = _probe(Vector3(start.x, floor_y + ProbeBody.INSET, start.z))
			probe.goal = shape.global_position
			probes.append(probe)
	await get_tree().create_timer(CHARGE_SECONDS).timeout
	var inside: int = 0
	for probe: ProbeBody in probes:
		if probe.is_inside_geometry():
			inside += 1
			failures.append("walls hold: probe ended inside geometry at %s" % probe.global_position)
		probe.queue_free()
	report.append("walls hold: %d charges, %d ended inside, %d start spots not walkable (skipped)" % [probes.size(),
		inside, skipped])


func _solid_boxes() -> Array[CollisionShape3D]:
	var out: Array[CollisionShape3D] = []
	for node: Node in m.find_children("*", "CollisionShape3D", true, false):
		var shape: CollisionShape3D = node
		var body: Node = shape.get_parent()
		if not body is StaticBody3D or not shape.shape is BoxShape3D:
			continue
		var top: float = shape.global_position.y + (shape.shape as BoxShape3D).size.y * 0.5
		var flat: bool = absf(shape.global_basis.y.normalized().y) > 0.99
		if top > ProbeBody.INSET * 10.0 and flat:
			out.append(shape)
	return out


func _sweep() -> void:
	var seconds: float = LONG_SWEEP_SECONDS if OS.get_cmdline_user_args().has("--long") else SWEEP_SECONDS
	var cells: Array = grid.reachable.keys()
	var probes: Array[ProbeBody] = []
	for index: int in SWEEP_PROBES:
		var start: Vector3 = grid.centre_of(cells[randi() % cells.size()])
		var probe: ProbeBody = _probe(Vector3(start.x, grid.floor_at(start) + ProbeBody.INSET, start.z))
		probe.heading = Vector3.FORWARD.rotated(Vector3.UP, randf() * TAU)
		probe.set_meta("last", probe.global_position)
		probe.set_meta("still", 0.0)
		probes.append(probe)
	var problems: Dictionary = {}
	var elapsed: float = 0.0
	while elapsed < seconds:
		await get_tree().create_timer(CHECK_EVERY).timeout
		elapsed += CHECK_EVERY
		for probe: ProbeBody in probes:
			_sweep_check(probe, problems)
	for probe: ProbeBody in probes:
		probe.queue_free()
	report.append("sweep: %d probes for %.0f s, %d problems" % [SWEEP_PROBES, seconds, problems.size()])
	for key: String in problems:
		failures.append("sweep: " + key)


func _sweep_check(probe: ProbeBody, problems: Dictionary) -> void:
	var at: Vector3 = probe.global_position
	var where: String = "(%.0f, %.0f, %.0f)" % [at.x, at.y, at.z]
	if probe.is_inside_geometry():
		problems["inside geometry (%s) near %s" % [probe.get_meta("inside"), where]] = true
	var floor_y: float = grid.floor_near(at)
	if is_nan(floor_y):
		problems["off walkable ground near " + where] = true
	elif at.y < floor_y - BELOW_FLOOR:
		problems["below the floor near " + where] = true
	var moved: float = at.distance_to(probe.get_meta("last"))
	probe.set_meta("last", at)
	if moved < STUCK_MOVE * CHECK_EVERY:
		probe.heading = probe.heading.rotated(Vector3.UP, TAU / DIRECTIONS)
		probe.set_meta("still", float(probe.get_meta("still")) + CHECK_EVERY)
		if float(probe.get_meta("still")) > STUCK_SECONDS:
			problems["stuck for over 2 s near " + where] = true
	else:
		probe.set_meta("still", 0.0)
		if randf() < CHECK_EVERY / STUCK_SECONDS:
			probe.heading = Vector3.FORWARD.rotated(Vector3.UP, randf() * TAU)


func _crossings() -> void:
	for crossing: Array in CROSSINGS:
		var probe: ProbeBody = _probe(crossing[1] + Vector3.UP * ProbeBody.INSET)
		probe.goal = crossing[2]
		var waited: float = 0.0
		while waited < CROSS_SECONDS and Vector2(probe.global_position.x - crossing[2].x,
				probe.global_position.z - crossing[2].z).length() > ARRIVE:
			await get_tree().create_timer(CHECK_EVERY).timeout
			waited += CHECK_EVERY
		var arrived: bool = waited < CROSS_SECONDS and absf(probe.global_position.y - crossing[2].y) < 1.0
		report.append("crossing %s: %s in %.1f s" % [crossing[0], "made it" if arrived else "FAILED", waited])
		if not arrived:
			failures.append("could not cross: %s (stopped at %s)" % [crossing[0], probe.global_position])
		probe.queue_free()


func _camera_probes() -> void:
	var space: PhysicsDirectSpaceState3D = m.get_world_3d().direct_space_state
	for spot: Array in CAMERA_SPOTS:
		m.player.global_position = Vector3(spot[0], ProbeBody.INSET, spot[1])
		m.camera_rig.yaw = deg_to_rad(spot[2])
		m.camera_rig.snap()
		for frame: int in 6:
			await get_tree().physics_frame
		var eye: Vector3 = m.camera_rig.camera.global_position
		var query := PhysicsPointQueryParameters3D.new()
		query.position = eye
		query.collision_mask = Layers.WORLD
		if not space.intersect_point(query, 1).is_empty():
			failures.append("camera inside geometry at %s (player at %s)" % [eye, m.player.global_position])
	report.append("camera: %d probes against walls" % CAMERA_SPOTS.size())


## Every townsperson playing the sit clip sits on a real bench: hips at the right height over its seat top,
## facing the way the bench faces. A sit step with no bench nearby is skipped (never a sit in mid-air).
func _seat_pose() -> void:
	var clearance: float = float(Tuning.doc("npcs")["seat"]["hip_clearance"])
	var sitters: int = 0
	for person: Townsperson in m.townsfolk:
		if person.model.current_clip() != "sit":
			continue
		sitters += 1
		if person.seat_bench == null:
			failures.append("%s sits with no bench under them" % person.person_name)
			continue
		var skeleton: Skeleton3D = person.model.skeleton
		var hips: Vector3 = skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone(HIPS)).origin
		var above: float = hips.y - _seat_top(Townsperson.seat_spot(person.seat_bench)) - clearance
		var facing: float = -person.global_basis.z.dot(person.seat_bench.global_basis.z)
		report.append("bench: %s's hips sit %.3f m from the seat (clearance included), facing %.2f" % [
			person.person_name, above, facing])
		if absf(above) > SEAT_TOLERANCE or facing < SEAT_FACING:
			failures.append("%s sits %.2f m off the seat or faces away (%.2f)" % [person.person_name, above, facing])
	if sitters == 0:
		failures.append("nobody is sitting at the start (the old man should be on his bench)")
	_sit_without_bench()


func _sit_without_bench() -> void:
	var person := Townsperson.new()
	m.add_child(person)
	var spec: Dictionary = Tuning.doc("npcs")["townsfolk"][1].duplicate(true)
	person.setup(spec, [] as Array[Node3D])
	if person.model.current_clip() == "sit":
		failures.append("a townsperson sat down with no bench there")
	person.queue_free()


## The top of the bench seat under a point: the highest bench vertex near it below the backrest.
func _seat_top(at: Vector3) -> float:
	var top: float = -INF
	for node: Node3D in m.town.placed:
		if node.get_meta("asset", "") != "bench" or node.global_position.distance_to(at) > 1.0:
			continue
		for point: Vector3 in LayoutCheck.band_vertices(node):
			if Vector2(point.x - at.x, point.z - at.z).length() < 0.3 and point.y < node.global_position.y + 0.6:
				top = maxf(top, point.y)
	return top


## A pumpkin behind a row of houses chases the player in the street (through the open gaps between houses): it
## must never get inside a house on the way.
func _walkers_stay_out() -> void:
	m.start_night()
	m.night.set_physics_process(false)
	m.night.loadout.process_mode = Node.PROCESS_MODE_DISABLED
	m.player.global_position = Vector3(-28, ProbeBody.INSET, 0)
	var pumpkin: Creature = m.night.horde.spawn("pumpkin_head", Vector3(-28, 0.5, -14))
	var inside: int = 0
	for frame: int in 180:
		await get_tree().physics_frame
		var query := PhysicsPointQueryParameters3D.new()
		query.position = pumpkin.global_position + Vector3.UP * pumpkin.radius
		query.collision_mask = Layers.WORLD
		if not m.get_world_3d().direct_space_state.intersect_point(query, 1).is_empty():
			inside += 1
	report.append("walkers: a pumpkin chasing past a row of houses: inside geometry on %d of 180 frames, ended at %s"
		% [inside, pumpkin.global_position])
	if inside > 0:
		failures.append("a pumpkin got into a house")
	m.night.finish(true)
	m.night.loadout.process_mode = Node.PROCESS_MODE_INHERIT


func _spawn_reachability() -> void:
	var unreachable: int = 0
	var spots: Array[Vector3] = [Vector3(0, 0, 4), Vector3(-30, 0, 0), Vector3(20, 0, 0), Vector3(0, 0, 22)]
	for index: int in SPAWN_SAMPLES:
		m.player.global_position = spots[index % spots.size()]
		var at: Vector3 = m.night.spawner.free_spot()
		if at != Vector3.INF and not grid.is_reachable(at):
			unreachable += 1
			failures.append("spawn spot %s can't be walked to" % at)
	report.append("spawns: %d sampled, %d unreachable" % [SPAWN_SAMPLES, unreachable])
