class_name BattleLog
extends Panel
## The battle's message panel: types each line, holds it briefly (accept skips ahead), then moves on.

const CHARS_PER_SEC: float = 70.0
const HOLD: float = 0.9

var _text: Label
var _skip: bool = false


func setup(rect: Rect2) -> BattleLog:
	position = rect.position
	size = rect.size
	add_theme_stylebox_override("panel", UiKit.panel_style())
	_text = UiKit.label("")
	_text.position = Vector2(6, 2)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(rect.size.x - 12, 0)
	_text.size = rect.size - Vector2(12, 4)
	add_child(_text)
	return self


func say(line: String) -> void:
	_text.text = line
	if Game.fast:
		_text.visible_ratio = 1.0
		await get_tree().process_frame
		return
	_skip = false
	_text.visible_characters = 0
	var shown: float = 0.0
	while not _skip and _text.visible_characters < line.length():
		shown += get_process_delta_time() * CHARS_PER_SEC * Settings.text_mult()
		_text.visible_characters = int(shown)
		await get_tree().process_frame
	_text.visible_ratio = 1.0
	_skip = false
	var held: float = 0.0
	while not _skip and held < HOLD:
		held += get_process_delta_time()
		await get_tree().process_frame


func show_now(line: String) -> void:
	_text.text = line
	_text.visible_ratio = 1.0


func text() -> String:
	return _text.text


func _unhandled_input(ev: InputEvent) -> void:
	if is_visible_in_tree() and (ev.is_action_pressed("accept") or UiKit.is_click(ev)):
		_skip = true
