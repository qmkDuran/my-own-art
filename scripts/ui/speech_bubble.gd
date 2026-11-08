class_name SpeechBubble
extends Node2D
## A short line of speech above a character (e.g. a Warden shouting "Go, Toxlop!").
## Pops in, stays for a moment, fades out.

@export var font_size: int = 6
@export var text_color: Color = Color(0.906, 0.835, 0.702)
@export var background: Color = Color(0.075, 0.05, 0.055, 0.85)
@export var border: Color = Color(0.871, 0.62, 0.255, 0.8)


func say(text: String, seconds: float = 1.4) -> void:
	for child in get_children():
		child.queue_free()

	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	style.content_margin_left = 3
	style.content_margin_right = 3
	style.content_margin_top = 1
	style.content_margin_bottom = 1
	panel.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", text_color)
	panel.add_child(label)
	add_child(panel)

	# Centre the bubble above this node once its size is known.
	await get_tree().process_frame
	panel.position = Vector2(-panel.size.x / 2.0, -panel.size.y)
	panel.pivot_offset = Vector2(panel.size.x / 2.0, panel.size.y)
	panel.scale = Vector2(0.6, 0.6)
	var pop := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop.tween_property(panel, "scale", Vector2.ONE, 0.18)
	pop.tween_interval(seconds)
	pop.tween_property(panel, "modulate:a", 0.0, 0.25)
	pop.tween_callback(panel.queue_free)
