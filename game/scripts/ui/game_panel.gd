class_name GamePanel
extends Control
## Base for the windows (inventory, character, skills, passives, menu): a framed panel with a title bar and a
## close box, placed by place() for the current screen size so it always fits above the hotbar. Subclasses draw
## their content in _content() and handle clicks in _click().

signal closed

const CLOSE: float = 14.0
const TOP: float = 8.0
const SIDE: float = 8.0
const CONTENT_Y: float = 30.0

var g: Game
var title: String = ""
var panel_size: Vector2
var side: String = "left"            ## left, right or center


func setup(game: Game, t: String, sz: Vector2, where: String) -> void:
	g = game
	title = t
	panel_size = sz
	side = where
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP


## Where this panel goes on a screen of size vs (also used by the UI check).
func place_rect(vs: Vector2) -> Rect2:
	var cluster: Rect2 = Hud.layout(vs)["cluster"]
	var y: float = maxf(TOP, roundf((cluster.position.y - 6.0 - panel_size.y) / 2.0))
	var x: float = SIDE
	if side == "right":
		x = vs.x - panel_size.x - SIDE
	elif side == "center":
		x = roundf((vs.x - panel_size.x) / 2.0)
	return Rect2(Vector2(x, y), panel_size)


func toggle() -> void:
	visible = not visible
	Audio.sfx("ui_open", -8.0)
	if not visible:
		closed.emit()


func _process(_delta: float) -> void:
	if not visible:
		return
	var r: Rect2 = place_rect(get_viewport_rect().size)
	position = r.position
	size = r.size
	queue_redraw()
	_hover(get_local_mouse_position())


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	UiDraw.box(self, r)
	UiDraw.title_bar(self, r, title)
	var c: Rect2 = _close_rect()
	UiDraw.text(self, c.position + Vector2(3, 11), "x", UiDraw.DIM)
	_content()


func _close_rect() -> Rect2:
	return Rect2(size.x - CLOSE - 5.0, 5.0, CLOSE, CLOSE)


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed:
		return
	accept_event()
	if mb.button_index == MOUSE_BUTTON_LEFT and _close_rect().has_point(mb.position):
		toggle()
		return
	_click(mb.position, mb.button_index)


func _content() -> void:
	pass


func _click(_at: Vector2, _button: int) -> void:
	pass


func _hover(_at: Vector2) -> void:
	pass


## A small framed button; returns its rect (draw-time helper).
func button(r: Rect2, label: String, enabled: bool = true) -> void:
	UiDraw.box(self, r, Color(0.14, 0.1, 0.08) if enabled else Color(0.08, 0.07, 0.09), UiDraw.FRAME if enabled else UiDraw.LOCKED)
	UiDraw.text(self, r.position + Vector2(0, r.size.y * 0.5 + 4.0), label, UiDraw.GOLD if enabled else UiDraw.LOCKED,
		UiDraw.BODY, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)


func tip(rows: Array, title_col: Color = UiDraw.TEXT) -> void:
	g.ui.tooltip.show_rows(rows, get_global_mouse_position(), title_col)
