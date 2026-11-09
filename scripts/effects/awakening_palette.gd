class_name AwakeningPalette
extends RefCounted
## Emberoo's look at each Awakening stage: the same sprite, recoloured by the palette-swap
## shader (see PaletteSwap). Every colour is an Apollo colour.
##
##   Not awakened: his own colours.
##   Awakening I, "Blue Flame": fur a deeper ember orange, the flames on his ears and tail
##       tip blue (EmberooFlameMarker finds them), the gold highlights on his ears, tail and
##       fists blue-white. The gloves stay red.
##   Awakening II: darker again (deep brick shading, a night-blue outline) with white-hot
##       highlights; the fur keeps Awakening I's ember orange so he never sinks into dirt
##       paths. Its quiet flame shimmer is AwakeningAura.
## The cream belly never changes, so he stays the clearest thing on screen.

const FUR := ApolloPalette.ORANGE
const FUR_SHADE := ApolloPalette.ORANGE_DARK
const HIGHLIGHT := ApolloPalette.GOLD
const OUTLINE := ApolloPalette.OUTLINE
const FLAME_TIP := EmberooFlameMarker.FLAME_RED_MARK

## Per stage: key colour -> the colour it is drawn in. Stage 0 only turns the flame-tip
## key back into the red it came from.
const LOOKS: Array[Dictionary] = [
	{FLAME_TIP: ApolloPalette.RED_LIGHT},
	{
		FUR: ApolloPalette.ORANGE_DARK, FUR_SHADE: ApolloPalette.RUST,
		HIGHLIGHT: ApolloPalette.SKY_LIGHT, FLAME_TIP: ApolloPalette.SKY,
	},
	{
		FUR: ApolloPalette.ORANGE_DARK, FUR_SHADE: ApolloPalette.BRICK, OUTLINE: ApolloPalette.NAVY,
		HIGHLIGHT: ApolloPalette.WHITE, FLAME_TIP: ApolloPalette.SKY,
	},
]
## Matches only the exact colour: the flame-tip key is a single step off the glove red.
const EXACT_MATCH_TOLERANCE := 0.5 / 255.0


## Gives `sprite` the look of Awakening `stage`, reusing its material when it has one.
## Its frames must be marked first (EmberooFlameMarker.mark_frames).
static func apply(sprite: CanvasItem, stage: int) -> void:
	var swap_material := sprite.material as ShaderMaterial
	if swap_material == null:
		swap_material = PaletteSwap.make_material()
		swap_material.set_shader_parameter("tolerance", EXACT_MATCH_TOLERANCE)
		sprite.material = swap_material
	var look: Dictionary = LOOKS[clampi(stage, 0, LOOKS.size() - 1)]
	PaletteSwap.set_swaps(swap_material, PackedColorArray(look.keys()), PackedColorArray(look.values()))
