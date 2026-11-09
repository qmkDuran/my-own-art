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

## Root: a sprout curling out of the ground. 'g' the vine, 'l' its bright leaf.
const ROOT := [
	"...l...",
	"..llg..",
	"...g...",
	"g..g..g",
	".g.g.g.",
	"..ggg..",
	"ggggggg",
]
const ROOT_COLORS := {"g": StatusColors.ROOT, "l": StatusColors.ROOT_LIGHT}

## Soak: a falling drop over a puddle. 'b' water, 's' its shine.
const SOAK := [
	"...b...",
	"..bsb..",
	".bsbbb.",
	".bbbbb.",
	"..bbb..",
	".......",
	"sbbbbbs",
]
const SOAK_COLORS := {"b": StatusColors.SOAK, "s": StatusColors.SOAK_LIGHT}

## Chill: a snowflake. 'c' the arms, 'w' its bright heart.
const CHILL := [
	"c..c..c",
	".c.c.c.",
	"..cwc..",
	"cccwccc",
	"..cwc..",
	".c.c.c.",
	"c..c..c",
]
const CHILL_COLORS := {"c": StatusColors.CHILL, "w": StatusColors.CHILL_LIGHT}

## Jolt: a lightning bolt. 'y' the bolt, 'w' its hot core.
const JOLT := [
	"....yy.",
	"...yy..",
	"..ywy..",
	".yyyyy.",
	"..ywy..",
	"..yy...",
	".yy....",
]
const JOLT_COLORS := {"y": StatusColors.JOLT, "w": StatusColors.JOLT_LIGHT}

## Each shown effect: its pixel rows, its colours and its timer bar colour.
const ICONS := {
	Poisoned.NODE_NAME: [POISON, POISON_COLORS, StatusColors.POISON],
	Staggered.NODE_NAME: [STAGGER, STAGGER_COLORS, StatusColors.STAGGER],
	Rooted.NODE_NAME: [ROOT, ROOT_COLORS, StatusColors.ROOT],
	Soaked.NODE_NAME: [SOAK, SOAK_COLORS, StatusColors.SOAK],
	Chilled.NODE_NAME: [CHILL, CHILL_COLORS, StatusColors.CHILL],
	Jolted.NODE_NAME: [JOLT, JOLT_COLORS, StatusColors.JOLT],
}

const SIZE := Vector2i(7, 7)


## The icon's pixels (Vector2i -> Color) for the effect called `effect_name`; empty if none.
static func icon_for(effect_name: String) -> Dictionary:
	if not ICONS.has(effect_name):
		return {}
	var icon: Array = ICONS[effect_name]
	return PixelShape.colored(PixelShape.from_rows(icon[0]), icon[1])


## The colour of the effect's draining timer bar.
static func timer_color_for(effect_name: String) -> Color:
	return ICONS[effect_name][2] if ICONS.has(effect_name) else StatusColors.POISON
