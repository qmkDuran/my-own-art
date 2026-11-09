class_name EmberooFlameColors
extends RefCounted
## The colours of Emberoo's fire, in one place: fist embers, the jab impacts and crits, the
## Flame Uppercut arc, the Spinning Hook's fire ring, Ember Hop's trail and landing, the
## Ash Guard wall, Wildfire's streak, burn embers and the dodge's afterimages read them here.
##
## Before he Awakens his fire is gold, orange and red; once Awakened it burns blue-white,
## and at Awakening II a richer, deeper blue. The Awakening autoload sets `awakening_stage`.
## Effects read the colours when they start, so a burst already playing never switches.

## Hottest to coolest, per Awakening stage (always five, so effects can index them alike).
const FIRE_RAMPS: Array[Array] = [
	[ApolloPalette.GOLD, ApolloPalette.ORANGE, ApolloPalette.ORANGE_MID, ApolloPalette.RED_LIGHT, ApolloPalette.RED],
	[ApolloPalette.WHITE, ApolloPalette.SKY_LIGHT, ApolloPalette.SKY_LIGHT, ApolloPalette.SKY, ApolloPalette.BLUE],
	[ApolloPalette.WHITE, ApolloPalette.SKY_LIGHT, ApolloPalette.SKY, ApolloPalette.BLUE, ApolloPalette.BLUE_DEEP],
]
## The flashier ramp his attacks burst in: white-hot core, then the fire ramp's falloff
## (gold, orange, red before he Awakens). Always six, hottest first.
const BURST_RAMPS: Array[Array] = [
	[ApolloPalette.WHITE, ApolloPalette.GOLD, ApolloPalette.ORANGE, ApolloPalette.ORANGE_MID, ApolloPalette.RED_LIGHT, ApolloPalette.RED],
	[ApolloPalette.WHITE, ApolloPalette.SKY_LIGHT, ApolloPalette.SKY, ApolloPalette.SKY, ApolloPalette.BLUE, ApolloPalette.BLUE_DEEP],
	[ApolloPalette.WHITE, ApolloPalette.SKY_LIGHT, ApolloPalette.SKY, ApolloPalette.BLUE, ApolloPalette.BLUE_DEEP, ApolloPalette.NAVY_MID],
]
## Index of the hottest, warm and cool colours in a ramp.
const HOT := 0
const WARM := 1
const COOL := 3
## How see-through the dodge's afterimages are.
const AFTERIMAGE_ALPHA := 0.6

## The Awakening stage the colours follow (0 = not Awakened).
static var awakening_stage: int = 0


## The five fire colours, hottest first, for the current Awakening.
static func fire_ramp() -> Array[Color]:
	var ramp: Array[Color] = []
	ramp.assign(FIRE_RAMPS[clampi(awakening_stage, 0, FIRE_RAMPS.size() - 1)])
	return ramp


## The six burst colours (white-hot first), for the current Awakening.
static func burst_ramp() -> Array[Color]:
	var ramp: Array[Color] = []
	ramp.assign(BURST_RAMPS[clampi(awakening_stage, 0, BURST_RAMPS.size() - 1)])
	return ramp


static func hot() -> Color:
	return fire_ramp()[HOT]


static func warm() -> Color:
	return fire_ramp()[WARM]


static func cool() -> Color:
	return fire_ramp()[COOL]


## The tint of the dodge's afterimages: his fur colour before, his flame colour after.
static func afterimage_tint() -> Color:
	var base := ApolloPalette.ORANGE if awakening_stage == 0 else ApolloPalette.SKY
	return Color(base, AFTERIMAGE_ALPHA)
