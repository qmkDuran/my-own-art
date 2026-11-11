class_name TooltipLayer
extends Control
## Draws the one tooltip on screen, above every panel. Whoever is hovered sets rows each frame via show_rows();
## nothing set this frame = no tooltip.

var _rows: Array = []
var _at: Vector2
var _title_col: Color = UiDraw.TEXT
var _fresh: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func show_rows(rows: Array, at: Vector2, title_col: Color = UiDraw.TEXT) -> void:
	_rows = rows
	_at = at
	_title_col = title_col
	_fresh = true


func _process(_delta: float) -> void:
	if not _fresh:
		_rows = []
	_fresh = false
	queue_redraw()


func _draw() -> void:
	if not _rows.is_empty():
		UiDraw.tooltip(self, _at, _rows, _title_col)
