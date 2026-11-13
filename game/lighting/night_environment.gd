class_name NightEnvironment
extends WorldEnvironment
## The night's atmosphere from data/lighting.json: the starry sky, ambient light, AgX tone mapping with a warm/cool
## colour grade, glow, screen-space reflections and ambient occlusion, distance fog, volumetric fog (thicker in a
## low layer over the streets), and how all of it thickens when it rains.

const SKY_SHADER: Shader = preload("res://shaders/night_sky.gdshader")
const SKY_RADIANCE: int = 256
const SKY_KEYS: Array[String] = ["glow_height", "star_density", "star_brightness", "moon_size", "moon_energy", "halo",
	"cloud_cover", "rain_cloud_cover"]
const SKY_COLOURS: Array[String] = ["top", "horizon", "glow", "moon_color", "cloud"]
const GLOW_LEVELS: Array[int] = [2, 3, 4, 5]
const GRADE_SIZE: int = 256

var _env: Environment
var _ground_fog: FogMaterial


func setup() -> void:
	name = "NightEnvironment"
	_env = Environment.new()
	_sky()
	_light_and_tone()
	_glow()
	_screen_space()
	_fog()
	_grade()
	environment = _env
	_add_ground_fog()
	set_rain(0.0)


## 0 = clear night, 1 = full rain: fog thickens.
func set_rain(mix: float) -> void:
	_env.fog_density = lerpf(Tuning.look_f("fog", "density"), Tuning.look_f("fog", "rain_density"), mix)
	_env.volumetric_fog_density = lerpf(Tuning.look_f("volumetric", "density"), Tuning.look_f("volumetric",
		"rain_density"), mix)


func _sky() -> void:
	var material := ShaderMaterial.new()
	material.shader = SKY_SHADER
	for key: String in SKY_KEYS:
		material.set_shader_parameter(key, Tuning.look_f("sky", key))
	for key: String in SKY_COLOURS:
		material.set_shader_parameter(key + ("" if key.ends_with("color") else "_color"), Tuning.look_color("sky", key))
	var sky := Sky.new()
	sky.sky_material = material
	sky.radiance_size = Sky.RADIANCE_SIZE_256
	sky.process_mode = Sky.PROCESS_MODE_REALTIME
	_env.background_mode = Environment.BG_SKY
	_env.sky = sky


func _light_and_tone() -> void:
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.ambient_light_color = Tuning.look_color("ambient", "color")
	_env.ambient_light_energy = Tuning.look_f("ambient", "energy")
	_env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	_env.tonemap_mode = Environment.TONE_MAPPER_AGX
	_env.tonemap_exposure = Tuning.look_f("tonemap", "exposure")
	_env.tonemap_white = Tuning.look_f("tonemap", "white")


func _glow() -> void:
	_env.glow_enabled = true
	for level: int in GLOW_LEVELS:
		_env.set_glow_level(level, 1.0)
	_env.glow_intensity = Tuning.look_f("glow", "intensity")
	_env.glow_strength = Tuning.look_f("glow", "strength")
	_env.glow_bloom = Tuning.look_f("glow", "bloom")
	_env.glow_hdr_threshold = Tuning.look_f("glow", "hdr_threshold")
	_env.glow_hdr_scale = Tuning.look_f("glow", "hdr_scale")
	_env.glow_mix = Tuning.look_f("glow", "mix")
	_env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN


func _screen_space() -> void:
	_env.ssr_enabled = true
	_env.ssr_max_steps = Tuning.i_look("ssr", "max_steps")
	_env.ssr_fade_in = Tuning.look_f("ssr", "fade_in")
	_env.ssr_fade_out = Tuning.look_f("ssr", "fade_out")
	_env.ssr_depth_tolerance = Tuning.look_f("ssr", "depth_tolerance")
	_env.ssao_enabled = true
	_env.ssao_radius = Tuning.look_f("ssao", "radius")
	_env.ssao_intensity = Tuning.look_f("ssao", "intensity")
	_env.ssao_power = Tuning.look_f("ssao", "power")


func _fog() -> void:
	_env.fog_enabled = true
	_env.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	_env.fog_light_color = Tuning.look_color("fog", "color")
	_env.fog_sky_affect = Tuning.look_f("fog", "sky_affect")
	_env.fog_height = Tuning.look_f("fog", "height")
	_env.fog_height_density = Tuning.look_f("fog", "height_density")
	_env.fog_aerial_perspective = Tuning.look_f("fog", "aerial")
	_env.volumetric_fog_enabled = true
	_env.volumetric_fog_albedo = Tuning.look_color("volumetric", "albedo")
	_env.volumetric_fog_emission = Tuning.look_color("volumetric", "emission")
	_env.volumetric_fog_anisotropy = Tuning.look_f("volumetric", "anisotropy")
	_env.volumetric_fog_length = Tuning.look_f("volumetric", "length")
	_env.volumetric_fog_ambient_inject = Tuning.look_f("volumetric", "ambient_inject")
	_env.volumetric_fog_sky_affect = Tuning.look_f("volumetric", "sky_affect")


## The warm/cool grade: shadows lean blue, highlights lean warm (a per-channel curve).
func _grade() -> void:
	_env.adjustment_enabled = true
	_env.adjustment_brightness = Tuning.look_f("grade", "brightness")
	_env.adjustment_contrast = Tuning.look_f("grade", "contrast")
	_env.adjustment_saturation = Tuning.look_f("grade", "saturation")
	var curve := Gradient.new()
	curve.set_color(0, Tuning.look_color("grade", "shadow_tint"))
	curve.set_color(1, Tuning.look_color("grade", "highlight"))
	curve.add_point(0.5, Tuning.look_color("grade", "mid"))
	var texture := GradientTexture1D.new()
	texture.gradient = curve
	texture.width = GRADE_SIZE
	_env.adjustment_color_correction = texture


## A thicker layer of volumetric fog hugging the streets.
func _add_ground_fog() -> void:
	var bounds: Array = Tuning.doc("town")["bounds"]
	var height: float = Tuning.look_f("volumetric", "ground_height")
	_ground_fog = FogMaterial.new()
	_ground_fog.density = Tuning.look_f("volumetric", "ground_density")
	_ground_fog.height_falloff = 1.0 / height
	_ground_fog.albedo = Tuning.look_color("volumetric", "albedo")
	var volume := FogVolume.new()
	volume.name = "GroundFog"
	volume.shape = RenderingServer.FOG_VOLUME_SHAPE_BOX
	volume.size = Vector3(float(bounds[2]) - float(bounds[0]), height * 2.0, float(bounds[3]) - float(bounds[1]))
	volume.material = _ground_fog
	add_child(volume)
