class_name SpeechBubble
extends Node2D
## A short line of speech above a character (e.g. a Warden shouting "Go, Toxlop!").
## Fades in, stays for a moment, fades out.
##
## It's UI, not part of the world, so the night darkness and lights never touch it.

@export var font_size: int = 6
@export var text_color: Color = Color(0.906, 0.835, 0.702)
## Same see-through dark card as the discovery toast, with no border.
@export var background: Color = Color(0.035, 0.039, 0.078, 0.6)

const UNSHADED := preload("res://scenes/effects/unshaded_material.tres")


func _ready() -> void:
	material = UNSHADED


func say(text: String, seconds: float = 1.4) -> void:
	for child in get_children():
		child.queue_free()

	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.set_corner_radius_all(3)
	style.content_margin_left = 3
	style.content_margin_right = 3
	style.content_margin_top = 1
	style.content_margin_bottom = 1
	panel.add_theme_stylebox_override("panel", style)
	panel.use_parent_material = true
	var label := Label.new()
	label.use_parent_material = true
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", text_color)
	panel.add_child(label)
	add_child(panel)

	# Centre the bubble above this node once its size is known.
	await get_tree().process_frame
	panel.position = Vector2(-panel.size.x / 2.0, -panel.size.y)
	panel.pivot_offset = Vector2(panel.size.x / 2.0, panel.size.y)
	# Fade in while rising slightly, hold, then fade out (no popping).
	var resting_y := panel.position.y
	panel.position.y = resting_y + 3.0
	panel.modulate.a = 0.0
	var show := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).set_parallel()
	show.tween_property(panel, "modulate:a", 1.0, 0.3)
	show.tween_property(panel, "position:y", resting_y, 0.3)
	show.chain().tween_interval(seconds)
	show.chain().tween_property(panel, "modulate:a", 0.0, 0.4)
	show.chain().tween_callback(panel.queue_free)
