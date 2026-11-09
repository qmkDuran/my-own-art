class_name DamageNumber
extends Node2D
## A small pixel-font number that pops up from a hit, drifts up and fades away, then frees itself.
##
## Normal hits are small and white. Critical hits are gold with a "!" (e.g. "4!") and twice
## the size; they pop in with a white flash (a size pop would cover the numbers beside them).
## Status ticks are small and in their element's colour (orange burn, green poison; see
## StatusColors), so they read as the effect, not as a punch.
## Drawn with PixelFont at whole-pixel offsets and whole-number scales, so it stays crisp.
## Quick hits on the same target merge into this number (`add`) while it is young: it shows
## the running total and flashes again, still rising. DamageNumbers places numbers so they
## never overlap (`footprint`).

## Pixels the number rises over its life.
const RISE_HEIGHT := 8.0
## Seconds from popping up to gone.
const LIFETIME := 0.7
## Share of the lifetime (0 to 1) after which it starts to fade.
const FADE_START := 0.45
## Shown after a critical hit's number.
const CRIT_MARK := "!"
## A critical number's size (a whole number, so the font stays crisp).
const CRIT_SCALE := 2
## Seconds a new or grown number shows white before its own colour.
const POP_TIME := 0.08
const POP_COLOR := ApolloPalette.WHITE
const NORMAL_COLOR := StatusColors.DIRECT
const CRIT_COLOR := ApolloPalette.GOLD

var _amount: int = 0
var _damage_type: Health.DamageType = Health.DamageType.DIRECT
var _text: String = ""
var _color: Color = NORMAL_COLOR
var _is_critical: bool = false
var _start_position: Vector2 = Vector2.ZERO
var _age: float = 0.0
var _pop_left: float = 0.0


## Starts showing `amount`; call right after adding the number to the tree and placing it.
func pop(amount: int, is_critical: bool = false, damage_type: Health.DamageType = Health.DamageType.DIRECT) -> void:
	_amount = amount
	_damage_type = damage_type
	_is_critical = is_critical
	_refresh_text()
	_start_position = position.round()
	_update_motion()


## Merges another hit into this number: it shows the total, turns gold if either was a
## crit, and flashes again; it keeps rising where it is, so a flurry reads as one total.
func add(amount: int, is_critical: bool) -> void:
	_amount += amount
	_is_critical = _is_critical or is_critical
	_refresh_text()
	_update_motion()


## Seconds since it popped up.
func age() -> float:
	return _age


## Moves where it starts rising from (its bottom centre), by whole pixels.
func place_at(spot: Vector2) -> void:
	_start_position = spot.round()
	_update_motion()


## Where it started rising from (its bottom centre).
func start_position() -> Vector2:
	return _start_position


## The area it covers once settled, in its parent's space, with a one-pixel margin for the
## outline; DamageNumbers keeps these from overlapping.
func footprint() -> Rect2:
	var size := CRIT_SCALE if _is_critical else 1
	var width := (PixelFont.width_of(_text) + 2) * size
	var height := (PixelFont.GLYPH_HEIGHT + 2) * size
	return Rect2(position.x - ceilf(width / 2.0), position.y - height, width, height)


## The area it covers from now until it stops rising: it only moves up, so two numbers
## whose paths don't meet never overlap.
func path_footprint() -> Rect2:
	var area := footprint()
	var rise_left := RISE_HEIGHT - (_start_position.y - position.y)
	return Rect2(area.position - Vector2(0, rise_left), area.size + Vector2(0, rise_left))


func _refresh_text() -> void:
	_text = str(_amount) + (CRIT_MARK if _is_critical else "")
	_color = _color_for(_is_critical, _damage_type)
	_pop_left = POP_TIME
	queue_redraw()


static func _color_for(is_critical: bool, damage_type: Health.DamageType) -> Color:
	if is_critical:
		return CRIT_COLOR
	return StatusColors.for_damage_type(damage_type)


func _process(delta: float) -> void:
	_age += delta
	if _pop_left > 0.0:
		_pop_left -= delta
		if _pop_left <= 0.0:
			queue_redraw()
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
	var size := CRIT_SCALE if _is_critical else 1
	scale = Vector2(size, size)


## Bottom centre on the node's origin, so a bigger scale grows upward from the hit.
func _draw() -> void:
	var top_left := Vector2(-floorf(PixelFont.width_of(_text) / 2.0), -PixelFont.GLYPH_HEIGHT)
	PixelFont.draw_text(self, _text, top_left, POP_COLOR if _pop_left > 0.0 else _color, ApolloPalette.OUTLINE)
