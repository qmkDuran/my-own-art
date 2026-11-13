class_name Outskirts
extends Node3D
## The world around the town: a dark meadow framing the town that you can walk out onto (its floor sounds of
## grass), a dense band of trees marking the edge of the walkable world, a forest of Meshy trees and simple trees
## further out (each ring one MultiMesh, so hundreds of trees cost a few draw
## calls), rolling hills, a lake to the south and a scatter of warm cottage lights on the hills. Laid out from
## data/town.json "outskirts" with a fixed seed.

const TRUNK: Color = Color(0.16, 0.11, 0.08)
const CROWN: Color = Color(0.07, 0.13, 0.09)
const HILL: Color = Color(0.05, 0.08, 0.09)
const MEADOW: Color = Color(0.06, 0.09, 0.06)
const TRUNK_SHARE: Vector2 = Vector2(0.12, 0.45)
const CROWN_SHARE: float = 0.75
const TRUNK_FLARE: float = 0.6
const CROWN_SINK: float = 0.8
const GROUND_DROP: float = 0.06
const HILL_SEGMENTS: int = 24
const FLOOR_THICKNESS: float = 1.0

var _rng := RandomNumberGenerator.new()


func build(library: AssetLibrary) -> void:
	name = "Outskirts"
	var spec: Dictionary = Tuning.doc("town")["outskirts"]
	_rng.seed = int(spec["seed"])
	_meadow(float(spec["meadow_size"]))
	_meshy_trees(library, spec["near_trees"])
	_simple_trees(spec["far_trees"])
	_simple_trees(spec["edge_trees"])
	for hill: Array in spec["hills"]:
		_hill(Tuning.vec3(hill.slice(0, 3)), Tuning.vec3(hill.slice(3, 6)))
	_lake(spec["lake"])
	_cottage_lights(spec["cottage_lights"])


## The meadow: four planes framing the town's own ground (never under it, where it would cover the canal).
func _meadow(size: float) -> void:
	var bounds: Array = Tuning.doc("town")["bounds"]
	var inner := Rect2(Vector2(float(bounds[0]), float(bounds[1])), Vector2(float(bounds[2]) - float(bounds[0]),
		float(bounds[3]) - float(bounds[1])))
	var half: float = size * 0.5
	var pieces: Array[Rect2] = [Rect2(-half, -half, size, inner.position.y + half),
		Rect2(-half, inner.end.y, size, half - inner.end.y),
		Rect2(-half, inner.position.y, inner.position.x + half, inner.size.y),
		Rect2(inner.end.x, inner.position.y, half - inner.end.x, inner.size.y)]
	var material: StandardMaterial3D = flat(MEADOW)
	for piece: Rect2 in pieces:
		var plane := PlaneMesh.new()
		plane.size = piece.size
		plane.material = material
		var ground := MeshInstance3D.new()
		ground.mesh = plane
		ground.position = Vector3(piece.get_center().x, -GROUND_DROP, piece.get_center().y)
		ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(ground)
		var floor_box := Vector3(piece.size.x, FLOOR_THICKNESS, piece.size.y)
		var body: Node3D = Blocks.box(self, ground.position - Vector3.UP * FLOOR_THICKNESS * 0.5, floor_box, null, true)
		Blocks.mark_surface(body, "grass")


## A ring of trees as one MultiMesh: positions between two radii, with random turn and size (none inside the
## mission woods' clearing, which plants its own).
func _ring(mesh: Mesh, ring: Dictionary) -> MultiMeshInstance3D:
	var clear: Array = Tuning.doc("mission")["tree_clear"]
	var keep_out := Rect2(float(clear[0]), float(clear[1]), float(clear[2]) - float(clear[0]), float(clear[3]) -
		float(clear[1]))
	var placed: Array[Transform3D] = []
	for index: int in int(ring["count"]):
		var angle: float = _rng.randf() * TAU
		var distance: float = _rng.randf_range(float(ring["radius_min"]), float(ring["radius_max"]))
		var at := Vector3(float(ring["centre"][0]) + cos(angle) * distance, 0.0, float(ring["centre"][1]) +
			sin(angle) * distance * float(ring["squash"]))
		var size: float = _rng.randf_range(float(ring["scale_min"]), float(ring["scale_max"]))
		var basis := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * size)
		if not keep_out.has_point(Vector2(at.x, at.z)):
			placed.append(Transform3D(basis, at))
	var instance: MultiMeshInstance3D = trees(mesh, placed)
	add_child(instance)
	return instance


