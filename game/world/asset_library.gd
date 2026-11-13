class_name AssetLibrary
extends RefCounted
## Loads the Meshy GLBs listed in data/assets.json and spawns them ready for the town: scaled to their listed
## height, centred on their footprint with the base on the ground, painted with the town asset material (window
## glow plus wetness) and, when listed, given a collision box. The box is measured from the mesh itself: the
## extent of the vertices at walking height (the ground-floor walls, a tree's trunk, a lamp's post), so what you
## bump into is what you see. Everything is worked out once per asset and shared by every copy.

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
	holder.set_meta("asset", asset)
	holder.set_meta("scale", scale)
	var model: Node3D = (info["scene"] as PackedScene).instantiate()
	model.scale = Vector3.ONE * info["scale"] * scale
	model.position = info["offset"] * scale
	_paint(model, info["materials"])
	holder.add_child(model)
	if holder is StaticBody3D:
		_add_box(holder, asset, scale)
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
	var band: AABB = walking_band(probe, Transform3D(Basis().scaled(Vector3.ONE * scale), -base_centre * scale))
	probe.free()
	return { "scene": scene, "scale": scale, "offset": -base_centre * scale, "size": bounds.size * scale,
		"materials": materials, "collide": spec["collide"] == "box", "band": band }


## The box around a model's vertices at walking height (data/tuning.json town.collision_band), in the spawned
## node's space at scale 1, ignoring a small share of stray vertices on each side (a hanging sign, trailing ivy).
## Empty when no vertex is at that height.
func walking_band(root: Node3D, placed: Transform3D) -> AABB:
	var low: float = Tuning.f("town", "collision_band_low")
	var high: float = Tuning.f("town", "collision_band_high")
	var xs := PackedFloat32Array()
	var zs := PackedFloat32Array()
	for node: Node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node
		var xform: Transform3D = placed * _relative_transform(mesh, root)
		for surface: int in mesh.mesh.get_surface_count():
			for vertex: Vector3 in mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:
				var point: Vector3 = xform * vertex
				if point.y >= low and point.y <= high:
					xs.append(point.x)
					zs.append(point.z)
	if xs.is_empty():
		return AABB()
	xs.sort()
	zs.sort()
	var trim: int = int(xs.size() * Tuning.f("town", "collision_trim_share"))
	var corner := Vector3(xs[trim], low, zs[trim])
	return AABB(corner, Vector3(xs[xs.size() - 1 - trim], high, zs[zs.size() - 1 - trim]) - corner)


## The collision box of an asset at a scale, in the spawned node's space.
func collision_box(asset: String, scale: float = 1.0) -> AABB:
	var info: Dictionary = _prepared(asset)
	var band: AABB = info["band"]
	var size: Vector3 = info["size"]
	if band.size == Vector3.ZERO:
		band = AABB(Vector3(-size.x * 0.5, 0.0, -size.z * 0.5), size)
	var corner := Vector3(band.position.x, 0.0, band.position.z)
	return AABB(corner * scale, Vector3(band.size.x, size.y, band.size.z) * scale)


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


func _add_box(body: StaticBody3D, asset: String, scale: float) -> void:
	var bounds: AABB = collision_box(asset, scale)
	var box := BoxShape3D.new()
	box.size = bounds.size
	var shape := CollisionShape3D.new()
	shape.shape = box
	shape.position = bounds.get_center()
	body.add_child(shape)
