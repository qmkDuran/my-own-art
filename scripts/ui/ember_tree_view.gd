class_name EmberTreeView
extends Control
## The window onto the Ember Tree: zoom with the wheel, drag to move, point at and click nodes.
##
## Owns the EmberTreeCanvas and moves it smoothly toward the wanted zoom and position.
## Says what the player points at (a node, a branch name or nothing) and clicks through
## signals; the screen decides what happens.

## Pointing moved onto a node, or onto nothing when `id` is "".
signal node_hovered(id: String)
## Pointing moved onto a branch's name.
signal branch_hovered(branch: String)
signal node_clicked(id: String)
signal node_right_clicked(id: String)
## The wanted zoom changed (the wheel turned); 1.0 = tree pixels at full size.
signal zoom_changed(zoom: float)

const MIN_ZOOM := 0.4
const MAX_ZOOM := 1.6
const ZOOM_STEP := 1.15
## Mouse travel (pixels) before a press counts as a drag instead of a click.
const DRAG_THRESHOLD := 4.0
## How quickly zoom and pan ease toward their targets (higher = snappier).
const EASE_RATE := 14.0

## Where Emberoo sits and how zoomed in the tree is when the screen opens.
var home_centre: Vector2 = Vector2.ZERO
var home_zoom: float = 1.0

var _canvas: EmberTreeCanvas
var _target_zoom: float = 1.0
var _target_offset: Vector2 = Vector2.ZERO
var _press_position: Vector2 = Vector2.ZERO
var _is_pressing: bool = false
var _is_dragging: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	_canvas = EmberTreeCanvas.new()
	add_child(_canvas)
	snap_home()


## Puts the tree back to its starting zoom and position, without easing, and forgets
## what was pointed at.
func snap_home() -> void:
	_target_zoom = home_zoom
	_target_offset = home_centre
	if _canvas != null:
		_canvas.scale = Vector2.ONE * home_zoom
		_canvas.position = home_centre
		_canvas.hovered_id = ""
		_canvas.hovered_branch = ""


func _process(delta: float) -> void:
	var ease_amount := 1.0 - exp(-EASE_RATE * delta)
	_canvas.scale = Vector2.ONE * lerpf(_canvas.scale.x, _target_zoom, ease_amount)
	_canvas.position = _canvas.position.lerp(_target_offset, ease_amount)


## The very dark backdrop, behind the tree.
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), EmberTreePalette.BACKGROUND)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_on_mouse_button(event)
	elif event is InputEventMouseMotion:
		_on_mouse_motion(event)


func _on_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
		_zoom_around(event.position, ZOOM_STEP)
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
		_zoom_around(event.position, 1.0 / ZOOM_STEP)
	elif event.pressed:
		_is_pressing = true
		_is_dragging = false
		_press_position = event.position
	else:
		var was_click := _is_pressing and not _is_dragging
		_is_pressing = false
		_is_dragging = false
		if was_click:
			_report_click(event.button_index, _node_under(event.position))


func _report_click(button: MouseButton, id: String) -> void:
	if id == "":
		return
	if button == MOUSE_BUTTON_LEFT:
		node_clicked.emit(id)
	elif button == MOUSE_BUTTON_RIGHT:
		node_right_clicked.emit(id)


func _on_mouse_motion(event: InputEventMouseMotion) -> void:
	if _is_pressing and event.position.distance_to(_press_position) > DRAG_THRESHOLD:
		_is_dragging = true
	if _is_dragging:
		_target_offset += event.relative
		_canvas.position += event.relative
		return
	_update_hover(event.position)


## Tells the canvas and listeners what is under the pointer, when that changes.
## Nodes win over branch names, though the two never overlap.
func _update_hover(view_point: Vector2) -> void:
	var tree_point := _canvas.transform.affine_inverse() * view_point
	var id := _canvas.node_at(tree_point)
	var branch := _canvas.branch_at(tree_point) if id == "" else ""
	if id == _canvas.hovered_id and branch == _canvas.hovered_branch:
		return
	_canvas.hovered_id = id
	_canvas.hovered_branch = branch
	var points_at_something := id != "" or branch != ""
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if points_at_something else Control.CURSOR_ARROW
	if branch != "":
		branch_hovered.emit(branch)
	else:
		node_hovered.emit(id)


## Zooms in or out while keeping the point under the cursor where it is.
func _zoom_around(screen_point: Vector2, factor: float) -> void:
	var new_zoom := clampf(_target_zoom * factor, MIN_ZOOM, MAX_ZOOM)
	var applied := new_zoom / _target_zoom
	_target_offset = screen_point - (screen_point - _target_offset) * applied
	_target_zoom = new_zoom
	zoom_changed.emit(new_zoom)


func _node_under(view_point: Vector2) -> String:
	return _canvas.node_at(_canvas.transform.affine_inverse() * view_point)
