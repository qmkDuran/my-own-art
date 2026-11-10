class_name DialogueBox
extends CanvasLayer
## Bottom-of-screen dialogue: 128 px portrait, speaker name, typed text, and choice lists.
## Driven by the Dialogue autoload through the awaitable present_line / present_choices.

signal advanced
signal chosen(index: int)

const CHARS_PER_SECOND := 48.0
const BLIP_EVERY := 3
const INPUT_GRACE := 0.12
const BOX_RECT := Rect2(16, 388, 928, 144)
const PORTRAIT_SIZE := 128

var _panel: Panel
var _portrait: TextureRect
var _name: Label
var _text: Label
var _more: Label
var _choices_panel: PanelContainer
var _choices_list: VBoxContainer
var _choice_labels: Array[Label] = []
var _choice_index := 0
var _typing := false
var _waiting := false
var _choosing := false
var _shown_time := 0.0
var _typed := 0.0
var _auto_continue := false


func _ready() -> void:
	layer = 20
	_build()
	close()


func is_open() -> bool:
	return _panel.visible


func is_choosing() -> bool:
	return _choosing


func choice_count() -> int:
	return _choice_labels.size()


## auto_continue: return as soon as the text is typed (an interrupted line stays on screen).
func present_line(speaker_name: String, portrait: Texture2D, text: String, auto_continue: bool = false) -> void:
	_panel.visible = true
	_portrait.texture = portrait
	_portrait.visible = portrait != null
	var left := 24.0 + (PORTRAIT_SIZE + 16.0 if portrait else 0.0)
	_name.position.x = left
	_text.position.x = left
	_text.size.x = BOX_RECT.size.x - left - 16.0
	_name.text = speaker_name
	_name.visible = not speaker_name.is_empty()
	_text.text = text
	_text.visible_characters = 0
	_typed = 0.0
	_typing = true
	_waiting = true
	_shown_time = 0.0
	_auto_continue = auto_continue
	await advanced


## Shows the choices under the current line and returns the chosen index.
func present_choices(texts: Array[String]) -> int:
	for child: Node in _choices_list.get_children():
		_choices_list.remove_child(child)
		child.queue_free()
	_choice_labels.clear()
	for text: String in texts:
		var label := UiStyle.label(text, 16)
		_choices_list.add_child(label)
		_choice_labels.append(label)
	_choice_index = 0
	_highlight()
	_text.visible_characters = -1
	_typing = false
	_choices_panel.visible = true
	_choices_panel.reset_size()
	var size := _choices_panel.get_combined_minimum_size()
	_choices_panel.position = Vector2(BOX_RECT.end.x - size.x, BOX_RECT.position.y - size.y - 6)
	_choosing = true
	_shown_time = 0.0
	var index: int = await chosen
	_choices_panel.visible = false
	return index


## Skin palette swap for portraits that need it (Mom matches the hero's skin tone).
func set_portrait_material(portrait_material: Material) -> void:
	_portrait.material = portrait_material


func close() -> void:
	_panel.visible = false
	_choices_panel.visible = false
	_typing = false
	_waiting = false
	_choosing = false


func _process(delta: float) -> void:
	_shown_time += delta
	if _typing:
		_type(delta)
	_more.visible = _waiting and not _typing and not _choosing and fmod(_shown_time, 0.8) < 0.5
	if _shown_time < INPUT_GRACE:
		return
	if _choosing:
		_handle_choice_input()
	elif _waiting and _advance_pressed():
		if _typing:
			_text.visible_characters = -1
			_typing = false
			if _auto_continue:
				_auto_continue = false
				_waiting = false
				advanced.emit()
		else:
			_waiting = false
			advanced.emit()


func _type(delta: float) -> void:
	var before := int(_typed)
	_typed += delta * CHARS_PER_SECOND
	var shown := int(_typed)
	_text.visible_characters = shown
	if shown / BLIP_EVERY != before / BLIP_EVERY:
		AudioManager.play_sfx("typewriter_tick", -18.0, 0.1)
	if shown >= _text.get_total_character_count():
		_text.visible_characters = -1
		_typing = false
		if _auto_continue:
			_auto_continue = false
			_waiting = false
			advanced.emit.call_deferred()


func _handle_choice_input() -> void:
	if Input.is_action_just_pressed("move_down") or Input.is_action_just_pressed("ui_down"):
		_choice_index = (_choice_index + 1) % _choice_labels.size()
		_highlight()
	elif Input.is_action_just_pressed("move_up") or Input.is_action_just_pressed("ui_up"):
		_choice_index = (_choice_index - 1 + _choice_labels.size()) % _choice_labels.size()
		_highlight()
	elif _advance_pressed():
		_choosing = false
		AudioManager.play_sfx("ui_confirm", -6.0)
		chosen.emit(_choice_index)


func _highlight() -> void:
	for i in _choice_labels.size():
		var label := _choice_labels[i]
		var raw := label.text.trim_prefix("> ").trim_prefix("  ")
		label.text = ("> " if i == _choice_index else "  ") + raw
		label.add_theme_color_override("font_color", UiStyle.ACCENT if i == _choice_index else UiStyle.INK)


func _advance_pressed() -> bool:
	return Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("ui_accept")


func _build() -> void:
	_panel = Panel.new()
	_panel.position = BOX_RECT.position
	_panel.size = BOX_RECT.size
	_panel.add_theme_stylebox_override("panel", UiStyle.panel())
	add_child(_panel)
	_portrait = TextureRect.new()
	_portrait.position = Vector2(8, 8)
	_portrait.size = Vector2(PORTRAIT_SIZE, PORTRAIT_SIZE)
	_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_panel.add_child(_portrait)
	_name = UiStyle.label("", 16, UiStyle.ACCENT)
	_name.position = Vector2(152, 8)
	_panel.add_child(_name)
	_text = UiStyle.label("", 17)
	_text.position = Vector2(152, 34)
	_text.size = Vector2(760, 100)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel.add_child(_text)
	_more = UiStyle.label("v", 14, UiStyle.ACCENT)
	_more.position = BOX_RECT.size - Vector2(22, 24)
	_panel.add_child(_more)
	_choices_panel = PanelContainer.new()
	_choices_panel.add_theme_stylebox_override("panel", UiStyle.panel())
	_choices_list = VBoxContainer.new()
	_choices_panel.add_child(_choices_list)
	add_child(_choices_panel)
