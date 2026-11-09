class_name SpeechBubble
extends Node2D
## A short line of speech above a character (e.g. a Warden shouting "Go, Toxlop!").
## Fades in, stays for a moment, fades out.

## Half of Monogram's native 16 px: one font pixel is half a game pixel (two screen pixels
## at 4×), as fine as the HUD's cards and the Ember Tree, and still crisp.
@export var font_size: int = 8
@export var text_color: Color = ApolloPalette.CREAM
## A light see-through bubble with no border, so speech in the world never hides the fight.
@export var background: Color = Color(ApolloPalette.OUTLINE, 0.6)


func say(text: String, seconds: float = 1.4) -> void:
	for child in get_children():
		child.queue_free()

	var panel := PanelContainer.new()
	panel.theme = EmberTreeFonts.ui_theme()
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.set_corner_radius_all(3)
	style.content_margin_left = 3
	style.content_margin_right = 3
	style.content_margin_top = 1
	style.content_margin_bottom = 1
	panel.add_theme_stylebox_override("panel", style)
	panel.add_child(UiLabel.make(font_size, text_color, text))
	add_child(panel)

	# Centre the bubble above this node once its size is known.
	await get_tree().process_frame
	if not is_instance_valid(panel):
		return  # a newer line replaced this one in the meantime
	panel.position = Vector2(-panel.size.x / 2.0, -panel.size.y)
	panel.pivot_offset = Vector2(panel.size.x / 2.0, panel.size.y)
	# Fade in while rising slightly, hold, then fade out (no popping).
	var resting_y := panel.position.y
	panel.position.y = resting_y + 3.0
	panel.modulate.a = 0.0
	var appearance := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).set_parallel()
	appearance.tween_property(panel, "modulate:a", 1.0, 0.3)
	appearance.tween_property(panel, "position:y", resting_y, 0.3)
	appearance.chain().tween_interval(seconds)
	appearance.chain().tween_property(panel, "modulate:a", 0.0, 0.4)
	appearance.chain().tween_callback(panel.queue_free)
