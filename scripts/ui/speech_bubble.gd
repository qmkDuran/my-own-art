class_name SpeechBubble
extends Node2D
## A short line of speech above a character (e.g. a Warden shouting "Go, Toxlop!").
## Fades in, stays for a moment, fades out.

## Bubble padding (left/right, top/bottom) and corner radius, in pixels.
const PADDING := Vector2i(3, 1)
const CORNER_RADIUS := 3
## How far the bubble rises while fading in, in pixels.
const RISE := 3.0
const FADE_IN_SECONDS := 0.3
const FADE_OUT_SECONDS := 0.4
const DEFAULT_SECONDS := 1.4

## Half of Monogram's native 16 px: one font pixel is half a game pixel (two screen pixels
## at 4×), as fine as the HUD's cards and the Ember Tree, and still crisp.
@export var font_size: int = 8
@export var text_color: Color = ApolloPalette.CREAM
## A light see-through bubble with no border, so speech in the world never hides the fight.
@export var background: Color = Color(ApolloPalette.OUTLINE, 0.6)


## Shows `text` for `seconds` (after fading in), replacing any line still showing.
func say(text: String, seconds: float = DEFAULT_SECONDS) -> void:
	for child in get_children():
		child.queue_free()
	var panel := _make_panel(text)
	add_child(panel)
	# Centre the bubble above this node once its size is known.
	await get_tree().process_frame
	if not is_instance_valid(panel):
		return  # a newer line replaced this one in the meantime
	panel.position = Vector2(-panel.size.x / 2.0, -panel.size.y)
	panel.pivot_offset = Vector2(panel.size.x / 2.0, panel.size.y)
	_fade_in_and_out(panel, seconds)


func _make_panel(text: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.theme = EmberTreeFonts.ui_theme()
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.set_corner_radius_all(CORNER_RADIUS)
	style.content_margin_left = PADDING.x
	style.content_margin_right = PADDING.x
	style.content_margin_top = PADDING.y
	style.content_margin_bottom = PADDING.y
	panel.add_theme_stylebox_override("panel", style)
	panel.add_child(UiLabel.make(font_size, text_color, text))
	return panel


## Fades in while rising slightly, holds for `seconds`, then fades out (no popping).
func _fade_in_and_out(panel: PanelContainer, seconds: float) -> void:
	var resting_y := panel.position.y
	panel.position.y = resting_y + RISE
	panel.modulate.a = 0.0
	var fade := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).set_parallel()
	fade.tween_property(panel, "modulate:a", 1.0, FADE_IN_SECONDS)
	fade.tween_property(panel, "position:y", resting_y, FADE_IN_SECONDS)
	fade.chain().tween_interval(seconds)
	fade.chain().tween_property(panel, "modulate:a", 0.0, FADE_OUT_SECONDS)
	fade.chain().tween_callback(panel.queue_free)
