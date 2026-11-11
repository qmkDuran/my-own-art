class_name TooltipLayer
extends Control
## Draws the one tooltip on screen, above every panel. Whoever is hovered sets rows each frame via show_rows();
## nothing set this frame = no tooltip.

const GAP: float = 6.0

var _rows: Array = []
var _at: Vector2
var _title_col: Color = UiDraw.TEXT
var _fresh: bool = false
var _worn: Array = []                 ## the item you wear, shown beside the hovered one
var _worn_col: Color = UiDraw.TEXT


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func show_rows(rows: Array, at: Vector2, title_col: Color = UiDraw.TEXT) -> void:
	_worn = []
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
	if _rows.is_empty():
		return
	var r: Rect2 = UiDraw.tooltip(self, _at, _rows, _title_col)
	if not _worn.is_empty():
		var w: Vector2 = UiDraw.tooltip_size(self, _worn)
		var x: float = r.position.x - w.x - GAP if r.position.x - w.x - GAP > 4.0 else r.end.x + GAP
		UiDraw.tooltip(self, Vector2(x - 14.0, r.position.y - 10.0), _worn, _worn_col)


## A new item and the one it would replace, side by side (the worn one on the far side, labelled).
func show_pair(rows: Array, worn: Array, at: Vector2, title_col: Color, worn_col: Color) -> void:
	show_rows(rows, at, title_col)
	_worn = [["Equipped", UiDraw.DIM]] + worn
	_worn_col = worn_col
