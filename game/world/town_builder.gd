class_name TownBuilder
extends Node3D
## Places the Meshy town from data/town.json: rows of houses along the streets (each house turned to face the
## street, with lit windows), the distant backdrop rows, the props, the street lamps and wall lanterns with their
## lights, the fountain's water and the cat. Collects every light so the light budget and the lamp network can
## manage them.

var library: AssetLibrary
var lights: Array[OmniLight3D] = []
var lamps: Array[LampLight] = []
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
	cat = TownCat.new()
	cat.setup(library, town["cat"])
	add_child(cat)


## One asset at a ground point, turned by yaw (radians) and scaled.
func place(asset: String, at: Vector3, yaw: float, scale: float, collide: bool) -> Node3D:
	var node: Node3D = library.spawn(asset, scale, collide)
	add_child(node)
	node.position = at
	node.rotation.y = yaw
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
		if not backdrop:
			_windows(house, asset, scale)
		travelled += size.x + Tuning.f("town", "gap")
		index += 1
	if not backdrop:
		_row_wall(start, end, front)


## An invisible wall just behind a row's fronts, so no gap between two houses lets the player out of town.
func _row_wall(start: Vector3, end: Vector3, front: Vector3) -> void:
	var back: Vector3 = -front * Tuning.f("town", "row_wall_setback")
	Blocks.wall_between(self, start + back, end + back, Tuning.f("town", "row_wall_height"), Tuning.f("town",
		"row_wall_width"), null)


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
