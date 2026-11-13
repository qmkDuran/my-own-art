class_name SurfaceMaterials
## The materials of the code-made town parts: cobbles for the streets, bricks for walls, steps and the canal,
## plaster for fillers, and the canal water. One shared material per kind.

const STONE_SHADER: Shader = preload("res://shaders/stone.gdshader")
const WATER_SHADER: Shader = preload("res://shaders/water.gdshader")
const PATTERNS: Dictionary = { "cobbles": 0, "bricks": 1, "plaster": 2 }
const COLOURS: Dictionary = {
	"cobbles": [Color(0.4, 0.39, 0.42), Color(0.5, 0.45, 0.41), Color(0.12, 0.11, 0.12)],
	"bricks": [Color(0.42, 0.37, 0.34), Color(0.5, 0.44, 0.38), Color(0.16, 0.14, 0.13)],
	"plaster": [Color(0.62, 0.55, 0.45), Color(0.66, 0.6, 0.5), Color(0.5, 0.44, 0.36)],
}

static var _cache: Dictionary = {}


static func stone(pattern: String) -> ShaderMaterial:
	if not _cache.has(pattern):
		var material := ShaderMaterial.new()
		material.shader = STONE_SHADER
		material.set_shader_parameter("pattern", PATTERNS[pattern])
		var colours: Array = COLOURS[pattern]
		material.set_shader_parameter("base_color", colours[0])
		material.set_shader_parameter("alt_color", colours[1])
		material.set_shader_parameter("mortar_color", colours[2])
		_cache[pattern] = material
	return _cache[pattern]


static func water() -> ShaderMaterial:
	if not _cache.has("water"):
		var material := ShaderMaterial.new()
		material.shader = WATER_SHADER
		_cache["water"] = material
	return _cache["water"]
