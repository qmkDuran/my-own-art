class_name HudPalette
extends RefCounted
## The in-fight HUD's colour roles (skill slots, minimap, bars), from ApolloPalette.
##
## Like the cards (EmberTreePalette), the frames are cold, dark stone so they sit with the
## gritty world; the ember's gold and orange only mark what is ready or pointed at. The
## heart, the Heat flame, loot and crit colours keep their own bright colours.

## The stone frame round a slot or the minimap: outline, lit top and left, shaded rest.
const FRAME_OUTLINE := ApolloPalette.OUTLINE
const FRAME_LIT := ApolloPalette.STONE_LIGHT
const FRAME_SHADE := ApolloPalette.SLATE
## Inside a frame: a dark well, a step lighter in its top half, and its inner glint.
const WELL := ApolloPalette.NIGHT
const WELL_TOP := ApolloPalette.DARK
const WELL_GLINT := ApolloPalette.STONE
## The ember: a slot that is ready (its top edge) and a pointed-at slot (its ring).
const READY_EDGE := ApolloPalette.GOLD
const HOVER_RING := ApolloPalette.ORANGE
## An empty bar's trough (XP, boss and status bars).
const BAR_TROUGH := ApolloPalette.SLATE
