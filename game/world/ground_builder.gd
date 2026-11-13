class_name GroundBuilder
extends Node3D
## Builds the code-made ground of the town from data/town.json: the cobbled streets, the canal (walls, floor and
## water), the low stone parapets, stone blocks (the overlook terrace and fillers), the steps up to the overlook,
## the iron railings around it, and the walkable deck of the stone bridge.

const FLOOR_THICKNESS: float = 1.0
const RAMP_THICKNESS: float = 0.5
const RAIL_POST_SPACING: float = 1.4
const RAIL_BAR: float = 0.07
const BRIDGE_WALL_HEIGHT: float = 1.1
const BRIDGE_WALL_WIDTH: float = 0.2
const CANAL_WALL: float = 0.6
const IRON_COLOUR: Color = Color(0.07, 0.065, 0.07)
const IRON_ROUGHNESS: float = 0.45
const IRON_METALLIC: float = 0.6

var _iron: StandardMaterial3D


func build() -> void:
	name = "Ground"
	var town: Dictionary = Tuning.doc("town")
	_iron = StandardMaterial3D.new()
	_iron.albedo_color = IRON_COLOUR
	_iron.roughness = IRON_ROUGHNESS
	_iron.metallic = IRON_METALLIC
	for rect: Array in town["ground"]:
		_ground_rect(rect)
	_canal(town["canal"])
	_parapets(town["parapets"], town["parapet"])
	for block: Dictionary in town["blocks"]:
		var material: ShaderMaterial = SurfaceMaterials.stone(block["pattern"])
		Blocks.box(self, Tuning.vec3(block["center"]), Tuning.vec3(block["size"]), material, true)
	for flight: Dictionary in town["steps"]:
		_steps(flight)
	_railings(town["railings"], town["railing"])
	_bridge_deck(town["bridge"])
	for probe: Dictionary in town["reflection_probes"]:
		_reflection_probe(Tuning.vec3(probe["center"]), Tuning.vec3(probe["size"]))


func _ground_rect(rect: Array) -> void:
	var size := Vector2(float(rect[2]) - float(rect[0]), float(rect[3]) - float(rect[1]))
	var centre := Vector3(float(rect[0]) + size.x * 0.5, 0.0, float(rect[1]) + size.y * 0.5)
	var plane := PlaneMesh.new()
	plane.size = size
	plane.material = SurfaceMaterials.stone("cobbles")
	var mesh := MeshInstance3D.new()
	mesh.mesh = plane
	mesh.position = centre
	add_child(mesh)
	var floor_size := Vector3(size.x, FLOOR_THICKNESS, size.y)
	Blocks.box(self, centre - Vector3.UP * FLOOR_THICKNESS * 0.5, floor_size, null, true)


func _canal(canal: Dictionary) -> void:
	var x0: float = canal["x0"]
	var x1: float = canal["x1"]
	var z0: float = canal["z0"]
	var z1: float = canal["z1"]
	var bottom: float = canal["floor_y"]
	var mid := Vector3((x0 + x1) * 0.5, bottom * 0.5, (z0 + z1) * 0.5)
	var length: float = x1 - x0
	var span: float = z1 - z0
	var half_wall: float = CANAL_WALL * 0.5
	var bricks: ShaderMaterial = SurfaceMaterials.stone("bricks")
	var long_wall := Vector3(length, -bottom, CANAL_WALL)
	var end_wall := Vector3(CANAL_WALL, -bottom, span)
	Blocks.box(self, Vector3(mid.x, mid.y, z0 - half_wall), long_wall, bricks, false)
	Blocks.box(self, Vector3(mid.x, mid.y, z1 + half_wall), long_wall, bricks, false)
	Blocks.box(self, Vector3(x0 - half_wall, mid.y, mid.z), end_wall, bricks, false)
	Blocks.box(self, Vector3(x1 + half_wall, mid.y, mid.z), end_wall, bricks, false)
	Blocks.box(self, Vector3(mid.x, bottom - half_wall, mid.z), Vector3(length, CANAL_WALL, span), bricks, true)
	var water := PlaneMesh.new()
	water.size = Vector2(length, span)
	water.material = SurfaceMaterials.water()
	var surface := MeshInstance3D.new()
	surface.name = "CanalWater"
	surface.mesh = water
	surface.position = Vector3(mid.x, float(canal["water_y"]), mid.z)
	add_child(surface)


