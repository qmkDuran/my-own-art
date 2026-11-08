class_name ComboPips
extends Node2D
## Three tiny pips under the attacker's feet showing the combo chain: one lights for each
## attack that lands (jab, jab, then the Spinning Hook), so the player knows the spin is next.
##
## Subtle on purpose: hidden until the first jab lands, and fades out as the combo window
## runs out (or soon after the finisher lands). Reads the chain from MeleeAttack's ComboChain.

## Size of one pip and the gap between pips, in pixels.
const PIP_SIZE := 2
const PIP_GAP := 1
## Seconds the pips take to fade out at the end of the window.
const FADE_TIME := 0.3
## Seconds a finished chain stays lit before it fades.
const FINISHED_HOLD_TIME := 0.25
## Lit pips are silver, the finisher's a brighter white: never orange, so they can't be
## mistaken for Heat.
const LIT_COLOR := ApolloPalette.SILVER
const FINISHER_LIT_COLOR := ApolloPalette.WHITE
const UNLIT_COLOR := ApolloPalette.STONE

@export var melee_attack: MeleeAttack

var _lit_count: int = 0


func _process(_delta: float) -> void:
	var combo := melee_attack.combo if melee_attack != null else null
	var lit_count := combo.landed_steps() if combo != null else 0
	visible = lit_count > 0
	if not visible:
		return
	modulate.a = _opacity(combo)
	if lit_count != _lit_count:
		_lit_count = lit_count
		queue_redraw()


func _opacity(combo: ComboChain) -> float:
	var lit_time := FINISHED_HOLD_TIME + FADE_TIME if combo.is_complete() else combo.reset_time
	var time_left := lit_time - combo.seconds_idle()
	return clampf(time_left / FADE_TIME, 0.0, 1.0)


func _draw() -> void:
	if melee_attack == null or melee_attack.combo == null:
		return
	var pip_count := melee_attack.combo.length
	var row_width := pip_count * PIP_SIZE + (pip_count - 1) * PIP_GAP
	var left := -floori(row_width / 2.0)
	for pip in pip_count:
		var color := UNLIT_COLOR
		if pip < _lit_count:
			color = FINISHER_LIT_COLOR if pip == pip_count - 1 else LIT_COLOR
		var top_left := Vector2(left + pip * (PIP_SIZE + PIP_GAP), 0)
		draw_rect(Rect2(top_left, Vector2(PIP_SIZE, PIP_SIZE)), color)
