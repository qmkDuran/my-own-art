class_name PaletteSwap
extends RefCounted
## Builds and fills materials for the palette-swap shader (scripts/shaders/palette_swap.gdshader):
## each key colour in a sprite is drawn as its matching target colour.

const SHADER := preload("res://scripts/shaders/palette_swap.gdshader")
## Must match MAX_SWAPS in the shader.
const MAX_SWAPS := 8


static func make_material() -> ShaderMaterial:
	var swap_material := ShaderMaterial.new()
	swap_material.shader = SHADER
	return swap_material


## Draws `keys[i]` as `targets[i]` (the two lists pair up, up to MAX_SWAPS).
static func set_swaps(swap_material: ShaderMaterial, keys: PackedColorArray, targets: PackedColorArray) -> void:
	var count := mini(mini(keys.size(), targets.size()), MAX_SWAPS)
	if count < keys.size():
		push_warning("PaletteSwap: only %d swaps fit; the rest are ignored." % MAX_SWAPS)
	swap_material.set_shader_parameter("keys", _padded(keys))
	swap_material.set_shader_parameter("targets", _padded(targets))
	swap_material.set_shader_parameter("swap_count", count)


## The shader's arrays always hold MAX_SWAPS colours.
static func _padded(colors: PackedColorArray) -> PackedColorArray:
	var padded := colors.slice(0, MAX_SWAPS)
	padded.resize(MAX_SWAPS)
	return padded
