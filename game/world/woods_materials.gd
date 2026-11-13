class_name WoodsMaterials
## Shared, cached materials for the woods (one per palette colour), so hundreds of props reuse a handful of
## materials. Colours come from the palette in data/woods.json.

const FOLIAGE_SHADER: String = "res://shaders/foliage.gdshader"

static var _cache: Dictionary = {}


static func solid(palette_name: String) -> StandardMaterial3D:
	if not _cache.has(palette_name):
		var material := StandardMaterial3D.new()
		material.albedo_color = Tuning.palette(palette_name)
		material.roughness = 1.0
		_cache[palette_name] = material
	return _cache[palette_name]


static func vertex_colored() -> StandardMaterial3D:
	if not _cache.has("_vertex"):
		var material := StandardMaterial3D.new()
		material.vertex_color_use_as_albedo = true
		material.roughness = 1.0
		_cache["_vertex"] = material
	return _cache["_vertex"]


static func blades() -> StandardMaterial3D:
	if not _cache.has("_blades"):
		var material: StandardMaterial3D = vertex_colored().duplicate()
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		_cache["_blades"] = material
	return _cache["_blades"]


## The wind-swayed foliage material (vertex and instance colours), one per sway strength and height.
static func foliage(strength: float, height: float) -> ShaderMaterial:
	var key: String = "_foliage_%s_%s" % [strength, height]
	if not _cache.has(key):
		var material := ShaderMaterial.new()
		material.shader = load(FOLIAGE_SHADER)
		material.set_shader_parameter("sway_strength", strength)
		material.set_shader_parameter("sway_height", height)
		_cache[key] = material
	return _cache[key]


static func glow(color: Color, alpha: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = Color(color, alpha)
	return material
