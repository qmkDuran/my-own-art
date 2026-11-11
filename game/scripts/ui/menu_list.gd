class_name MenuList
extends Control
## A list of choices in one or more columns with a pointer: arrows move, accept picks, cancel backs out, and
## the mouse hovers and clicks. `await pick()` returns the chosen index, or -1 when cancelled.

signal resolved(index: int)
signal index_changed(index: int)

const ROW_H: int = 13
const POINTER_W: int = 8

var options: PackedStringArray = []
var enabled: Array[bool] = []
var columns: int = 1
var column_w: int = 80
var index: int = 0
var cancellable: bool = true
## Rows shown at once (0 = all); longer lists scroll to keep the pointer in view.
var max_rows: int = 0
var _top: int = 0
var _labels: Array[Label] = []
var _pointer: TextureRect
var _active: bool = false
var _colour: String = "ink"


func setup(items: PackedStringArray, cols: int = 1, col_w: int = 80, colour: String = "ink") -> MenuList:
	options = items
	_colour = colour
	columns = cols
	column_w = col_w
	enabled.clear()
	for i: int in items.size():
		enabled.append(true)
	for l: Label in _labels:
		l.queue_free()
	_labels.clear()
	for i: int in items.size():
		_labels.append(_make_label(i, colour))
	if _pointer == null:
		_pointer = TextureRect.new()
		_pointer.texture = UiKit.tex("res://art/ui/cursor.png")
		add_child(_pointer)
	custom_minimum_size = Vector2(cols * col_w, visible_rows() * ROW_H)
	size = custom_minimum_size
	_refresh()
	return self


func _make_label(i: int, colour: String) -> Label:
	var l := UiKit.label(options[i], colour)
	l.position = Vector2(POINTER_W + (i % columns) * column_w, (i / columns) * ROW_H - 1)
	l.mouse_filter = Control.MOUSE_FILTER_STOP
	l.mouse_entered.connect(func() -> void: _hover(i))
	l.gui_input.connect(func(ev: InputEvent) -> void: _click(ev, i))
	add_child(l)
	return l


func rows() -> int:
	return int(ceil(float(options.size()) / columns))


func visible_rows() -> int:
	return rows() if max_rows <= 0 else mini(rows(), max_rows)


func _scroll() -> void:
	var row: int = index / columns
	if row < _top:
		_top = row
	elif row >= _top + visible_rows():
		_top = row - visible_rows() + 1
	for i: int in _labels.size():
		var r: int = i / columns - _top
		_labels[i].visible = r >= 0 and r < visible_rows()
		_labels[i].position.y = r * ROW_H - 1


func set_enabled(i: int, on: bool) -> void:
	enabled[i] = on
	_labels[i].add_theme_color_override("font_color", UiKit.c(_colour if on else "mist"))


func pick() -> int:
	_active = true
	_refresh()
	var result: int = await resolved
	_active = false
	return result


func _hover(i: int) -> void:
	if _active and index != i:
		index = i
		_refresh()
		index_changed.emit(i)


func _click(ev: InputEvent, i: int) -> void:
	if _active and UiKit.is_click(ev):
		index = i
		_choose()
		accept_event()


func _unhandled_input(ev: InputEvent) -> void:
	if not _active or not is_visible_in_tree():
		return
	if ev.is_action_pressed("accept"):
		_choose()
	elif ev.is_action_pressed("cancel") and cancellable:
		_finish(-1)
	else:
		_move(ev)
		return
	get_viewport().set_input_as_handled()


func _move(ev: InputEvent) -> void:
	var step: int = 0
	if ev.is_action_pressed("move_down"):
		step = columns
	elif ev.is_action_pressed("move_up"):
		step = -columns
	elif ev.is_action_pressed("move_right") and columns > 1:
		step = 1
	elif ev.is_action_pressed("move_left") and columns > 1:
		step = -1
	if step != 0:
		index = posmod(index + step, options.size())
		Audio.sfx("move")
		_refresh()
		index_changed.emit(index)
		get_viewport().set_input_as_handled()


func _choose() -> void:
	if enabled[index]:
		Audio.sfx("select")
		_finish(index)
	else:
		Audio.sfx("bump")


func _finish(i: int) -> void:
	_active = false
	if i < 0:
		Audio.sfx("cancel")
	resolved.emit(i)


func _refresh() -> void:
	if _pointer == null or options.is_empty():
		return
	index = clampi(index, 0, options.size() - 1)
	_scroll()
	_pointer.position = Vector2((index % columns) * column_w, (index / columns - _top) * ROW_H + 2)
	_pointer.visible = _active or not cancellable
