class_name XpBar
extends Control
## The level ("LV 4") and a slim XP bar in the top-left corner, mirroring the minimap.
## Lights up for a moment when the player levels up. XP gained slides in: a light leading
## segment shows the new total at once, and the blue fill catches up to it.

## Length of the bar itself, in game pixels.
const BAR_LENGTH := 74
## Gap between the level label and the bar.
const LABEL_GAP := 4
## The bar's row, from the top of the label.
const BAR_TOP := 2
const FLASH_SECONDS := 0.5
## After a gain the fill waits this long, then catches up with the leading segment in CATCH_UP_SECONDS.
const CATCH_UP_DELAY_SECONDS := 0.15
const CATCH_UP_SECONDS := 0.4

var _level_flash := HudMotion.new(FLASH_SECONDS)
var _catch_up_delay := HudMotion.new(CATCH_UP_DELAY_SECONDS)
## The share the blue fill shows (it trails the real share after a gain), and how fast it moves.
var _shown_share: float = 0.0
var _catch_up_per_second: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shown_share = _share_to_next_level()
	Progression.xp_changed.connect(func(_xp: int, _next: int) -> void: _on_xp_changed())
	Progression.leveled_up.connect(_on_leveled_up)


func _process(delta: float) -> void:
	var is_moving := _level_flash.advance(delta)
	is_moving = _catch_up(delta) or is_moving
	if is_moving:
		queue_redraw()


func _on_leveled_up(_level: int) -> void:
	_level_flash.start()
	_shown_share = 0.0
	queue_redraw()


func _on_xp_changed() -> void:
	var share := _share_to_next_level()
	if share > _shown_share:
		_catch_up_delay.start()
		_catch_up_per_second = (share - _shown_share) / CATCH_UP_SECONDS
	else:
		_shown_share = share
	queue_redraw()


## Waits a moment after a gain, then moves the fill up to the real share. True while it moves.
func _catch_up(delta: float) -> bool:
	var share := _share_to_next_level()
	if _catch_up_delay.advance(delta) or _shown_share >= share:
		return false
	_shown_share = minf(share, _shown_share + _catch_up_per_second * delta)
	return true


func _draw() -> void:
	var is_flashing := _level_flash.is_running()
	var label := "LV %d" % Progression.level
	PixelFont.draw_text(self, label, Vector2.ZERO, ApolloPalette.WHITE if is_flashing else ApolloPalette.GOLD, ApolloPalette.OUTLINE)
	var bar_left := PixelFont.width_of(label) + LABEL_GAP
	var bar := Rect2(bar_left, BAR_TOP, BAR_LENGTH, 1)
	draw_rect(bar.grow(1.0), ApolloPalette.OUTLINE)
	draw_rect(bar, ApolloPalette.SLATE)
	var leading := roundi(BAR_LENGTH * _share_to_next_level())
	var filled := roundi(BAR_LENGTH * _shown_share)
	if leading > filled:
		draw_rect(Rect2(bar.position, Vector2(leading, 1)), ApolloPalette.SKY_LIGHT)
	if filled <= 0:
		return
	draw_rect(Rect2(bar.position, Vector2(filled, 1)), ApolloPalette.SKY_LIGHT if is_flashing else ApolloPalette.SKY)
	draw_rect(Rect2(bar.position + Vector2(filled - 1, 0), Vector2.ONE), ApolloPalette.SKY_LIGHT)


func _share_to_next_level() -> float:
	return clampf(float(Progression.xp) / float(maxi(1, Progression.xp_to_next())), 0.0, 1.0)
