class_name AwakeningPalette
extends RefCounted
## Emberoo's look at each Awakening stage: the same sprite, recoloured by the palette-swap
## shader (see PaletteSwap), plus a sky-blue SilhouetteRim from Awakening II. Every colour
## is an Apollo colour.
##
##   Not awakened: his own colours.
##   Awakening I, "Blue Flame": fur a deeper ember orange, the flames on his ears and tail
##       tip blue (EmberooFlameMarker finds them), the gold highlights on his ears, tail and
##       fists blue-white. The gloves stay red.
##   Awakening II: darker again (deep brick shading) with white-hot highlights; the fur keeps
##       Awakening I's ember orange so he never sinks into dirt paths. His dark outline stays,
##       with a 1px sky-blue rim around it. Its quiet flame shimmer is AwakeningAura.
## The cream belly never changes, so he stays the clearest thing on screen.

const FUR := ApolloPalette.ORANGE
const FUR_SHADE := ApolloPalette.ORANGE_DARK
const HIGHLIGHT := ApolloPalette.GOLD
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
		FUR: ApolloPalette.ORANGE_DARK, FUR_SHADE: ApolloPalette.BRICK,
		HIGHLIGHT: ApolloPalette.WHITE, FLAME_TIP: ApolloPalette.SKY,
	},
]
## Matches only the exact colour: the flame-tip key is a single step off the glove red.
const EXACT_MATCH_TOLERANCE := 0.5 / 255.0
## The outer rim around his silhouette, from this stage on.
const RIM_COLOR := ApolloPalette.SKY
const RIM_FROM_STAGE := AwakeningStage.TWO


## Gives `sprite` the look of Awakening `stage`, reusing its material and rim when it has
## them. Its frames must be marked first (EmberooFlameMarker.mark_frames).
static func apply(sprite: AnimatedSprite2D, stage: int) -> void:
	_apply_swaps(sprite, stage)
	_apply_rim(sprite, stage)


static func _apply_swaps(sprite: AnimatedSprite2D, stage: int) -> void:
	var swap_material := sprite.material as ShaderMaterial
	if swap_material == null:
		swap_material = PaletteSwap.make_material()
		swap_material.set_shader_parameter("tolerance", EXACT_MATCH_TOLERANCE)
		sprite.material = swap_material
	var look: Dictionary = LOOKS[clampi(stage, 0, LOOKS.size() - 1)]
	PaletteSwap.set_swaps(swap_material, PackedColorArray(look.keys()), PackedColorArray(look.values()))


static func _apply_rim(sprite: AnimatedSprite2D, stage: int) -> void:
	var rim: SilhouetteRim = null
	for child in sprite.get_children():
		if child is SilhouetteRim:
			rim = child
	var wants_rim := stage >= RIM_FROM_STAGE
	if rim == null and wants_rim:
		rim = SilhouetteRim.new(RIM_COLOR)
		sprite.add_child(rim)
	if rim != null:
		rim.visible = wants_rim
