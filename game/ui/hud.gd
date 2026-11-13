class_name Hud
extends CanvasLayer
## A quiet on-screen hint of the controls that fades after a while (H brings it back), and a small note when the
## rain starts or stops. The town is the show, so the HUD stays out of the way.

const HINT: String = "WASD walk   Shift run (tap: dash)   Space jump   N night   R rain   G graphics   H hints"
const SHADOW: Color = Color(0.0, 0.0, 0.0, 0.6)

var _hint: Label
var _timer: float = 0.0


func setup() -> void:
	name = "Hud"
	process_mode = Node.PROCESS_MODE_ALWAYS
	_hint = Label.new()
	_hint.text = HINT
	_hint.add_theme_font_size_override("font_size", Tuning.i("hud", "font_size"))
	_hint.add_theme_color_override("font_shadow_color", SHADOW)
	_hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_KEEP_SIZE,
		Tuning.i("hud", "margin"))
	_hint.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(_hint)
	show_hints()


func hint_label() -> Label:
	return _hint


func show_hints() -> void:
	_timer = Tuning.f("hud", "hint_seconds")


## A short line in the hint's place (for example "It starts to rain").
func note(text: String) -> void:
	_hint.text = text
	_timer = Tuning.f("hud", "hint_fade_seconds") * 2.0


func _process(delta: float) -> void:
	_timer = maxf(_timer - delta, 0.0)
	_hint.modulate.a = clampf(_timer / Tuning.f("hud", "hint_fade_seconds"), 0.0, 1.0)
	if _timer == 0.0:
		_hint.text = HINT


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_hints"):
		_hint.text = HINT
		show_hints()
