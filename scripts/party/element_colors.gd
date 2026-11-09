class_name ElementColors
extends RefCounted
## The colour of each element (see PROJECT_B.md, "Elements"), for the team cards and swap
## bursts. Built from the Apollo palette only.

const BY_ELEMENT := {
	"Fire": ApolloPalette.ORANGE,
	"Toxic": ApolloPalette.GREEN_LIGHT,
	"Wind": ApolloPalette.SKY_LIGHT,
	"Stone": ApolloPalette.CORK,
	"Tide": ApolloPalette.SKY,
	"Spark": ApolloPalette.GOLD,
	"Bloom": ApolloPalette.GREEN,
	"Frost": ApolloPalette.SILVER,
	"Shadow": ApolloPalette.MAGENTA,
	"Light": ApolloPalette.CREAM,
}


static func for_element(element: String) -> Color:
	return BY_ELEMENT.get(element, ApolloPalette.WHITE)
