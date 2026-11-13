class_name TerrainBuilder
## Builds the ground: a vertex-coloured heightmap mesh (grass, sunny clearings, dirt on slopes, stone on the ridge,
## moss in the ravine, dark soft soil you can burrow in, grey gravel you cannot) and a matching trimesh collider that
## the navmesh is baked from.

const COLOR_NOISE_FREQUENCY: float = 0.08
const SLOPE_DIRT_START: float = 0.9
const SLOPE_DIRT_FULL: float = 0.75
const RIDGE_STONE_START: float = 1.8
const RIDGE_STONE_SHARE: float = 0.45
const RAVINE_MOSS_DISTANCE: float = 2.5
const CLEARING_EDGE: float = 2.5
const PATCH_GRAIN: float = 3.0
const PATCH_MIX: float = 0.5


static func build(shape: TerrainShape, spec: Dictionary, clearings: Array, features: WoodsFeatures) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "Terrain"
	body.collision_layer = Layers.TERRAIN
	body.collision_mask = 0
	var mesh: ArrayMesh = _mesh(shape, float(spec["size"]), float(spec["step"]), clearings, features)
	var view := MeshInstance3D.new()
	view.mesh = mesh
	view.material_override = WoodsMaterials.vertex_colored()
	body.add_child(view)
	var collider := CollisionShape3D.new()
	collider.shape = mesh.create_trimesh_shape()
	body.add_child(collider)
	return body


static func _mesh(shape: TerrainShape, size: float, step: float, clearings: Array,
		features: WoodsFeatures) -> ArrayMesh:
	var count: int = int(size / step) + 1
	var half: float = size * 0.5
	var noise := FastNoiseLite.new()
	noise.frequency = COLOR_NOISE_FREQUENCY
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row: int in count:
		for col: int in count:
			var x: float = -half + col * step
			var z: float = -half + row * step
			var color: Color = _ground_color(shape, Vector2(x, z), noise, clearings)
			tool.set_color(_patch_color(color, Vector3(x, 0.0, z), features, noise))
			tool.add_vertex(Vector3(x, shape.height(x, z), z))
	_add_grid_indices(tool, count)
	tool.generate_normals()
	return tool.commit()


static func _add_grid_indices(tool: SurfaceTool, count: int) -> void:
	for row: int in count - 1:
		for col: int in count - 1:
			var a: int = row * count + col
			var b: int = a + 1
			var c: int = a + count
			var d: int = c + 1
			for index: int in [a, b, c, b, d, c]:
				tool.add_index(index)


static func _ground_color(shape: TerrainShape, p: Vector2, noise: FastNoiseLite, clearings: Array) -> Color:
	var shade: float = noise.get_noise_2d(p.x, p.y) * 0.5 + 0.5
	var color: Color = Tuning.palette("moss").lerp(Tuning.palette("grass"), shade)
	color = color.lerp(Tuning.palette("grass_light"), _clearing_weight(p, clearings) * shade)
	var flatness: float = shape.normal(p.x, p.y).y
	color = color.lerp(Tuning.palette("dirt"), smoothstep(SLOPE_DIRT_START, SLOPE_DIRT_FULL, flatness))
	var stone: float = smoothstep(RIDGE_STONE_START, RIDGE_STONE_START + 1.0, shape.ridge_lift(p))
	color = color.lerp(Tuning.palette("rock"), stone * RIDGE_STONE_SHARE * (1.0 - shade * 0.5))
	var moss: float = 1.0 - smoothstep(0.0, RAVINE_MOSS_DISTANCE, shape.ravine_distance(p))
	return color.lerp(Tuning.palette("moss"), moss)


## Soft soil reads dark and rich; rocky ground reads grey and gritty (same noise, so the edges look natural).
static func _patch_color(color: Color, p: Vector3, features: WoodsFeatures, noise: FastNoiseLite) -> Color:
	var grain: float = noise.get_noise_2d(p.z * PATCH_GRAIN, p.x * PATCH_GRAIN) * 0.5 + 0.5
	if features.rocky_at(p):
		return Tuning.palette("gravel").lerp(Tuning.palette("rock_dark"), grain * PATCH_MIX)
	if features.soft_at(p):
		return Tuning.palette("soil").lerp(Tuning.palette("dirt"), grain * PATCH_MIX)
	return color


static func _clearing_weight(p: Vector2, clearings: Array) -> float:
	var best: float = 0.0
	for clearing: Dictionary in clearings:
		var d: float = p.distance_to(Tuning.vec2(clearing["pos"]))
		var radius: float = float(clearing["radius"])
		best = maxf(best, 1.0 - smoothstep(radius - CLEARING_EDGE, radius, d))
	return best
