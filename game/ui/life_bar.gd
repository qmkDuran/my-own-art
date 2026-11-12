class_name LifeBar
extends Control
## A life bar with the creature's name and current life. Turns red when low.

const BAR_HEIGHT: float = 16.0
const NAME_GAP: float = 6.0

var _health: Health
var _title: String
var _color: Color


func setup(health: Health, title: String, color: Color, bar_size: Vector2) -> void:
	_health = health
	_title = title
	_color = color
	custom_minimum_size = bar_size
	size = bar_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var bar := Rect2(Vector2(0, size.y - BAR_HEIGHT), Vector2(size.x, BAR_HEIGHT))
	HudStyle.panel(self, bar)
	var share: float = _health.fraction()
	var low: bool = share <= Tuning.f("hud", "low_health_fraction")
	var fill := Rect2(bar.position + Vector2.ONE * HudStyle.EDGE_WIDTH,
			Vector2((bar.size.x - HudStyle.EDGE_WIDTH * 2.0) * share, bar.size.y - HudStyle.EDGE_WIDTH * 2.0))
	draw_rect(fill, HudStyle.LIFE_LOW if low else _color)
	var baseline: float = bar.position.y - NAME_GAP
	HudStyle.text(self, Vector2(0, baseline), _title, HudStyle.FONT_MEDIUM, HudStyle.INK,
			HORIZONTAL_ALIGNMENT_LEFT, size.x)
	HudStyle.text(self, Vector2(0, baseline), "%d / %d" % [ceili(_health.current), int(_health.maximum)],
			HudStyle.FONT_SMALL, HudStyle.INK_DIM, HORIZONTAL_ALIGNMENT_RIGHT, size.x)
