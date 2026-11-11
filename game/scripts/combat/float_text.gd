class_name FloatText
extends Label
## Damage numbers and short world notices: they pop, rise and fade, unlit above everything. Crits are bigger and
## gold; hits on you are red. Spread sideways a little so stacked hits stay readable.

const RISE: float = 24.0
const TIME: float = 0.75
const POP: float = 1.35
const WIDTH: float = 120.0
const SPREAD: float = 10.0
const HEAD: float = 46.0

static var enabled: bool = true


static func spawn(at: Vector2, text: String, color: Color, big: bool = false) -> void:
	if not enabled or Overlay.layer == null:
		return
	var f := FloatText.new()
	f.label_settings = UiDraw.label_settings(UiDraw.TITLE if big else UiDraw.BODY, color)
	f.text = text
	f.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	f.size = Vector2(WIDTH, 24)
	f.pivot_offset = Vector2(WIDTH / 2.0, 12)
	f.position = at + Vector2(-WIDTH / 2.0 + randf_range(-SPREAD, SPREAD), -HEAD)
	f.scale = Vector2.ONE * POP
	Overlay.layer.add_child(f)
	var tw := f.create_tween()
	tw.set_parallel()
	tw.tween_property(f, "scale", Vector2.ONE, 0.12)
	tw.tween_property(f, "position:y", f.position.y - RISE, TIME).set_ease(Tween.EASE_OUT)
	tw.tween_property(f, "modulate:a", 0.0, TIME * 0.4).set_delay(TIME * 0.6)
	tw.chain().tween_callback(f.queue_free)
