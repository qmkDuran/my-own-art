class_name DialogueBox
extends Control
## The message box along the bottom of the screen: types text out, waits for accept (or a click), shows the
## speaker's name tag, and can ask a question with a small choice list beside it.

signal advanced

const BOX_H: int = 46
const MARGIN: int = 4
const CHARS_PER_SEC: float = 60.0
const NAME_TAG_H: int = 13

var _panel: Panel
var _text: Label
var _name_tag: Panel
var _name: Label
var _more: TextureRect
var _typing: bool = false
var _waiting: bool = false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel = UiKit.panel(Rect2(), "paper", "ink")
	add_child(_panel)
	_text = UiKit.label("")
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.position = Vector2(8, 4)
	_text.add_theme_constant_override("line_spacing", 0)
	_panel.add_child(_text)
	_name_tag = UiKit.panel(Rect2(), "ink2", "ink")
	add_child(_name_tag)
	_name = UiKit.label("", "cream")
	_name.position = Vector2(5, -1)
	_name_tag.add_child(_name)
	_more = TextureRect.new()
	_more.texture = UiKit.tex("res://art/ui/cursor.png")
	_more.rotation_degrees = 90
	_panel.add_child(_more)
	_layout()
	get_viewport().size_changed.connect(_layout)
	hide()


func _layout() -> void:
	var view: Vector2 = get_viewport_rect().size
	_panel.position = Vector2(MARGIN, view.y - BOX_H - MARGIN)
	_panel.size = Vector2(view.x - MARGIN * 2, BOX_H)
	_text.size = Vector2(_panel.size.x - 16, BOX_H - 6)
	_more.position = Vector2(_panel.size.x - 6, BOX_H - 9)
	_name_tag.position = _panel.position + Vector2(6, -NAME_TAG_H)


## Shows each line in turn, waiting for the player after each.
func say(lines: PackedStringArray, speaker: String = "") -> void:
	show()
	_set_speaker(speaker)
	for line: String in lines:
		await _show_line(line)
		await _wait_for_advance()
	hide()


## Shows a line without waiting (battle narration keeps it on screen while menus are open).
func show_line_now(line: String) -> void:
	show()
	_set_speaker("")
	_text.text = line
	_text.visible_ratio = 1.0
	_more.hide()


func _set_speaker(speaker: String) -> void:
	_name_tag.visible = speaker != ""
	_name.text = speaker
	_name_tag.size = Vector2(UiKit.text_width(speaker) + 10, NAME_TAG_H)


func _show_line(line: String) -> void:
	_text.text = line
	_more.hide()
	if Game.fast:
		_text.visible_ratio = 1.0
		return
	_typing = true
	_text.visible_characters = 0
	var total: int = line.length()
	var shown: float = 0.0
	while _typing and _text.visible_characters < total:
		shown += get_process_delta_time() * CHARS_PER_SEC
		_text.visible_characters = mini(total, int(shown))
		await get_tree().process_frame
	_typing = false
	_text.visible_ratio = 1.0


func _wait_for_advance() -> void:
	if Game.fast:
		await get_tree().process_frame
		return
	_more.show()
	_waiting = true
	await advanced
	_waiting = false
	Audio.sfx("move")


## Asks a question; returns the chosen option index (-1 if cancelled).
func ask(question: String, choices: PackedStringArray, speaker: String = "") -> int:
	show()
	_set_speaker(speaker)
	await _show_line(question)
	var menu := MenuList.new()
	var box := UiKit.panel(Rect2(), "paper", "ink")
	add_child(box)
	box.add_child(menu)
	menu.setup(choices, 1, 56)
	menu.position = Vector2(6, 5)
	box.size = menu.size + Vector2(12, 8)
	box.position = _panel.position + Vector2(_panel.size.x - box.size.x, -box.size.y - 2)
	var choice: int = 0 if Game.fast else await menu.pick()
	box.queue_free()
	hide()
	return choice


func _unhandled_input(ev: InputEvent) -> void:
	if not visible:
		return
	var pressed: bool = ev.is_action_pressed("accept") or UiKit.is_click(ev)
	if not pressed:
		return
	if _typing:
		_typing = false
		get_viewport().set_input_as_handled()
	elif _waiting:
		advanced.emit()
		get_viewport().set_input_as_handled()
