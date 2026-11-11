class_name NoonFx
extends Control
## Noon on screen: a white-gold flash over everything, a sun disc swelling at the top, both fading out.

const TIME: float = 1.2
const DISC: float = 90.0

var _t: float = 0.0


static func spawn(ui: CanvasLayer) -> void:
	var f := NoonFx.new()
	f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	f.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(f)


func _process(delta: float) -> void:
	_t += delta
	if _t > TIME:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var vs: Vector2 = get_viewport_rect().size
	var k: float = _t / TIME
	draw_rect(Rect2(Vector2.ZERO, vs), Color(Pal.c("sun"), 0.55 * (1.0 - k) * (1.0 - k)))
	var c := Vector2(vs.x * 0.5, vs.y * 0.18)
	for i: int in 4:
		draw_circle(c, DISC * (0.4 + k * 0.6) * (1.0 + i * 0.35), Color(Pal.c("gold"), 0.18 * (1.0 - k)))
	draw_circle(c, DISC * 0.4 * (1.0 + k * 0.3), Color(Pal.c("sun"), 0.9 * (1.0 - k)))
