class_name DialogueBox
extends CanvasLayer
## The conversation card at the bottom of the screen (part of the GameLayer): the speaker's
## portrait, name and one line at a time, typed out quickly. A click, F, E, Space or Enter
## shows the whole line, then the next one; after the last it closes. In the HUD's card style
## (HudCard: Monogram, the Ember Tree's frame).
##
## The game pauses while it's open (this layer keeps running), and stays paused a moment
## after the last click, so the key that closed it doesn't also throw a tonic or dodge.
## Npc finds it through the GROUP: `DialogueBox.find(self).play(...)`, then awaits `finished`.

signal finished

const GROUP := "dialogue_box"
## The keys that move it on, besides a left click.
const ADVANCE_ACTIONS: Array[String] = ["trainer_aid", "skill_3", "dodge", "ui_accept"]
## Card pixels (twice the game's) for the line's width.
const LINE_WIDTH := 500.0
## The portrait is the 16×26 sprite at 3 card pixels per sprite pixel (1.5 game pixels).
const PORTRAIT_SCALE := 3.0
const PORTRAIT_GAP := 10
## Gap between the speaker's name and the line, in card pixels.
const NAME_GAP := 2
## Gap between the card's bottom and the screen's bottom, in game pixels (clears the HUD's bottom cluster).
const BOTTOM_MARGIN := 44.0
const CHARACTERS_PER_SECOND := 70.0
const FADE_SECONDS := 0.15
## Real seconds the game stays paused after the last line.
const RELEASE_SECONDS := 0.12
const NEXT_HINT := "click"
const LAST_HINT := "click to close"

var is_open: bool = false

var _card: PanelContainer
var _portrait: TextureRect
var _name: Label
var _line: Label
var _hint: Label
var _lines: PackedStringArray = []
var _index: int = 0
var _typing: Tween
var _paused_by_me: bool = false


static func find(asker: Node) -> DialogueBox:
	return asker.get_tree().get_first_node_in_group(GROUP) as DialogueBox


func _ready() -> void:
	add_to_group(GROUP)
	layer = 3
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_card()


func _exit_tree() -> void:
	if _paused_by_me:
		get_tree().paused = false


## Shows `lines` said by `speaker` (with `portrait`, a 16×26 texture, if given). Await `finished`.
func play(speaker: String, lines: PackedStringArray, portrait: Texture2D = null) -> void:
	if is_open or lines.is_empty():
		finished.emit.call_deferred()
		return
	is_open = true
	_lines = lines
	_index = 0
	_name.text = speaker
	_portrait.texture = portrait
	_portrait.visible = portrait != null
	_paused_by_me = not get_tree().paused
	get_tree().paused = true
	_show_line()
	_card.modulate.a = 0.0
	_card.visible = true
	create_tween().tween_property(_card, "modulate:a", 1.0, FADE_SECONDS)


func _input(event: InputEvent) -> void:
	if not is_open or not _is_advance(event):
		return
	get_viewport().set_input_as_handled()
	if _typing != null and _typing.is_running():
		_typing.kill()
		_line.visible_ratio = 1.0
		return
	_index += 1
	if _index < _lines.size():
		_show_line()
	else:
		_close()


func _is_advance(event: InputEvent) -> bool:
	if event.is_echo() or not event.is_pressed():
		return false
	var mouse := event as InputEventMouseButton
	if mouse != null:
		return mouse.button_index == MOUSE_BUTTON_LEFT
	for action in ADVANCE_ACTIONS:
		if event.is_action_pressed(action):
			return true
	return false


func _show_line() -> void:
	_line.text = _lines[_index]
	_line.visible_ratio = 0.0
	_hint.text = LAST_HINT if _index == _lines.size() - 1 else NEXT_HINT
	_place_card()
	_typing = create_tween()
	_typing.tween_property(_line, "visible_ratio", 1.0, _line.text.length() / CHARACTERS_PER_SECOND)


func _close() -> void:
	is_open = false
	var fade := create_tween()
	fade.tween_property(_card, "modulate:a", 0.0, FADE_SECONDS)
	fade.tween_callback(_card.hide)
	await Wait.seconds(self, RELEASE_SECONDS, true)
	if _paused_by_me:
		_paused_by_me = false
		get_tree().paused = false
	finished.emit()


func _place_card() -> void:
	_card.reset_size()
	var screen := _card.get_viewport_rect().size
	var on_screen := HudCard.size_on_screen(_card)
	_card.position = Vector2(roundf((screen.x - on_screen.x) / 2.0), roundf(screen.y - BOTTOM_MARGIN - on_screen.y))


func _build_card() -> void:
	_card = HudCard.make()
	_card.visible = false
	add_child(_card)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", PORTRAIT_GAP)
	_card.add_child(row)
	_portrait = TextureRect.new()
	_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.custom_minimum_size = Vector2(16, 26) * PORTRAIT_SCALE
	_portrait.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_portrait)
	var words := VBoxContainer.new()
	words.add_theme_constant_override("separation", NAME_GAP)
	words.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(words)
	_name = UiLabel.make(EmberTreeFonts.TEXT_SIZE, EmberTreePalette.ORANGE)
	words.add_child(_name)
	_line = UiLabel.make(EmberTreeFonts.TEXT_SIZE, EmberTreePalette.CREAM)
	_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Lay out the whole line before typing it, so the card has its final size from the first
	# letter (and words never jump to the next row halfway through).
	_line.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	_line.custom_minimum_size = Vector2(LINE_WIDTH, 0)
	words.add_child(_line)
	_hint = UiLabel.make(EmberTreeFonts.TEXT_SIZE, EmberTreePalette.GREY)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	words.add_child(_hint)
