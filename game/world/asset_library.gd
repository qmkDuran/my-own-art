class_name AssetLibrary
extends RefCounted
## Loads the Meshy GLBs listed in data/assets.json and spawns them ready for the town: scaled to their listed
## height, centred on their footprint with the base on the ground, painted with the town asset material (window
## glow plus wetness) and, when listed, given a collision box. Scale, offset and materials are worked out once
## per asset and shared by every copy.

const ASSET_SHADER: Shader = preload("res://shaders/asset.gdshader")
const GLOW_KEYS: Array[String] = ["hue_min", "hue_max", "saturation_min", "value_min", "softness"]

var _info: Dictionary = {}


## The asset's size in metres at scale 1 (x is its width across the front, z its depth).
func size_of(asset: String) -> Vector3:
	return _prepared(asset)["size"]


## A point inside the asset's bounds given as shares (0..1 on x, y, z), relative to its base centre.
func anchor(asset: String, shares: Array, scale: float = 1.0) -> Vector3:
	var size: Vector3 = size_of(asset) * scale
	var share: Vector3 = Tuning.vec3(shares)
	return Vector3((share.x - 0.5) * size.x, share.y * size.y, (share.z - 0.5) * size.z)


## A new copy of the asset, its base centre at the node's origin. With collide, a StaticBody3D with a box.
func spawn(asset: String, scale: float = 1.0, collide: bool = true) -> Node3D:
	var info: Dictionary = _prepared(asset)
	var holder: Node3D = StaticBody3D.new() if collide and info["collide"] else Node3D.new()
	holder.name = asset.to_pascal_case()
	var model: Node3D = (info["scene"] as PackedScene).instantiate()
	model.scale = Vector3.ONE * info["scale"] * scale
	model.position = info["offset"] * scale
	_paint(model, info["materials"])
	holder.add_child(model)
	if holder is StaticBody3D:
		_add_box(holder, info, scale)
	return holder


func _prepared(asset: String) -> Dictionary:
	if not _info.has(asset):
		_info[asset] = _prepare(asset)
	return _info[asset]


func _prepare(asset: String) -> Dictionary:
	var spec: Dictionary = Tuning.doc("assets")[asset]
	var scene: PackedScene = load(spec["path"])
	var probe: Node3D = scene.instantiate()
	var bounds: AABB = _bounds(probe)
	var scale: float = float(spec["height"]) / bounds.size.y
	var base_centre := Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z)
	var materials: Array[Material] = _materials_for(probe, float(spec["glow"]))
	probe.free()
	return { "scene": scene, "scale": scale, "offset": -base_centre * scale, "size": bounds.size * scale,
		"materials": materials, "collide": spec["collide"] == "box",
		"footprint": float(spec.get("footprint_share", 1.0)) }


func _bounds(root: Node3D) -> AABB:
	var box := AABB()
	var first: bool = true
	for node: Node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node
		var part: AABB = _relative_transform(mesh, root) * mesh.get_aabb()
		box = part if first else box.merge(part)
		first = false
	return box


func _relative_transform(node: Node3D, root: Node3D) -> Transform3D:
	var xform: Transform3D = node.transform
	var parent: Node = node.get_parent()
	while parent != root and parent is Node3D:
		xform = (parent as Node3D).transform * xform
		parent = parent.get_parent()
	return xform


## One town material per mesh surface, in the order the meshes are found.
func _materials_for(root: Node3D, glow: float) -> Array[Material]:
	var out: Array[Material] = []
	for node: Node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node
		for surface: int in mesh.mesh.get_surface_count():
			out.append(_town_material(mesh.mesh.surface_get_material(surface), glow))
	return out


func _town_material(source: Material, glow: float) -> Material:
	var material := ShaderMaterial.new()
	material.shader = ASSET_SHADER
	if source is BaseMaterial3D:
		material.set_shader_parameter("albedo_tex", (source as BaseMaterial3D).albedo_texture)
	material.set_shader_parameter("glow", glow)
	for key: String in GLOW_KEYS:
		material.set_shader_parameter(key, Tuning.look_f("asset_glow", key))
	return material


func _paint(model: Node3D, materials: Array[Material]) -> void:
	var index: int = 0
	for node: Node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node
		for surface: int in mesh.mesh.get_surface_count():
			mesh.set_surface_override_material(surface, materials[index])
			index += 1


func _add_box(body: StaticBody3D, info: Dictionary, scale: float) -> void:
	var size: Vector3 = info["size"] * scale
	var share: float = info["footprint"]
	var box := BoxShape3D.new()
	box.size = Vector3(size.x * share, size.y, size.z * share)
	var shape := CollisionShape3D.new()
	shape.shape = box
	shape.position.y = size.y * 0.5
	body.add_child(shape)
