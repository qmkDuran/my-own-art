class_name TownBuilder
extends Node3D
## Places the Meshy town from data/town.json: rows of houses along the streets (each house turned to face the
## street, with lit windows), the distant backdrop rows, the props, the street lamps and wall lanterns with their
## lights, the fountain's water, the fish in the canal and the cat. Collects every light so the light budget and
## the lamp network can manage them.

var library: AssetLibrary
var lights: Array[OmniLight3D] = []
var lamps: Array[LampLight] = []
## Every placed asset (backdrop ones carry the "backdrop" meta), for the collision and layout tests.
var placed: Array[Node3D] = []
var cat: TownCat
var fountain: Node3D
var _rng := RandomNumberGenerator.new()


func build(asset_library: AssetLibrary) -> void:
	name = "Town"
	library = asset_library
	_rng.seed = Tuning.i("town", "seed")
	var town: Dictionary = Tuning.doc("town")
	for row: Dictionary in town["rows"]:
		_row(row, false)
	for row: Dictionary in town["backdrop_rows"]:
		_row(row, true)
	for prop: Dictionary in town["props"]:
		var node: Node3D = place(prop["asset"], Tuning.point(prop["at"]), _yaw(prop), 1.0, true)
		if prop["asset"] == "fountain":
			fountain = node
			node.add_child(FountainWater.new())
	var bridge: Dictionary = town["bridge"]
	var bridge_yaw: float = deg_to_rad(float(bridge["rot"]))
	var bridge_node: Node3D = place("bridge", Tuning.point(bridge["center"]), bridge_yaw, 1.0, false)
	bridge_node.position.y = float(bridge["base_y"])
	for lamp: Dictionary in town["street_lamps"]:
		_lamp("street_lamp", lamp)
	for lamp: Dictionary in town["hanging_lanterns"]:
		_lamp("hanging_lantern", lamp)
	var fish := CanalFish.new()
	add_child(fish)
	fish.build()
	cat = TownCat.new()
	cat.setup(library, town["cat"])
	add_child(cat)


## One asset at a ground point, turned by yaw (radians) and scaled.
func place(asset: String, at: Vector3, yaw: float, scale: float, collide: bool) -> Node3D:
	var node: Node3D = library.spawn(asset, scale, collide)
	add_child(node)
	node.position = at
	node.rotation.y = yaw
	placed.append(node)
	return node


func _row(row: Dictionary, backdrop: bool) -> void:
	var start: Vector3 = Tuning.point(row["start"])
	var end: Vector3 = Tuning.point(row["end"])
	var along: Vector3 = start.direction_to(end)
	var yaw: float = deg_to_rad(float(row["rot"]))
	var front := Vector3(sin(yaw), 0.0, cos(yaw))
	var types: Array = row["types"]
	var travelled: float = 0.0
	var index: int = 0
	var previous: Node3D = null
	while true:
		var asset: String = types[index % types.size()]
		var jitter: float = _rng.randf_range(-1.0, 1.0) * Tuning.f("town", "scale_jitter")
		var scale: float = float(row.get("scale", 1.0)) * (1.0 + jitter)
		var size: Vector3 = library.size_of(asset) * scale
		if travelled + size.x > start.distance_to(end) + Tuning.f("town", "row_overrun"):
			break
		var centre: Vector3 = start + along * (travelled + size.x * 0.5) - front * size.z * 0.5
		var turn: float = deg_to_rad(_rng.randf_range(-1.0, 1.0) * Tuning.f("town", "rot_jitter_deg"))
		var house: Node3D = place(asset, centre, yaw + turn, scale, not backdrop)
		house.set_meta("backdrop", backdrop)
		if not backdrop:
			_windows(house, asset, scale)
			if index > 0:
				_fill_gap(start + along * (travelled - Tuning.f("town", "gap")), start + along * travelled, front,
					size.z)
				_garden_wall(previous, house, along, front)
			previous = house
		travelled += size.x + Tuning.f("town", "gap")
		index += 1
	if not backdrop:
		_row_wall(start, end, front)


