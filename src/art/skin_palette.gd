class_name SkinPalette
extends RefCounted
## Skin-tone palette swap. Skin in hero and Mom art is painted with the key ramp: the key colour
## (data/heroes.json "skin_key") darkened by each of FACTORS. The shader swaps every key shade
## for the same shade of the chosen tone, so one set of sprites serves every skin tone.

const SHADER := preload("res://shaders/skin_palette.gdshader")
const FACTORS: Array[float] = [0.0, 0.1, 0.12, 0.15, 0.2, 0.3, 0.45]

static var _cache: Dictionary = {}


static func material(tone: Color) -> ShaderMaterial:
	var key := tone.to_html()
	if _cache.has(key):
		return _cache[key]
	var base := Color.from_string(String(DB.heroes.get("skin_key", "#c89070")), Color("c89070"))
	var keys := PackedColorArray()
	var targets := PackedColorArray()
	for factor: float in FACTORS:
		keys.append(base.darkened(factor))
		targets.append(tone.darkened(factor))
	var result := ShaderMaterial.new()
	result.shader = SHADER
	result.set_shader_parameter("key_colors", keys)
	result.set_shader_parameter("target_colors", targets)
	_cache[key] = result
	return result
