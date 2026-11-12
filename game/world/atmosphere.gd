class_name Atmosphere
## Forest mood: a warm low sun with soft shadows (the canopy throws patches of shade, clearings stay bright), a soft
## sky, green-grey fog for depth, and a few faint light shafts falling into the clearings.

const SHAFT_SEGMENTS: int = 16
const SHAFT_RINGS: int = 8
const SHAFT_PEAK_SKEW: float = 0.6


static func build(parent: Node3D, shape: TerrainShape) -> DirectionalLight3D:
	var spec: Dictionary = Tuning.woods["atmosphere"]
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation = Vector3(deg_to_rad(spec["sun_pitch_deg"]), deg_to_rad(spec["sun_yaw_deg"]), 0)
	sun.light_color = Tuning.palette("sun")
	sun.light_energy = float(spec["sun_energy"])
	sun.shadow_enabled = true
	sun.shadow_blur = float(spec["shadow_blur"])
	sun.directional_shadow_max_distance = float(spec["shadow_distance"])
	parent.add_child(sun)
	var world_env := WorldEnvironment.new()
	world_env.environment = _environment(spec)
	parent.add_child(world_env)
	for spot: Array in Tuning.woods["light_shafts"]:
		parent.add_child(_shaft(spot, shape, sun, spec))
	return sun


static func _environment(spec: Dictionary) -> Environment:
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Tuning.palette("sky_top")
	sky_material.sky_horizon_color = Tuning.palette("sky_horizon")
	sky_material.ground_horizon_color = Tuning.palette("sky_horizon")
	sky_material.ground_bottom_color = Tuning.palette("ground_horizon")
	var sky := Sky.new()
	sky.sky_material = sky_material
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Tuning.palette("ambient")
	env.ambient_light_energy = float(spec["ambient_energy"])
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Tuning.palette("fog")
	env.fog_density = float(spec["fog_density"])
	env.fog_sky_affect = float(spec["fog_sky_affect"])
	return env


## A tall, faint, additive cone leaning along the sunlight, standing in a clearing. It fades out at both ends so
## it reads as light in the air rather than a solid tube.
static func _shaft(spot: Array, shape: TerrainShape, sun: DirectionalLight3D, spec: Dictionary) -> MeshInstance3D:
	var material: StandardMaterial3D = WoodsMaterials.glow(Tuning.palette("shaft"), 1.0)
	material.vertex_color_use_as_albedo = true
	material.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_ALPHA
	material.distance_fade_min_distance = float(spec["shaft_fade_near"])
	material.distance_fade_max_distance = float(spec["shaft_fade_far"])
	var view := MeshInstance3D.new()
	view.name = "LightShaft"
	view.mesh = _shaft_mesh(spec, Tuning.palette("shaft").a)
	view.material_override = material
	view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var toward_sun: Vector3 = sun.basis.z
	var side: Vector3 = toward_sun.cross(Vector3.BACK).normalized()
	view.basis = Basis(side, toward_sun, side.cross(toward_sun))
	view.position = Vector3(float(spot[0]), shape.height(float(spot[0]), float(spot[1])), float(spot[1]))
	return view


## An open tube from the ground up along +Y, widening toward the sky, brightest a third of the way up.
static func _shaft_mesh(spec: Dictionary, peak_alpha: float) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var length: float = float(spec["shaft_length"])
	for ring: int in SHAFT_RINGS:
		var low: float = float(ring) / SHAFT_RINGS
		var high: float = float(ring + 1) / SHAFT_RINGS
		for k: int in SHAFT_SEGMENTS:
			var a: float = TAU * k / SHAFT_SEGMENTS
			var b: float = TAU * (k + 1) / SHAFT_SEGMENTS
			var quad: Array[Vector2] = [Vector2(a, low), Vector2(b, low), Vector2(b, high), Vector2(a, high)]
			for corner: int in [0, 1, 2, 0, 2, 3]:
				_shaft_vertex(tool, quad[corner], spec, length, peak_alpha)
	return tool.commit()


static func _shaft_vertex(tool: SurfaceTool, at: Vector2, spec: Dictionary, length: float, peak_alpha: float) -> void:
	var radius: float = lerpf(float(spec["shaft_bottom_radius"]), float(spec["shaft_top_radius"]), at.y)
	var fade: float = sin(PI * pow(at.y, SHAFT_PEAK_SKEW))
	tool.set_color(Color(1, 1, 1, peak_alpha * fade))
	tool.add_vertex(Vector3(cos(at.x) * radius, at.y * length, sin(at.x) * radius))
