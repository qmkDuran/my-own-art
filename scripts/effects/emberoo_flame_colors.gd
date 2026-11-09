class_name EmberooFlameColors
extends RefCounted
## The colours of Emberoo's fire, in one place: fist embers, the jab impacts and crits, the
## Flame Uppercut flame, the Spinning Hook's fire ring, Ember Hop's trail and landing, the
## Ash Guard wall, Wildfire's streak, burn embers and the dodge's afterimages read them here.
##
## His fire is gold, orange and red in every evolution form: the new art is what changes as
## he Awakens (see HeroFormSwitch), not the colour of his flames.

## Hottest to coolest (five, so effects can index them alike).
const FIRE_RAMP: Array[Color] = [
	ApolloPalette.GOLD, ApolloPalette.ORANGE, ApolloPalette.ORANGE_MID, ApolloPalette.RED_LIGHT, ApolloPalette.RED,
]
## The flashier ramp his attacks burst in: white-hot core, then the fire ramp's falloff.
## Six, hottest first.
const BURST_RAMP: Array[Color] = [
	ApolloPalette.WHITE, ApolloPalette.GOLD, ApolloPalette.ORANGE, ApolloPalette.ORANGE_MID, ApolloPalette.RED_LIGHT, ApolloPalette.RED,
]
## Index of the hottest, warm and cool colours in a ramp.
const HOT := 0
const WARM := 1
const COOL := 3
## The tint of the dodge's afterimages (his fur colour), and how see-through they are.
const AFTERIMAGE_TINT := Color(ApolloPalette.ORANGE, 0.6)


## The five fire colours, hottest first (a copy, so callers may change it).
static func fire_ramp() -> Array[Color]:
	return FIRE_RAMP.duplicate()


## The six burst colours, white-hot first (a copy, so callers may change it).
static func burst_ramp() -> Array[Color]:
	return BURST_RAMP.duplicate()


static func hot() -> Color:
	return FIRE_RAMP[HOT]


static func warm() -> Color:
	return FIRE_RAMP[WARM]


static func cool() -> Color:
	return FIRE_RAMP[COOL]
