class_name ScreenFlash
extends CanvasLayer
## A quick full-screen flash of colour for the biggest hits (e.g. a swap-chain Intro).

const START_ALPHA := 0.45
const FADE_SECONDS := 0.18


## Flashes the screen `color`, fading out at once.
static func play(asker: Node, color: Color) -> void:
	var flash := ScreenFlash.new()
	flash.layer = 50
	var cover := ColorRect.new()
	cover.color = Color(color, START_ALPHA)
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cover.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.add_child(cover)
	asker.get_tree().current_scene.add_child(flash)
	var fade := cover.create_tween().set_ignore_time_scale(true)
	fade.tween_property(cover, "color:a", 0.0, FADE_SECONDS)
	fade.tween_callback(flash.queue_free)