## An invisible wall just behind a row's fronts, so no gap between two houses lets the player out of town.
func _row_wall(start: Vector3, end: Vector3, front: Vector3) -> void:
	var back: Vector3 = -front * Tuning.f("town", "row_wall_setback")
	Blocks.wall_between(self, start + back, end + back, Tuning.f("town", "row_wall_height"), Tuning.f("town",
		"row_wall_width"), null)


## A solid block filling the space between two neighbouring houses, front to back, so nobody squeezes in.
func _fill_gap(a: Vector3, b: Vector3, front: Vector3, depth: float) -> void:
	var overlap: Vector3 = a.direction_to(b) * Tuning.f("town", "gap_fill_overlap")
	var back: Vector3 = -front * depth * 0.5
	Blocks.wall_between(self, a - overlap + back, b + overlap + back, Tuning.f("town", "row_wall_height"), depth, null)


## A brick garden wall closing the visible gap between two houses' ground floors, set just behind the nearer front,
## so a gap never looks open where it isn't. Houses that touch get none.
func _garden_wall(one: Node3D, two: Node3D, along: Vector3, front: Vector3) -> void:
	var box_one: Array[Vector3] = _footprint(one)
	var box_two: Array[Vector3] = _footprint(two)
	var end_one: float = maxf(box_one[0].dot(along), box_one[1].dot(along))
	var start_two: float = minf(box_two[0].dot(along), box_two[1].dot(along))
	if start_two - end_one < Tuning.f("town", "gap_wall_min"):
		return
	var face: float = minf(maxf(box_one[0].dot(front), box_one[1].dot(front)), maxf(box_two[0].dot(front),
		box_two[1].dot(front))) - Tuning.f("town", "gap_wall_inset")
	var a: Vector3 = along * end_one + front * face
	var b: Vector3 = along * start_two + front * face
	Blocks.wall_between(self, a, b, Tuning.f("town", "gap_wall_height"), Tuning.f("town", "gap_wall_width"),
		SurfaceMaterials.stone("bricks"))


## Two opposite corners (world space, on the ground) of a placed house's measured ground-floor box.
func _footprint(house: Node3D) -> Array[Vector3]:
	var box: AABB = library.collision_box(house.get_meta("asset"), house.get_meta("scale"))
	var low: Vector3 = house.global_transform * Vector3(box.position.x, 0.0, box.position.z)
	var high: Vector3 = house.global_transform * Vector3(box.end.x, 0.0, box.end.z)
	return [Vector3(low.x, 0.0, low.z), Vector3(high.x, 0.0, high.z)]


func _windows(house: Node3D, asset: String, scale: float) -> void:
	var spec: Dictionary = Tuning.doc("assets")[asset]
	for window: Array in spec.get("windows", []):
		var light := LampLight.new()
		light.setup("window")
		house.add_child(light)
		light.position = library.anchor(asset, [window[0], window[1], 1.0], scale) + Vector3.BACK * Tuning.look_f(
			"window", "out")
		lights.append(light)


func _lamp(asset: String, spec: Dictionary) -> void:
	var node: Node3D = place(asset, Tuning.point(spec["at"]), _yaw(spec), 1.0, true)
	var light := LampLight.new()
	light.setup(asset)
	node.add_child(light)
	light.position = library.anchor(asset, Tuning.doc("assets")[asset]["lamp"])
	lights.append(light)
	lamps.append(light)


## The yaw of a placement: its "rot" in degrees, or turned so its front looks at its "face" point.
func _yaw(spec: Dictionary) -> float:
	if spec.has("face"):
		var to: Vector3 = Tuning.point(spec["face"]) - Tuning.point(spec["at"])
		return atan2(to.x, to.z)
	return deg_to_rad(float(spec.get("rot", 0.0)))
