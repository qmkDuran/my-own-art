class_name Undergrowth
## The living floor of the woods, all instanced: ferns in the shade near trunks, wildflowers in and around the sunny
## clearings, mushrooms at the feet of trees and logs, and pebbles on the rocky patches. Ferns and flowers sway in
## the wind. Nothing here blocks movement, sight or shots.

const FERN_LEAVES: int = 6
const FERN_LEAF: Vector2 = Vector2(0.22, 0.9)
const FERN_TILT: float = 0.9
const FERN_SCALE: Vector2 = Vector2(0.6, 1.3)
const FLOWER_STEM: Vector2 = Vector2(0.02, 0.35)
const FLOWER_HEAD: float = 0.07
const FLOWER_SCALE: Vector2 = Vector2(0.8, 1.4)
const CAP_RADIUS: float = 0.12
const STEM_HEIGHT: float = 0.12
const MUSHROOM_SCALE: Vector2 = Vector2(0.6, 1.8)
const PEBBLE: float = 0.12
const SHADE_REACH: float = 4.0
const SHADE_CHANCE: float = 0.85
const OPEN_CHANCE: float = 0.25
const FERN_SWAY: float = 0.08
const FLOWER_SWAY: float = 0.05
const SWAY_HEIGHT: float = 1.0
const TRIES_PER_PLANT: int = 6
const FERN_GREENS: Array[String] = ["fern", "fern_light"]
const FLOWER_TONES: Array[String] = ["flower_white", "flower_yellow", "flower_violet", "flower_pink"]
const MUSHROOM_TONES: Array[String] = ["mushroom_cap", "mushroom_pale"]
const LEAF_THIN: float = 0.1
const STEM_TOP: float = 0.35
const STEM_FOOT: float = 0.4
const PEBBLE_SCALE: Vector2 = Vector2(0.6, 1.6)


static func build(parent: Node3D, woods: Woods, rng: RandomNumberGenerator) -> void:
	var spec: Dictionary = Tuning.woods["undergrowth"]
	var clearings: Array = Tuning.woods["clearings"]
	var trees: Dictionary = _tree_cells(woods)
	var shady: Callable = func(p: Vector3) -> bool: return _near_tree(trees, p) and not _in_clearing(clearings, p)
	var sunny: Callable = func(p: Vector3) -> bool: return _in_clearing(clearings, p) or rng.randf() < OPEN_CHANCE
	var rooted: Callable = func(p: Vector3) -> bool: return _near_tree(trees, p)
	_layer(parent, _fern_mesh(), woods, rng, int(spec["ferns"]), shady, FERN_GREENS, FERN_SCALE, FERN_SWAY)
	_layer(parent, _flower_mesh(), woods, rng, int(spec["flowers"]), sunny, FLOWER_TONES, FLOWER_SCALE, FLOWER_SWAY)
	_layer(parent, _mushroom_mesh(), woods, rng, int(spec["mushrooms"]), rooted, MUSHROOM_TONES, MUSHROOM_SCALE, 0.0)
	_pebbles(parent, woods, rng, int(spec["pebbles_per_patch"]))


static func _layer(parent: Node3D, mesh: Mesh, woods: Woods, rng: RandomNumberGenerator, count: int, fits: Callable,
		tones: Array[String], scales: Vector2, sway: float) -> void:
	var spots: Array[Transform3D] = []
	var colors: Array[Color] = []
	var limit: float = float(Tuning.woods["trees"]["ring_from"])
	for k: int in count * TRIES_PER_PLANT:
		if spots.size() >= count:
			break
		var at: Vector3 = woods.ground_at(Vector2(rng.randf_range(-limit, limit), rng.randf_range(-limit, limit)))
		if woods.water_at(at) or not fits.call(at) or rng.randf() > SHADE_CHANCE:
			continue
		var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * rng.randf_range(scales.x, scales.y))
		spots.append(Transform3D(basis, at))
		colors.append(Tuning.palette(tones[rng.randi() % tones.size()]))
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = mesh
	multimesh.instance_count = spots.size()
	for k: int in spots.size():
		multimesh.set_instance_transform(k, spots[k])
		multimesh.set_instance_color(k, colors[k])
	var layer := MultiMeshInstance3D.new()
	layer.multimesh = multimesh
	layer.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var swaying: bool = sway > 0.0
	layer.material_override = WoodsMaterials.foliage(sway, SWAY_HEIGHT) if swaying else WoodsMaterials.vertex_colored()
	parent.add_child(layer)