## Many copies of one tree mesh as a single MultiMesh (a few draw calls for a whole forest).
static func trees(mesh: Mesh, placed: Array[Transform3D]) -> MultiMeshInstance3D:
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = mesh
	multi.instance_count = placed.size()
	for index: int in placed.size():
		multi.set_instance_transform(index, placed[index])
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = multi
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return instance


## The Meshy tree's mesh, material and the placement its model sits in (folded into each copy).
static func meshy_tree(library: AssetLibrary) -> Dictionary:
	var tree: Node3D = library.spawn("tree", 1.0, false)
	var model: MeshInstance3D = tree.find_children("*", "MeshInstance3D", true, false)[0]
	var offset: Transform3D = model.transform
	var parent: Node = model.get_parent()
	while parent != tree:
		offset = (parent as Node3D).transform * offset
		parent = parent.get_parent()
	var out: Dictionary = { "mesh": model.mesh, "material": model.get_surface_override_material(0), "offset": offset }
	tree.free()
	return out


func _meshy_trees(library: AssetLibrary, ring: Dictionary) -> void:
	var tree: Dictionary = meshy_tree(library)
	var placed: MultiMeshInstance3D = _ring(tree["mesh"], ring)
	placed.material_override = tree["material"]
	bake_offset(placed, tree["offset"])


## The Meshy model sits inside a scaled, offset node; each instance gets that placement folded in.
static func bake_offset(placed: MultiMeshInstance3D, offset: Transform3D) -> void:
	for index: int in placed.multimesh.instance_count:
		var at: Transform3D = placed.multimesh.get_instance_transform(index)
		placed.multimesh.set_instance_transform(index, at * offset)


func _simple_trees(ring: Dictionary) -> void:
	_ring(lollipop_tree(float(ring["height"])), ring)


## A far tree: a dark lollipop (trunk and round crown) merged into one mesh.
static func lollipop_tree(height: float) -> ArrayMesh:
	var trunk := CylinderMesh.new()
	trunk.top_radius = height * TRUNK_SHARE.x * 0.5
	trunk.bottom_radius = height * TRUNK_SHARE.x * TRUNK_FLARE
	trunk.height = height * TRUNK_SHARE.y
	var crown := SphereMesh.new()
	crown.radius = height * CROWN_SHARE * 0.5
	crown.height = height * CROWN_SHARE
	var tool := SurfaceTool.new()
	tool.append_from(trunk, 0, Transform3D(Basis(), Vector3.UP * trunk.height * 0.5))
	tool.append_from(crown, 0, Transform3D(Basis(), Vector3.UP * (trunk.height + crown.radius * CROWN_SINK)))
	var mesh: ArrayMesh = tool.commit()
	mesh.surface_set_material(0, flat(CROWN))
	return mesh


func _hill(centre: Vector3, size: Vector3) -> void:
	var dome := SphereMesh.new()
	dome.radius = 1.0
	dome.height = 2.0
	dome.radial_segments = HILL_SEGMENTS
	dome.rings = HILL_SEGMENTS / 2
	dome.material = flat(HILL)
	var hill := MeshInstance3D.new()
	hill.mesh = dome
	hill.scale = size
	hill.position = centre
	hill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(hill)


func _lake(rect: Array) -> void:
	var water := PlaneMesh.new()
	water.size = Vector2(float(rect[2]) - float(rect[0]), float(rect[3]) - float(rect[1]))
	water.material = SurfaceMaterials.water()
	var lake := MeshInstance3D.new()
	lake.name = "Lake"
	lake.mesh = water
	lake.position = Vector3((float(rect[0]) + float(rect[2])) * 0.5, float(rect[4]), (float(rect[1]) + float(rect[3]))
		* 0.5)
	add_child(lake)


func _cottage_lights(spec: Dictionary) -> void:
	var colour: Color = Tuning.color(spec["color"])
	for index: int in int(spec["count"]):
		var angle: float = _rng.randf() * TAU
		var distance: float = _rng.randf_range(float(spec["radius_min"]), float(spec["radius_max"]))
		var glow: Node3D = SoftGlow.make(colour, float(spec["size"]), float(spec["energy"]))
		add_child(glow)
		glow.position = Vector3(cos(angle) * distance, _rng.randf_range(float(spec["height_min"]),
			float(spec["height_max"])), sin(angle) * distance)


static func flat(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 1.0
	return material
