class_name Foliage
## Builds the hiding spots: round bushes (a cluster of flat-shaded leaf balls) and tall-grass patches (a multimesh
## of blades). Both are HidingSpot areas; neither blocks movement, sight lines or spit.

const BUSH_BALLS: int = 6
const BUSH_BALL_SHARE: float = 0.55
const BUSH_SPREAD_SHARE: float = 0.5
const BUSH_HEIGHT: float = 0.75
const BUSH_LUMP: float = 0.16
const BUSH_SEGMENTS: int = 8
const BUSH_RINGS: int = 5
const BLADE_WIDTH: float = 0.12
const BLADE_DEPTH: float = 0.03
const BLADE_MIN_HEIGHT: float = 0.9
const BLADE_MAX_HEIGHT: float = 1.35
const BLADE_TILT: float = 0.25
const BUSH_SIZE_JITTER: Vector2 = Vector2(0.8, 1.1)
const BUSH_HEIGHT_JITTER: Vector2 = Vector2(0.8, 1.2)
const BUSH_SQUASH: float = 1.6
const GRASS_TINT_SHARE: float = 0.6
const SMOKE_COLOR: Color = Color(0.78, 0.8, 0.78)
const BUSH_COLORS: Array[String] = ["bush", "bush_light"]


static func bush(ground: Vector3, radius: float, rng: RandomNumberGenerator) -> HidingSpot:
	var spot := HidingSpot.new()
	spot.setup("bush", radius)
	spot.position = ground
	for color_name: String in BUSH_COLORS:
		spot.fade_materials.append(WoodsMaterials.solid(color_name).duplicate())
	for ball: int in BUSH_BALLS:
		var sphere := SphereMesh.new()
		sphere.radius = radius * BUSH_BALL_SHARE * rng.randf_range(BUSH_SIZE_JITTER.x, BUSH_SIZE_JITTER.y)
		sphere.height = sphere.radius * BUSH_SQUASH
		sphere.radial_segments = BUSH_SEGMENTS
		sphere.rings = BUSH_RINGS
		var view := MeshInstance3D.new()
		view.mesh = FlatMesh.lumpy(sphere, rng, BUSH_LUMP)
		view.material_override = spot.fade_materials[ball % spot.fade_materials.size()]
		var angle: float = TAU * ball / BUSH_BALLS
		var spread: float = radius * BUSH_SPREAD_SHARE * (0.0 if ball == 0 else 1.0)
		var height: float = BUSH_HEIGHT * rng.randf_range(BUSH_HEIGHT_JITTER.x, BUSH_HEIGHT_JITTER.y)
		view.position = Vector3(cos(angle) * spread, height, sin(angle) * spread)
		spot.sway_root.add_child(view)
	return spot


## A drifting cloud of smoke to hide in (from Smoke Puff); fades with its spot.
static func smoke_cloud(ground: Vector3, radius: float, rng: RandomNumberGenerator) -> HidingSpot:
	var spot := HidingSpot.new()
	spot.setup("smoke", radius)
	spot.position = ground
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(SMOKE_COLOR, Tuning.f("terrain_effects", "smoke_alpha"))
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	spot.fade_materials.append(material)
	for puff: int in BUSH_BALLS:
		var sphere := SphereMesh.new()
		sphere.radius = radius * BUSH_BALL_SHARE * rng.randf_range(BUSH_SIZE_JITTER.x, BUSH_SIZE_JITTER.y)
		sphere.height = sphere.radius * 2.0
		var view := MeshInstance3D.new()
		view.mesh = sphere
		view.material_override = material
		view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var angle: float = TAU * puff / BUSH_BALLS
		view.position = Vector3(cos(angle), 1.0, sin(angle)) * radius * BUSH_SPREAD_SHARE
		spot.sway_root.add_child(view)
	return spot


static func tall_grass(ground: Vector3, radius: float, density: float, rng: RandomNumberGenerator,
		shape: TerrainShape) -> HidingSpot:
	var spot := HidingSpot.new()
	spot.setup("grass", radius)
	spot.position = ground
	var blade := PrismMesh.new()
	blade.size = Vector3(BLADE_WIDTH, 1.0, BLADE_DEPTH)
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = blade
	multimesh.instance_count = int(PI * radius * radius * density)
	for k: int in multimesh.instance_count:
		multimesh.set_instance_transform(k, _blade_transform(ground, radius, rng, shape))
		var tint: float = rng.randf() * GRASS_TINT_SHARE
		multimesh.set_instance_color(k, Tuning.palette("tall_grass").lerp(Tuning.palette("tall_grass_tip"), tint))
	var view := MultiMeshInstance3D.new()
	view.multimesh = multimesh
	spot.fade_materials.append(WoodsMaterials.blades().duplicate())
	view.material_override = spot.fade_materials[0]
	view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	spot.sway_root.add_child(view)
	return spot


static func _blade_transform(ground: Vector3, radius: float, rng: RandomNumberGenerator,
		shape: TerrainShape) -> Transform3D:
	var offset: Vector2 = Vector2.from_angle(rng.randf() * TAU) * sqrt(rng.randf()) * radius
	var height: float = rng.randf_range(BLADE_MIN_HEIGHT, BLADE_MAX_HEIGHT)
	var basis := Basis(Vector3.UP, rng.randf() * TAU)
	basis = basis * Basis(Vector3.RIGHT, rng.randf_range(-BLADE_TILT, BLADE_TILT))
	basis = basis * Basis.from_scale(Vector3(1.0, height, 1.0))
	var y: float = shape.height(ground.x + offset.x, ground.z + offset.y) - ground.y + height * 0.5
	return Transform3D(basis, Vector3(offset.x, y, offset.y))
