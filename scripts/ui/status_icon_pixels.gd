class_name StatusIconPixels
extends RefCounted
## The 7×7 pixel icons of the player's status effects in the HUD (see StatusIcons), by the
## effect's node name, each with its colours. Effects without an icon here aren't shown
## (e.g. Buffeted: a gust's push is too short for one).

## Poison: a toxic droplet. 'd' rim, 'g' body, 'w' shine.
const POISON := [
	"...d...",
	"..dgd..",
	"..dgd..",
	".dwggd.",
	".dwggd.",
	".dgggd.",
	"..ddd..",
]
const POISON_COLORS := {"d": StatusColors.POISON_DARK, "g": StatusColors.POISON, "w": ApolloPalette.LIME_PALE}

## Stagger: a stone impact burst. 'c' the burst, 'l' its bright heart.
const STAGGER := [
	"...c...",
	".c.c.c.",
	"..clc..",
	"cclllcc",
	"..clc..",
	".c.c.c.",
	"...c...",
]
const STAGGER_COLORS := {"c": StatusColors.STAGGER, "l": StatusColors.STAGGER_LIGHT}

const SIZE := Vector2i(7, 7)


## The icon's pixels (Vector2i -> Color) for the effect called `effect_name`; empty if none.
static func icon_for(effect_name: String) -> Dictionary:
	match effect_name:
		Poisoned.NODE_NAME:
			return PixelShape.colored(PixelShape.from_rows(POISON), POISON_COLORS)
		Staggered.NODE_NAME:
			return PixelShape.colored(PixelShape.from_rows(STAGGER), STAGGER_COLORS)
	return {}


## The colour of the effect's draining timer bar.
static func timer_color_for(effect_name: String) -> Color:
	return StatusColors.STAGGER if effect_name == Staggered.NODE_NAME else StatusColors.POISON
