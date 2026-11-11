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
var _avoid: Rect2 = Rect2()            ## a panel the pair must not cover (the open inventory)


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
	if _worn.is_empty():
		UiDraw.tooltip(self, _at, _rows, _title_col)
		return
	var a: Vector2 = UiDraw.tooltip_size(self, _rows)
	var w: Vector2 = UiDraw.tooltip_size(self, _worn)
	var width: float = a.x + GAP + w.x
	var x: float = _avoid.position.x - GAP - width                  # beside the panel, never over it
	if x < 4.0:
		x = _avoid.end.x + GAP
	var y: float = _at.y - minf(a.y, w.y) * 0.3
	UiDraw.tooltip_at(self, Vector2(x, y), _worn, _worn_col)       # worn on the far side, the new one next to the panel
	UiDraw.tooltip_at(self, Vector2(x + w.x + GAP, y), _rows, _title_col)


## A new item and the one it would replace, side by side (the worn one on the far side, labelled), placed beside
## `avoid` (the inventory panel) so they never cover it.
func show_pair(rows: Array, worn: Array, at: Vector2, title_col: Color, worn_col: Color, avoid: Rect2) -> void:
	show_rows(rows, at, title_col)
	_avoid = avoid
	_worn = [["Equipped", UiDraw.DIM]] + worn
	_worn_col = worn_col
