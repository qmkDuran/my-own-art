class_name XpBar
extends Control
## The level ("LV 4") and a slim XP bar in the top-left corner, mirroring the minimap.
## Lights up for a moment when the player levels up.

## Length of the bar itself, in game pixels.
const BAR_LENGTH := 74
## Gap between the level label and the bar.
const LABEL_GAP := 4
## The bar's row, from the top of the label.
const BAR_TOP := 2
const FLASH_SECONDS := 0.5

var _flash_left: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	Progression.xp_changed.connect(func(_xp: int, _next: int) -> void: queue_redraw())
	Progression.leveled_up.connect(_on_leveled_up)


func _process(delta: float) -> void:
	if _flash_left > 0.0:
		_flash_left = maxf(0.0, _flash_left - delta)
		queue_redraw()


func _on_leveled_up(_level: int) -> void:
	_flash_left = FLASH_SECONDS
	queue_redraw()


func _draw() -> void:
	var is_flashing := _flash_left > 0.0
	var label := "LV %d" % Progression.level
	PixelFont.draw_text(self, label, Vector2.ZERO, HudPalette.WHITE if is_flashing else HudPalette.GOLD, HudPalette.OUTLINE)
	var bar_left := PixelFont.width_of(label) + LABEL_GAP
	var bar := Rect2(bar_left, BAR_TOP, BAR_LENGTH, 1)
	draw_rect(bar.grow(1.0), HudPalette.OUTLINE)
	draw_rect(bar, HudPalette.SLATE)
	var filled := roundi(BAR_LENGTH * _share_to_next_level())
	if filled <= 0:
		return
	draw_rect(Rect2(bar.position, Vector2(filled, 1)), HudPalette.SKY_LIGHT if is_flashing else HudPalette.SKY)
	draw_rect(Rect2(bar.position + Vector2(filled - 1, 0), Vector2.ONE), HudPalette.SKY_LIGHT)


func _share_to_next_level() -> float:
	return clampf(float(Progression.xp) / float(maxi(1, Progression.xp_to_next())), 0.0, 1.0)
