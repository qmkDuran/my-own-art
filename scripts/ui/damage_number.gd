class_name DamageNumber
extends Node2D
## A small pixel-font number that pops up from a hit, drifts up and fades away, then frees itself.
##
## Normal hits are small and white. Critical hits are gold with a "!" (e.g. "4!") and bigger,
## with a two-step pop: a flash at POP_SCALE, then they settle at CRIT_SCALE.
## Burn ticks are small and orange, so they read as the fire, not as a punch.
## Drawn with PixelFont at whole-pixel offsets and whole-number scales, so it stays crisp.

## Pixels the number rises over its life.
const RISE_HEIGHT := 8.0
## Seconds from popping up to gone.
const LIFETIME := 0.7
## Share of the lifetime (0 to 1) after which it starts to fade.
const FADE_START := 0.45
## Shown after a critical hit's number.
const CRIT_MARK := "!"
## A critical number's size: first POP_SCALE for POP_TIME seconds, then CRIT_SCALE.
const POP_SCALE := 3.0
const CRIT_SCALE := 2.0
const POP_TIME := 0.08
const NORMAL_COLOR := ApolloPalette.WHITE
const CRIT_COLOR := ApolloPalette.GOLD
const BURN_COLOR := ApolloPalette.ORANGE

var _text: String = ""
var _color: Color = NORMAL_COLOR
var _is_critical: bool = false
var _start_position: Vector2 = Vector2.ZERO
var _age: float = 0.0


## Starts showing `amount`; call right after adding the number to the tree and placing it.
func pop(amount: int, is_critical: bool = false, damage_type: Health.DamageType = Health.DamageType.DIRECT) -> void:
	_is_critical = is_critical
	_text = str(amount) + (CRIT_MARK if is_critical else "")
	_color = _color_for(is_critical, damage_type)
	_start_position = position.round()
	_update_motion()
	queue_redraw()


static func _color_for(is_critical: bool, damage_type: Health.DamageType) -> Color:
	if is_critical:
		return CRIT_COLOR
	return BURN_COLOR if damage_type == Health.DamageType.BURN else NORMAL_COLOR


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return
	_update_motion()


## Rises (easing out: a quick pop up, then it hangs for a moment while it fades),
## always by whole pixels so the text never blurs.
func _update_motion() -> void:
	var life_share := clampf(_age / LIFETIME, 0.0, 1.0)
	var rise := roundf(RISE_HEIGHT * (1.0 - pow(1.0 - life_share, 3.0)))
	position = _start_position - Vector2(0, rise)
	modulate.a = 1.0 - clampf((life_share - FADE_START) / (1.0 - FADE_START), 0.0, 1.0)
	var size := 1.0
	if _is_critical:
		size = POP_SCALE if _age < POP_TIME else CRIT_SCALE
	scale = Vector2(size, size)


## Bottom centre on the node's origin, so a bigger scale grows upward from the hit.
func _draw() -> void:
	var top_left := Vector2(-floorf(PixelFont.width_of(_text) / 2.0), -PixelFont.GLYPH_HEIGHT)
	PixelFont.draw_text(self, _text, top_left, _color, ApolloPalette.OUTLINE)
