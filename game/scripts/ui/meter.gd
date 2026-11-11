class_name Meter
extends Control
## A small pixel bar (HP, XP, Trust, Bond): dark track, coloured fill; HP turns amber then red as it drops.
## `animate_to()` slides the fill so changes read clearly.

const TRACK: String = "ink2"
const HP_COLOURS: Array[String] = ["leaf3", "ember4", "ember2"]
const SLIDE_TIME: float = 0.35

var fraction: float = 1.0
var colour: String = "leaf3"
var hp_style: bool = false


func setup(w: int, h: int, col: String, is_hp: bool = false) -> Meter:
	custom_minimum_size = Vector2(w, h)
	size = custom_minimum_size
	colour = col
	hp_style = is_hp
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	return self


func set_fraction(f: float) -> void:
	fraction = clampf(f, 0.0, 1.0)
	queue_redraw()


func animate_to(f: float) -> void:
	var tw: Tween = create_tween()
	tw.tween_method(set_fraction, fraction, clampf(f, 0.0, 1.0), 0.01 if Game.fast else SLIDE_TIME)
	await tw.finished


func _fill_colour() -> Color:
	if not hp_style:
		return UiKit.c(colour)
	if fraction > 0.5:
		return UiKit.c(HP_COLOURS[0])
	return UiKit.c(HP_COLOURS[1] if fraction > 0.2 else HP_COLOURS[2])


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), UiKit.c("ink"))
	draw_rect(Rect2(Vector2.ONE, size - Vector2(2, 2)), UiKit.c(TRACK))
	var w: float = round((size.x - 2) * fraction)
	if w > 0:
		draw_rect(Rect2(1, 1, w, size.y - 2), _fill_colour())
