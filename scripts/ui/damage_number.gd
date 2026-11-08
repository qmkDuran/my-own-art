class_name DamageNumber
extends Node2D
## A small pixel-font number that pops up from a hit, drifts up and fades away, then frees itself.
##
## Drawn with PixelFont at whole-pixel offsets, so it stays crisp while it rises.

## Pixels the number rises over its life.
const RISE_HEIGHT := 8.0
## Seconds from popping up to gone.
const LIFETIME := 0.7
## Share of the lifetime (0 to 1) after which it starts to fade.
const FADE_START := 0.45
## Hits of at least this much damage show in gold instead of white (e.g. Flame Uppercut).
const BIG_HIT := 3

var _text: String = ""
var _color: Color = HudPalette.WHITE
var _age: float = 0.0


## Starts showing `amount`; call right after adding the number to the tree.
func pop(amount: int) -> void:
	_text = str(amount)
	_color = HudPalette.GOLD if amount >= BIG_HIT else HudPalette.WHITE
	queue_redraw()


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return
	var life_share := _age / LIFETIME
	modulate.a = 1.0 - clampf((life_share - FADE_START) / (1.0 - FADE_START), 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	# Eases out: a quick pop up, then it hangs for a moment while it fades.
	var life_share := clampf(_age / LIFETIME, 0.0, 1.0)
	var rise := roundf(RISE_HEIGHT * (1.0 - pow(1.0 - life_share, 3.0)))
	var top_left := Vector2(-floorf(PixelFont.width_of(_text) / 2.0), -PixelFont.GLYPH_HEIGHT - rise)
	PixelFont.draw_text(self, _text, top_left, _color, HudPalette.OUTLINE)