static func _fern_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.set_color(Color.WHITE)
	for k: int in FERN_LEAVES:
		var leaf := PrismMesh.new()
		leaf.size = Vector3(FERN_LEAF.x, FERN_LEAF.y, FERN_LEAF.x * LEAF_THIN)
		var basis := Basis(Vector3.UP, TAU * k / FERN_LEAVES) * Basis(Vector3.RIGHT, FERN_TILT)
		tool.append_from(leaf, 0, Transform3D(basis, basis * Vector3(0, FERN_LEAF.y * 0.5, 0)))
	return TreeShapes.white(tool.commit())


static func _flower_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var stem := CylinderMesh.new()
	stem.top_radius = FLOWER_STEM.x
	stem.bottom_radius = FLOWER_STEM.x
	stem.height = FLOWER_STEM.y
	tool.append_from(stem, 0, Transform3D(Basis.IDENTITY, Vector3(0, FLOWER_STEM.y * 0.5, 0)))
	var head := SphereMesh.new()
	head.radius = FLOWER_HEAD
	head.height = FLOWER_HEAD
	tool.append_from(head, 0, Transform3D(Basis.IDENTITY, Vector3(0, FLOWER_STEM.y, 0)))
	return TreeShapes.white(tool.commit())


static func _mushroom_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var stem := CylinderMesh.new()
	stem.top_radius = CAP_RADIUS * STEM_TOP
	stem.bottom_radius = CAP_RADIUS * STEM_FOOT
	stem.height = STEM_HEIGHT
	tool.append_from(stem, 0, Transform3D(Basis.IDENTITY, Vector3(0, STEM_HEIGHT * 0.5, 0)))
	var cap := SphereMesh.new()
	cap.radius = CAP_RADIUS
	cap.height = CAP_RADIUS
	cap.is_hemisphere = true
	tool.append_from(cap, 0, Transform3D(Basis.IDENTITY, Vector3(0, STEM_HEIGHT, 0)))
	return TreeShapes.white(tool.commit())


static func _pebbles(parent: Node3D, woods: Woods, rng: RandomNumberGenerator, per_patch: int) -> void:
	var stone := SphereMesh.new()
	stone.radius = PEBBLE
	stone.height = PEBBLE
	var transforms: Array[Transform3D] = []
	for patch: Dictionary in woods.features.rocky_patches():
		for k: int in per_patch:
			var offset: Vector2 = Vector2.from_angle(rng.randf() * TAU) * sqrt(rng.randf()) * float(patch["radius"])
			var size: float = rng.randf_range(PEBBLE_SCALE.x, PEBBLE_SCALE.y)
			var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * size)
			transforms.append(Transform3D(basis, woods.ground_at((patch["pos"] as Vector2) + offset)))
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = stone
	multimesh.instance_count = transforms.size()
	for k: int in transforms.size():
		multimesh.set_instance_transform(k, transforms[k])
	var layer := MultiMeshInstance3D.new()
	layer.multimesh = multimesh
	layer.material_override = WoodsMaterials.solid("pebble")
	parent.add_child(layer)


## Trees by grid cell (SHADE_REACH wide), so "is a trunk near?" is a few lookups, not a scan of every tree.
static func _tree_cells(woods: Woods) -> Dictionary:
	var cells: Dictionary = {}
	for tree: Vector3 in woods.tree_spots:
		cells[Vector2i(floori(tree.x / SHADE_REACH), floori(tree.z / SHADE_REACH))] = true
	return cells


static func _near_tree(cells: Dictionary, p: Vector3) -> bool:
	var cell := Vector2i(floori(p.x / SHADE_REACH), floori(p.z / SHADE_REACH))
	for dx: int in [-1, 0, 1]:
		for dz: int in [-1, 0, 1]:
			if cells.has(cell + Vector2i(dx, dz)):
				return true
	return false


static func _in_clearing(clearings: Array, p: Vector3) -> bool:
	for clearing: Dictionary in clearings:
		if Vector2(p.x, p.z).distance_to(Tuning.vec2(clearing["pos"])) <= float(clearing["radius"]):
			return true
	return false

