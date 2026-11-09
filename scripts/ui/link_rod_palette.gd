class_name LinkRodPalette
extends RefCounted
## The Link Rod screen's colour roles, from ApolloPalette. It shares the Ember Tree's warm
## cards and text (EmberTreePalette) and adds the Wardens' cyan for everything chip.

const CHIP := ApolloPalette.SKY
const CHIP_LIGHT := ApolloPalette.SKY_LIGHT
const CHIP_DIM := ApolloPalette.BLUE_DEEP
## The rare overclocked mods stand out from the plain stat mods.
const OVERCLOCK := ApolloPalette.PINK
const LOCKED := ApolloPalette.STONE_LIGHT
## The page behind the cards, over the paused game.
const BACKDROP := Color(ApolloPalette.OUTLINE, 0.9)
## A selected chip's button edge.
const SELECTED_EDGE := ApolloPalette.SKY
