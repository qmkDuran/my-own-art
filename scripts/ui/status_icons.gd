class_name StatusIcons
extends Control
## The player's status effects as small pixel icons beside the HUD heart (7×7, outlined,
## see StatusIconPixels), the first one nearest the heart, each with a thin timer bar below it
## that drains as the effect runs out. An effect shows only while it works, not during the
## immunity after it.
##
## The control's right edge sits next to the heart; icons are laid out leftward from it.

## Pixels from one icon's left edge to the next.
const SPACING := 11
## The timer bar: one pixel tall, this far below the icon's top, inside a dark outline.
const BAR_TOP := 9
## Darkened part of the timer bar (time already gone).
const BAR_EMPTY_COLOR := ApolloPalette.COAL_DARK

## Effect node names to show, each with its icon pixels (cached).
var _icons := {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var player := PlayerFinder.find(self)
	if player == null:
		return
	var right_slot := size.x - StatusIconPixels.SIZE.x - 1
	var slot := 0
	for child in player.get_children():
		var effect := child as StatusEffect
		if effect == null or not effect.is_active():
			continue
		var icon := _icon_for(effect.name)
		if icon.is_empty():
			continue
		_draw_icon(icon, effect, Vector2(right_slot - slot * SPACING, 1))
		slot += 1


func _draw_icon(icon: Dictionary, effect: StatusEffect, top_left: Vector2) -> void:
	PixelShape.draw_outlined(self, icon, top_left, ApolloPalette.OUTLINE)
	var width := StatusIconPixels.SIZE.x
	var share := clampf(effect.seconds_left() / maxf(effect.full_length(), 0.001), 0.0, 1.0)
	var bar_left := top_left + Vector2(0, BAR_TOP)
	draw_rect(Rect2(bar_left - Vector2.ONE, Vector2(width + 2, 3)), ApolloPalette.OUTLINE)
	draw_rect(Rect2(bar_left, Vector2(width, 1)), BAR_EMPTY_COLOR)
	draw_rect(Rect2(bar_left, Vector2(ceilf(width * share), 1)), StatusIconPixels.timer_color_for(effect.name))


func _icon_for(effect_name: String) -> Dictionary:
	if not _icons.has(effect_name):
		_icons[effect_name] = StatusIconPixels.icon_for(effect_name)
	return _icons[effect_name]
