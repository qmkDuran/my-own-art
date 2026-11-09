class_name StatusTint
extends Node
## The quiet "this has a status effect" cue on a creature: its sprite's colour pulses gently
## toward a tint and back (e.g. green while poisoned). Subtle on purpose: the player stays
## the brightest thing on screen (see DESIGN.md, visual hierarchy).
##
## Uses the sprite's `modulate` colour only (never alpha, which fades use; HitFlash uses
## self_modulate), and puts it back when it leaves the tree. A status effect adds one for
## its target's Sprite (a target without one simply shows no tint).

## How far the colour moves toward the tint at the pulse's peak (0 = none, 1 = all the way).
const PEAK_STRENGTH := 0.45
## Seconds for one pulse, there and back.
const PULSE_SECONDS := 0.6

var _sprite: CanvasItem
var _tint: Color
var _age: float = 0.0


func _init(sprite: CanvasItem, tint: Color) -> void:
	_sprite = sprite
	_tint = tint


func _process(delta: float) -> void:
	if not is_instance_valid(_sprite):
		return
	_age += delta
	var strength := PEAK_STRENGTH * (0.5 - 0.5 * cos(TAU * _age / PULSE_SECONDS))
	_paint(Color.WHITE.lerp(_tint, strength))


func _exit_tree() -> void:
	if is_instance_valid(_sprite):
		_paint(Color.WHITE)


func _paint(color: Color) -> void:
	_sprite.modulate = Color(color, _sprite.modulate.a)
