class_name HeatFlame
extends Control
## Emberoo's Heat as one big flame to the right of the skill bar, with the numbers inside it.
##
## The flame lights up from the bottom as Heat builds (the tips light last) and sits as dark coal
## when cold. When a skill is refused for lack of Heat, the flame shakes and flashes briefly.

## Pixel map of the flame (25×26). 'x' = inside the flame.
const FLAME_PIXELS := [
	"............x............",
	"...........xx............",
	"...........xxx...........",
	"..........xxxx...........",
	"..........xxxxx......x...",
	".........xxxxxx.....xx...",
	".........xxxxxxx...xxx...",
	"....x...xxxxxxxx..xxxx...",
	"....xx..xxxxxxxxx.xxxx...",
	"...xxx..xxxxxxxxxxxxxx...",
	"...xxxx.xxxxxxxxxxxxxxx..",
	"..xxxxxxxxxxxxxxxxxxxxx..",
	"..xxxxxxxxxxxxxxxxxxxxx..",
	".xxxxxxxxxxxxxxxxxxxxxxx.",
	".xxxxxxxxxxxxxxxxxxxxxxx.",
	".xxxxxxxxxxxxxxxxxxxxxxx.",
	".xxxxxxxxxxxxxxxxxxxxxxx.",
	".xxxxxxxxxxxxxxxxxxxxxxx.",
	".xxxxxxxxxxxxxxxxxxxxxxx.",
	".xxxxxxxxxxxxxxxxxxxxxxx.",
	"..xxxxxxxxxxxxxxxxxxxxx..",
	"..xxxxxxxxxxxxxxxxxxxxx..",
	"...xxxxxxxxxxxxxxxxxxx...",
	"....xxxxxxxxxxxxxxxxx....",
	"......xxxxxxxxxxxxx......",
	"........xxxxxxxxx........",
]
const FLAME_SIZE := Vector2i(25, 26)
## The lit share is measured from this row down, so the thin tips are the last to light.
const BODY_TOP_ROW := 6
## Rim pixels below this row burn a deeper red.
const DEEP_RIM_FROM_ROW := FLAME_SIZE.y * 0.7
## Top of the numbers, from the top of the flame.
const NUMBERS_TOP := 17
## How long the "not enough Heat" shake lasts, and how far it moves, in pixels.
const REFUSED_SECONDS := 0.3
const SHAKE_PIXELS := 1.0

var _heat: int = 0
var _max_heat: int = 0
var _refused_left: float = 0.0
var _shape: Dictionary = PixelShape.from_rows(FLAME_PIXELS)
var _depths: Dictionary = PixelShape.depths(_shape)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	await get_tree().process_frame
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var heat: Heat = player.get_node_or_null("Heat")
	if heat == null:
		return
	heat.heat_changed.connect(_on_heat_changed)
	_on_heat_changed(heat.heat, heat.max_heat)


func _process(delta: float) -> void:
	if _refused_left > 0.0:
		_refused_left = maxf(0.0, _refused_left - delta)
		queue_redraw()


## A skill wanted more Heat than there is: shake and flash for a moment.
func show_not_enough_heat() -> void:
	_refused_left = REFUSED_SECONDS


func _on_heat_changed(heat: int, max_heat: int) -> void:
	_heat = heat
	_max_heat = max_heat
	queue_redraw()


func _draw() -> void:
	if _max_heat <= 0:
		return
	var origin := Vector2(_shake_offset(), 0)
	PixelShape.draw_outlined(self, _flame_colors(), origin, _outline_color())
	var numbers := "%d/%d" % [_heat, _max_heat]
	var left := floori((FLAME_SIZE.x - PixelFont.width_of(numbers)) / 2.0) + 1
	PixelFont.draw_text(self, numbers, origin + Vector2(left, NUMBERS_TOP), HudPalette.CREAM, HudPalette.OUTLINE)


## Left-right jitter while a refusal is showing: right, left, right... one pixel each step.
func _shake_offset() -> float:
	if _refused_left <= 0.0:
		return 0.0
	var step := int(_refused_left / 0.05)
	return SHAKE_PIXELS if step % 2 == 0 else -SHAKE_PIXELS


## The outline flashes red while a refusal is showing.
func _outline_color() -> Color:
	return HudPalette.RED_LIGHT if _refused_left > REFUSED_SECONDS * 0.5 else HudPalette.OUTLINE


## The colour of every flame pixel: fire from the bottom up to the Heat share, dark coal above.
func _flame_colors() -> Dictionary:
	var first_lit_row := -1.0
	if _heat < _max_heat:
		first_lit_row = BODY_TOP_ROW + (FLAME_SIZE.y - BODY_TOP_ROW) * (1.0 - float(_heat) / float(_max_heat))
	var surface_row := ceili(first_lit_row) if first_lit_row > 0.0 else -1
	var colors := {}
	for pixel: Vector2i in _shape:
		var depth: int = _depths[pixel]
		if pixel.y < first_lit_row:
			colors[pixel] = HudPalette.BRICK if depth == 0 else HudPalette.COAL
		elif pixel.y == surface_row and depth > 0:
			colors[pixel] = HudPalette.GOLD
		else:
			colors[pixel] = _fire_color(pixel, depth)
	return colors


## Lit fire: a red rim, orange just inside, a gold heart.
func _fire_color(pixel: Vector2i, depth: int) -> Color:
	if depth == 0:
		return HudPalette.RED if pixel.y > DEEP_RIM_FROM_ROW else HudPalette.RED_LIGHT
	return HudPalette.ORANGE if depth < 4 else HudPalette.GOLD
