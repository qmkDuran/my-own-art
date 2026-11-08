class_name SaveToast
extends Node2D
## A tiny "SAVED" note in the pixel font at the top centre, shown for a moment after a
## manual save (DebugControls' F5). Autosaves stay silent.

const TEXT := "SAVED"
const SHOW_SECONDS := 1.0
## Top edge of the text, in screen pixels: just under the debug banner.
const TOP := 11

var _seconds_left: float = 0.0


func show_toast() -> void:
	_seconds_left = SHOW_SECONDS
	queue_redraw()


func _process(delta: float) -> void:
	if _seconds_left <= 0.0:
		return
	_seconds_left -= delta
	if _seconds_left <= 0.0:
		queue_redraw()


func _draw() -> void:
	if _seconds_left <= 0.0:
		return
	var screen_width := get_viewport().get_visible_rect().size.x
	var left := floorf((screen_width - PixelFont.width_of(TEXT)) / 2.0)
	PixelFont.draw_text(self, TEXT, Vector2(left, TOP), ApolloPalette.GREEN_LIGHT, ApolloPalette.OUTLINE)
