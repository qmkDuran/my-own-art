class_name LinkRodPalette
extends RefCounted
## The Link Rod screen's colour roles, from ApolloPalette. It shares the Ember Tree's stone
## cards, ember highlights and text (EmberTreePalette) and adds the Wardens' cyan for
## everything chip.

const CHIP := ApolloPalette.SKY
const CHIP_LIGHT := ApolloPalette.SKY_LIGHT
const CHIP_DIM := ApolloPalette.BLUE_DEEP
## The rare overclocked mods stand out from the plain stat mods.
const OVERCLOCK := ApolloPalette.PINK
const LOCKED := ApolloPalette.STONE_LIGHT
## The page behind the cards. Opaque: while the screen is open the paused game behind it
## is drawn at the screen's 2× canvas (smaller, off-centre), which must not show through.
const BACKDROP := ApolloPalette.OUTLINE
## A selected chip's button: lit by the ember like every selected thing (EmberTreePalette),
## its fill and bevel (lit and shaded sides).
const SELECTED_FILL := EmberTreePalette.HOT_FILL
const SELECTED_EDGE := EmberTreePalette.HOT_EDGE
const SELECTED_EDGE_DARK := EmberTreePalette.HOT_EDGE_DARK
