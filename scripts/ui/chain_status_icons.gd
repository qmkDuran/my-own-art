class_name ChainStatusIcons
extends RefCounted
## The 7×7 pixel icons of the chain statuses (Burning, Soaked, Rooted, Airborne, Broken,
## Poisoned), by SetUp status name, each in its own colours. One look for a status
## everywhere: a lit team card shows the icon of the status that armed it, and the chain
## guide (Tab) uses the same icons in its tables. Apollo palette only.

const SIZE := 7

## Burning: a flame. 'o' orange, 'y' gold, 'w' its pale heart.
const BURNING := [
	"...o...",
	"..oo.o.",
	".ooyoo.",
	".oyyyo.",
	"oyyyyyo",
	"oyywyyo",
	".ooooo.",
]
const BURNING_COLORS := {"o": ApolloPalette.ORANGE, "y": ApolloPalette.GOLD, "w": ApolloPalette.CREAM}

## Soaked: a water drop. 'd' rim, 'b' water, 'w' shine.
const SOAKED := [
	"...d...",
	"..dbd..",
	"..dbd..",
	".dwbbd.",
	".dwbbd.",
	".dbbbd.",
	"..ddd..",
]
const SOAKED_COLORS := {"d": ApolloPalette.BLUE, "b": ApolloPalette.SKY, "w": ApolloPalette.WHITE}

## Rooted: a sprout over its roots. 'g' leaves, 'c' roots.
const ROOTED := [
	".g...g.",
	"ggg.ggg",
	"..ggg..",
	"...c...",
	"..ccc..",
	".c.c.c.",
	"c..c..c",
]
const ROOTED_COLORS := {"g": ApolloPalette.GREEN_LIGHT, "c": ApolloPalette.CORK}

## Airborne (Launched): an arrow up over a gust. 'w' arrow, 's' wind.
const LAUNCHED := [
	"...w...",
	"..www..",
	".w.w.w.",
	"...w...",
	"...w...",
	"s.....s",
	".sssss.",
]
const LAUNCHED_COLORS := {"w": ApolloPalette.WHITE, "s": ApolloPalette.SKY_LIGHT}

## Broken: a gold star. 'y' star, 'w' its shine.
const BROKEN := [
	"...y...",
	"..yyy..",
	"yyywyyy",
	".yyyyy.",
	"..yyy..",
	".yy.yy.",
	".y...y.",
]
const BROKEN_COLORS := {"y": ApolloPalette.GOLD, "w": ApolloPalette.CREAM}

## The status's main colour, for frames, glows and table text.
const COLORS := {
	SetUp.BURNING: ApolloPalette.ORANGE,
	SetUp.SOAKED: ApolloPalette.SKY,
	SetUp.ROOTED: ApolloPalette.GREEN_LIGHT,
	SetUp.LAUNCHED: ApolloPalette.SKY_LIGHT,
	SetUp.BROKEN: ApolloPalette.GOLD,
	SetUp.POISONED: ApolloPalette.GREEN_LIGHT,
}
## What players call each status (Launched reads as "Airborne").
const NAMES := {
	SetUp.BURNING: "Burning",
	SetUp.SOAKED: "Soaked",
	SetUp.ROOTED: "Rooted",
	SetUp.LAUNCHED: "Airborne",
	SetUp.BROKEN: "Broken",
	SetUp.POISONED: "Poisoned",
}

static var _cache: Dictionary = {}


## The icon's pixels (Vector2i -> Color) for `status_name`; empty if it has none.
static func pixels_of(status_name: String) -> Dictionary:
	if not _cache.has(status_name):
		_cache[status_name] = _build(status_name)
	return _cache[status_name]


static func color_of(status_name: String) -> Color:
	return COLORS.get(status_name, ApolloPalette.WHITE)


static func name_of(status_name: String) -> String:
	return NAMES.get(status_name, status_name)


## Draws the icon outlined with its top-left at `top_left`, each icon pixel `pixel_size`
## canvas pixels wide (the outline takes one icon pixel around it).
static func draw(canvas: CanvasItem, status_name: String, top_left: Vector2, pixel_size: int = 1) -> void:
	var pixels := pixels_of(status_name)
	if pixels.is_empty():
		return
	canvas.draw_set_transform(top_left, 0.0, Vector2(pixel_size, pixel_size))
	PixelShape.draw_outlined(canvas, pixels, Vector2.ZERO, ApolloPalette.OUTLINE)
	canvas.draw_set_transform(Vector2.ZERO)


static func _build(status_name: String) -> Dictionary:
	match status_name:
		SetUp.BURNING:
			return PixelShape.colored(PixelShape.from_rows(BURNING), BURNING_COLORS)
		SetUp.SOAKED:
			return PixelShape.colored(PixelShape.from_rows(SOAKED), SOAKED_COLORS)
		SetUp.ROOTED:
			return PixelShape.colored(PixelShape.from_rows(ROOTED), ROOTED_COLORS)
		SetUp.LAUNCHED:
			return PixelShape.colored(PixelShape.from_rows(LAUNCHED), LAUNCHED_COLORS)
		SetUp.BROKEN:
			return PixelShape.colored(PixelShape.from_rows(BROKEN), BROKEN_COLORS)
		SetUp.POISONED:
			return PixelShape.colored(PixelShape.from_rows(StatusIconPixels.POISON), StatusIconPixels.POISON_COLORS)
	return {}
