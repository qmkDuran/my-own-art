class_name HudOrb
extends Control
## A life or Oil orb: liquid in glass (shaders/orb.gdshader), its level easing to the value and, after a loss, a
## pale ghost of the old level draining after it. The frame and the outlined number are drawn on top.

const EASE: float = 10.0               ## how fast the liquid follows the value
const GHOST_HOLD: float = 0.35         ## the ghost waits this long after a loss, then drains
const GHOST_DRAIN: float = 0.9         ## of the full orb per second
const RIM: float = 2.0

var label: String = ""
var _mat := ShaderMaterial.new()
var _rect := ColorRect.new()
var _over := Control.new()
var _shown: float = 1.0
var _ghost: float = 1.0
var _hold: float = 0.0
var _t: float = 0.0


func setup(deep: Color, mid: Color, bright: Color) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mat.shader = preload("res://shaders/orb.gdshader")
	_mat.set_shader_parameter("deep", deep)
	_mat.set_shader_parameter("mid", mid)
	_mat.set_shader_parameter("bright", bright)
	_rect.material = _mat
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rect)
	_over.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_over.set_anchors_preset(Control.PRESET_FULL_RECT)
	_over.draw.connect(_draw_over)
	add_child(_over)


func place(r: Rect2) -> void:
	position = r.position
	size = r.size
	_rect.position = Vector2.ONE * RIM
	_rect.size = r.size - Vector2.ONE * RIM * 2.0
	_mat.set_shader_parameter("pixel", _rect.size.x)


func set_value(frac: float, delta: float) -> void:
	frac = clampf(frac, 0.0, 1.0)
	if frac < _shown - 0.002 and _ghost <= _shown + 0.002:
		_hold = GHOST_HOLD                                   # a loss: the ghost stays at the old level a moment
		_ghost = _shown
	_shown = lerpf(_shown, frac, minf(1.0, EASE * delta))
	_hold -= delta
	if _hold <= 0.0:
		_ghost = move_toward(_ghost, _shown, GHOST_DRAIN * delta)
	_ghost = maxf(_ghost, _shown)
	_t += delta
	_mat.set_shader_parameter("fill", _shown)
	_mat.set_shader_parameter("ghost", _ghost)
	_mat.set_shader_parameter("time", _t)
	_over.queue_redraw()


## The glass frame and the number go on a layer above the liquid.
func _draw_over() -> void:
	var c: Vector2 = size / 2.0
	var rad: float = size.x * 0.5
	_over.draw_arc(c, rad - 1.0, 0.0, TAU, 48, UiDraw.INK, 2.0)
	_over.draw_arc(c, rad - 1.0, 0.0, TAU, 48, UiDraw.FRAME, 1.0)
	_over.draw_arc(c, rad, PI * 1.2, PI * 1.8, 16, UiDraw.FRAME_LIT, 1.0)
	UiDraw.text(_over, Vector2(0, c.y + 4.0), label, UiDraw.TEXT, UiDraw.SMALL, HORIZONTAL_ALIGNMENT_CENTER, size.x)
