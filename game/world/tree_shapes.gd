class_name TreeShapes
## Unit-size tree meshes, merged into one mesh each so they can be instanced: a tapered trunk per kind, and lumpy
## low-poly crowns (stacked cones for pines, a cluster of blobs for leafy trees) in white for instance colouring.

const TRUNK_TAPER: float = 0.7
const PINE_TRUNK: float = 7.8
const LEAFY_TRUNK: float = 6.2
const PINE_TIERS: int = 3
const PINE_BASE: float = 3.3
const PINE_TIER_RADIUS: float = 2.1
const PINE_TIER_HEIGHT: float = 2.6
const PINE_TIER_RISE: float = 1.45
const PINE_TIER_SHRINK: float = 0.28
const LEAFY_BLOBS: int = 4
const LEAFY_BASE: float = 5.4
const LEAFY_RADIUS: float = 1.9
const LEAFY_SPREAD: float = 1.1
const LEAFY_SQUASH: float = 1.7
const LEAFY_MIN_SIZE: float = 0.7
const LEAFY_MAX_LIFT: float = 0.9
const CONE_SEGMENTS: int = 8
const ROUND_SEGMENTS: int = 9
const ROUND_RINGS: int = 5
const CROWN_COLLIDER_SHARE: float = 0.8


static func trunk(kind: String) -> ArrayMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = Props.TRUNK_RADIUS * TRUNK_TAPER
	mesh.bottom_radius = Props.TRUNK_RADIUS
	mesh.height = trunk_height(kind)
	mesh.radial_segments = CONE_SEGMENTS
	return _lifted(mesh, mesh.height * 0.5)


static func trunk_height(kind: String) -> float:
	return PINE_TRUNK if kind == "pine" else LEAFY_TRUNK


## Where a unit-size crown's collider ball sits and how big it is (for the camera only).
static func crown_ball(kind: String) -> Vector2:
	if kind == "pine":
		return Vector2(PINE_BASE + PINE_TIER_RISE, PINE_TIER_RADIUS * CROWN_COLLIDER_SHARE)
	return Vector2(LEAFY_BASE, LEAFY_RADIUS * CROWN_COLLIDER_SHARE)


static func crown(kind: String, rng: RandomNumberGenerator, lump: float) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	if kind == "pine":
		for tier: int in PINE_TIERS:
			var cone := CylinderMesh.new()
			cone.top_radius = 0.0
			cone.bottom_radius = PINE_TIER_RADIUS * (1.0 - tier * PINE_TIER_SHRINK)
			cone.height = PINE_TIER_HEIGHT
			cone.radial_segments = CONE_SEGMENTS
			var y: float = PINE_BASE + tier * PINE_TIER_RISE + cone.height * 0.5
			tool.append_from(FlatMesh.lumpy(cone, rng, lump), 0, Transform3D(Basis.IDENTITY, Vector3(0, y, 0)))
	else:
		for blob: int in LEAFY_BLOBS:
			var ball := SphereMesh.new()
			ball.radius = LEAFY_RADIUS * rng.randf_range(LEAFY_MIN_SIZE, 1.0)
			ball.height = ball.radius * LEAFY_SQUASH
			ball.radial_segments = ROUND_SEGMENTS
			ball.rings = ROUND_RINGS
			var angle: float = TAU * blob / LEAFY_BLOBS + rng.randf()
			var offset := Vector3(cos(angle), rng.randf_range(0.0, LEAFY_MAX_LIFT), sin(angle)) * LEAFY_SPREAD
			var at: Vector3 = offset + Vector3.UP * LEAFY_BASE
			tool.append_from(FlatMesh.lumpy(ball, rng, lump), 0, Transform3D(Basis.IDENTITY, at))
	return white(tool.commit())


static func _lifted(mesh: PrimitiveMesh, lift: float) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.append_from(mesh, 0, Transform3D(Basis.IDENTITY, Vector3.UP * lift))
	return tool.commit()


## Gives every vertex a white colour so the instance colour shows unchanged.
static func white(mesh: ArrayMesh) -> ArrayMesh:
	var arrays: Array = mesh.surface_get_arrays(0)
	var colors := PackedColorArray()
	colors.resize((arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size())
	colors.fill(Color.WHITE)
	arrays[Mesh.ARRAY_COLOR] = colors
	var out := ArrayMesh.new()
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return out
