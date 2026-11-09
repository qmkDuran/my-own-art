class_name DeathScreen
extends CanvasLayer
## The dark that falls over the screen when the player falls, with "EMBEROO FELL" in the
## HUD's pixel font at twice its size (a whole-number scale, so it stays crisp), and lifts again once they are back up (Respawner runs both).
## Its fades ignore the time scale, so the death's slow motion doesn't drag them out.

const TEXT := "EMBEROO FELL"
## How dark the screen gets (the darkness's alpha).
const DARKNESS := 0.92
## The text sits this far below the screen's middle, in game pixels (where Emberoo was).
const TEXT_DROP := 10.0
## Game pixels per font pixel: big enough to read as the moment it is, not a HUD label.
const TEXT_SCALE := 2

var _shade := ColorRect.new()
var _text := Control.new()


func _ready() -> void:
	_shade.color = Color(ApolloPalette.OUTLINE, DARKNESS)
	_shade.modulate.a = 0.0
	_text.modulate.a = 0.0
	for part: Control in [_shade, _text]:
		part.set_anchors_preset(Control.PRESET_FULL_RECT)
		part.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(part)
	_text.draw.connect(_draw_text)


## Darkens the screen and shows the text over `seconds`; await it to know when it's dark.
func fade_out(seconds: float) -> void:
	await _fade_to(1.0, seconds).finished


## Lifts the dark and the text over `seconds`.
func fade_in(seconds: float) -> void:
	_fade_to(0.0, seconds)


func _fade_to(alpha: float, seconds: float) -> Tween:
	var fade := create_tween().set_ignore_time_scale(true).set_parallel()
	fade.tween_property(_shade, "modulate:a", alpha, seconds)
	fade.tween_property(_text, "modulate:a", alpha, seconds)
	return fade


func _draw_text() -> void:
	var screen := _text.get_viewport_rect().size
	var top_left := Vector2(floorf((screen.x - PixelFont.width_of(TEXT) * TEXT_SCALE) / 2.0), floorf(screen.y / 2.0 + TEXT_DROP))
	_text.draw_set_transform(top_left, 0.0, Vector2.ONE * TEXT_SCALE)
	PixelFont.draw_text(_text, TEXT, Vector2.ZERO, ApolloPalette.RED_LIGHT, ApolloPalette.OUTLINE)
	_text.draw_set_transform(Vector2.ZERO)
