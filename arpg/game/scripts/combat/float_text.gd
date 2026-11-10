class_name FloatText
extends Label
## Damage numbers and short notices that rise and fade over the world (unlit, above everything).

const RISE: float = 26.0
const TIME: float = 0.8


static func spawn(_parent: Node, at: Vector2, text: String, color: Color, big: bool = false) -> void:
	var f := FloatText.new()
	var ls := LabelSettings.new()
	ls.font_size = 32 if big else 16
	ls.font_color = color
	ls.outline_size = 6 if big else 4
	ls.outline_color = Color("2e222f")
	f.label_settings = ls
	f.text = text
	f.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	f.size = Vector2(120, 20)
	f.position = at + Vector2(-60 + randf_range(-6, 6), -70)
	f.z_index = 30
	f.light_mask = 0
	Overlay.layer.add_child(f)
	var tw := f.create_tween()
	tw.set_parallel()
	tw.tween_property(f, "position:y", f.position.y - RISE, TIME).set_ease(Tween.EASE_OUT)
	tw.tween_property(f, "modulate:a", 0.0, TIME * 0.5).set_delay(TIME * 0.5)
	tw.chain().tween_callback(f.queue_free)