func _parapets(lines: Array, look: Dictionary) -> void:
	var height: float = look["height"]
	var width: float = look["width"]
	for line: Array in lines:
		var a := Vector3(float(line[0]), 0.0, float(line[1]))
		var b := Vector3(float(line[2]), 0.0, float(line[3]))
		Blocks.wall_between(self, a, b, height, width, SurfaceMaterials.stone("bricks"))


## Iron railings between two points (each end has its own height, so a railing can follow a flight of steps):
## posts, a top bar, and an invisible wall so nobody falls off.
func _railings(lines: Array, look: Dictionary) -> void:
	var height: float = look["height"]
	for line: Array in lines:
		var a: Vector3 = Tuning.vec3(line.slice(0, 3))
		var b: Vector3 = Tuning.vec3(line.slice(3, 6))
		var posts: int = maxi(1, int(a.distance_to(b) / RAIL_POST_SPACING))
		for index: int in posts + 1:
			var at: Vector3 = a.lerp(b, float(index) / posts)
			Blocks.box(self, at + Vector3.UP * height * 0.5, Vector3(RAIL_BAR, height, RAIL_BAR), _iron, false)
			if index < posts:
				var next: Vector3 = a.lerp(b, float(index + 1) / posts)
				var bar := Vector3(RAIL_BAR, RAIL_BAR, at.distance_to(next))
				var mid: Vector3 = (at + next) * 0.5 + Vector3.UP * height
				Blocks.box(self, mid, bar, _iron, false, at.direction_to(next))
				Blocks.wall_between(self, at, next, height, RAIL_BAR, null)


func _steps(flight: Dictionary) -> void:
	var from: Vector3 = Tuning.vec3(flight["from"])
	var to: Vector3 = Tuning.vec3(flight["to"])
	var width: float = flight["width"]
	var count: int = int(flight["count"])
	var run := Vector3(to.x - from.x, 0.0, to.z - from.z)
	var rise: float = to.y - from.y
	var tread: float = run.length() / count
	for index: int in count:
		var top: float = rise * (index + 1) / count
		var centre: Vector3 = from + run * ((index + 0.5) / count) + Vector3.UP * top * 0.5
		Blocks.box(self, centre, Vector3(width, top, tread), SurfaceMaterials.stone("bricks"), false, run.normalized())
	_ramp(from, to, width)


func _bridge_deck(bridge: Dictionary) -> void:
	var centre := Vector3(float(bridge["center"][0]), 0.0, float(bridge["center"][1]))
	var along: Vector3 = Vector3.FORWARD.rotated(Vector3.UP, deg_to_rad(float(bridge["rot"])))
	var half: Vector3 = along * float(bridge["length"]) * 0.5
	var top: Vector3 = centre + Vector3.UP * float(bridge["peak"])
	var width: float = bridge["width"]
	_ramp(centre - half, top, width)
	_ramp(top, centre + half, width)
	var side: Vector3 = along.cross(Vector3.UP) * (width * 0.5 + BRIDGE_WALL_WIDTH)
	for sign: float in [-1.0, 1.0]:
		var a: Vector3 = centre - half + side * sign
		var b: Vector3 = centre + half + side * sign
		Blocks.wall_between(self, a, b, BRIDGE_WALL_HEIGHT + float(bridge["peak"]), BRIDGE_WALL_WIDTH, null)


## Captures the lit town once, so wet stones and the canal mirror windows and lamps even where screen-space
## reflections cannot see.
func _reflection_probe(centre: Vector3, size: Vector3) -> void:
	var probe := ReflectionProbe.new()
	probe.size = size
	probe.box_projection = true
	probe.update_mode = ReflectionProbe.UPDATE_ONCE
	probe.ambient_mode = ReflectionProbe.AMBIENT_DISABLED
	probe.max_distance = size.length()
	add_child(probe)
	probe.position = centre


## A walkable slope whose top surface runs from one point to another.
func _ramp(from: Vector3, to: Vector3, width: float) -> void:
	var direction: Vector3 = from.direction_to(to)
	var body: StaticBody3D = Blocks.solid(Vector3(width, RAMP_THICKNESS, from.distance_to(to)))
	add_child(body)
	var up: Vector3 = direction.cross(direction.cross(Vector3.UP)).normalized() * -1.0
	body.global_transform = Transform3D(Basis.looking_at(direction, up), (from + to) * 0.5 - up * RAMP_THICKNESS * 0.5)
