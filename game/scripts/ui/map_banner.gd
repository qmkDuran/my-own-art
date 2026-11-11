class_name MapBanner
extends Control
## The place-name plate that slides in at the top left when you enter a map.

const SHOW_TIME: float = 1.6
const H: int = 17

var _panel: Panel
var _label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel = UiKit.panel(Rect2(4, -H - 2, 80, H), "ink2", "ink")
	add_child(_panel)
	_label = UiKit.label("", "cream")
	_label.position = Vector2(6, 1)
	_panel.add_child(_label)


func show_name(text: String) -> void:
	_label.text = text
	_panel.size.x = UiKit.text_width(text) + 12
	var tw: Tween = create_tween()
	tw.tween_property(_panel, "position:y", 4.0, 0.2)
	tw.tween_interval(SHOW_TIME)
	tw.tween_property(_panel, "position:y", -H - 2.0, 0.2)
