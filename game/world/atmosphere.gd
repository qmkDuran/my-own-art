class_name Atmosphere
## Forest mood: a warm low sun with soft shadows (the canopy throws patches of shade, clearings stay bright), a soft
## sky, green-grey fog for depth, and a few faint light shafts falling into the clearings.

const SHAFT_SEGMENTS: int = 12


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


## A tall, faint, additive cone leaning along the sunlight, standing in a clearing.
static func _shaft(spot: Array, shape: TerrainShape, sun: DirectionalLight3D, spec: Dictionary) -> MeshInstance3D:
	var cone := CylinderMesh.new()
	cone.top_radius = float(spec["shaft_top_radius"])
	cone.bottom_radius = float(spec["shaft_bottom_radius"])
	cone.height = float(spec["shaft_length"])
	cone.radial_segments = SHAFT_SEGMENTS
	cone.cap_top = false
	cone.cap_bottom = false
	var view := MeshInstance3D.new()
	view.name = "LightShaft"
	view.mesh = cone
	view.material_override = WoodsMaterials.glow(Tuning.palette("shaft"), Tuning.palette("shaft").a)
	view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var toward_sun: Vector3 = sun.basis.z
	var side: Vector3 = toward_sun.cross(Vector3.BACK).normalized()
	view.basis = Basis(side, toward_sun, side.cross(toward_sun))
	var ground := Vector3(float(spot[0]), shape.height(float(spot[0]), float(spot[1])), float(spot[1]))
	view.position = ground + toward_sun * cone.height * 0.5
	return view
