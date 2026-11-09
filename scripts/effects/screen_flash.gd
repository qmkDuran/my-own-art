class_name ScreenFlash
extends CanvasLayer
## A quick, light full-screen wash of colour for the biggest hits (a Signal Skill, a
## reaction). Kept faint and short so it tints the moment without hiding the fight, and
## flashes never stack: one asked for within a few frames of the last is skipped (e.g. a
## Steam Burst's white flash and the uppercut's gold flash on the same swap).

const START_ALPHA := 0.22
const FADE_SECONDS := 0.12
## A flash asked for this few rendered frames after the last one is skipped.
const MIN_GAP_FRAMES := 12

static var _last_flash_frame: int = -MIN_GAP_FRAMES


## Flashes the screen `color` at `alpha`, fading out at once (unless one just flashed).
static func play(asker: Node, color: Color, alpha: float = START_ALPHA) -> void:
	var now := Engine.get_process_frames()
	if now - _last_flash_frame < MIN_GAP_FRAMES:
		return
	_last_flash_frame = now
	var flash := ScreenFlash.new()
	flash.layer = 50
	var cover := ColorRect.new()
	cover.color = Color(color, alpha)
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cover.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.add_child(cover)
	asker.get_tree().current_scene.add_child(flash)
	var fade := cover.create_tween().set_ignore_time_scale(true)
	fade.tween_property(cover, "color:a", 0.0, FADE_SECONDS)
	fade.tween_callback(flash.queue_free)
