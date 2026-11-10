class_name GamePanel
extends Control
## Base for the inventory, skills and stars panels: a framed window that takes the mouse while open,
## tracks the hovered element for tooltips, and redraws every frame.

var m: Michael
var hover: Vector2 = Vector2(-1, -1)


func setup(michael: Michael, area: Rect2) -> void:
	m = michael
	position = area.position
	size = area.size
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP


func toggle() -> void:
	visible = not visible


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		hover = (event as InputEventMouseMotion).position
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed \
			and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		clicked((event as InputEventMouseButton).position)
		accept_event()


func clicked(_at: Vector2) -> void:
	pass


func frame(title: String) -> void:
	UiDraw.box(self, Rect2(Vector2.ZERO, size))
	UiDraw.text(self, Vector2(0, 18), title, UiDraw.GOLD, UiDraw.BODY, HORIZONTAL_ALIGNMENT_CENTER, size.x)
