class_name LevelUpPanel
extends CanvasLayer
## The level-up choice: the game pauses and three cards offer new or stronger lantern magic (a combo card glows
## gold). Pick with the mouse or the 1, 2 and 3 keys.

signal chosen(offer: Dictionary)

const TITLE: String = "Your lantern burns brighter!"
const TITLE_SIZE: int = 30
const NAME_SIZE: int = 22
const TEXT_SIZE: int = 16
const CARD_SIZE: Vector2 = Vector2(290, 150)
const COMBO_EDGE: Color = Color(1.0, 0.85, 0.3)
const KEYS: Array[Key] = [KEY_1, KEY_2, KEY_3]

var cards: Array[Button] = []
var root: Control
var _offers: Array[Dictionary] = []
var _row: HBoxContainer


func _ready() -> void:
	name = "LevelUpPanel"
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 2
	root = CenterContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiStyle.panel_box())
	root.add_child(panel)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(column)
	var title: Label = UiStyle.label(TITLE, TITLE_SIZE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	_row = HBoxContainer.new()
	_row.add_theme_constant_override("separation", UiStyle.PADDING)
	column.add_child(_row)
	visible = false


func show_offers(offers: Array[Dictionary]) -> void:
	_offers = offers
	for card: Button in cards:
		card.queue_free()
	cards.clear()
	for index: int in offers.size():
		cards.append(_card(index, offers[index]))
	visible = true
	get_tree().paused = true


func pick(index: int) -> void:
	if not visible or index >= _offers.size():
		return
	visible = false
	get_tree().paused = false
	chosen.emit(_offers[index])


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not event is InputEventKey or not event.is_pressed():
		return
	var index: int = KEYS.find((event as InputEventKey).physical_keycode)
	if index >= 0:
		pick(index)


func _card(index: int, offer: Dictionary) -> Button:
	var card := Button.new()
	card.custom_minimum_size = CARD_SIZE
	var box: StyleBoxFlat = UiStyle.panel_box()
	if offer["kind"] == "combo":
		box.border_color = COMBO_EDGE
	card.add_theme_stylebox_override("normal", box)
	card.add_theme_stylebox_override("hover", box)
	card.pressed.connect(pick.bind(index))
	var text := VBoxContainer.new()
	text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_KEEP_SIZE, UiStyle.PADDING)
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var heading: Label = UiStyle.label("%d. %s" % [index + 1, offer["name"]], NAME_SIZE)
	var tier: String = "New!" if int(offer["level"]) == 1 else "Level %d" % offer["level"]
	var level_line: Label = UiStyle.label("Combo!" if offer["kind"] == "combo" else tier, TEXT_SIZE)
	level_line.add_theme_color_override("font_color", COMBO_EDGE)
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var body: Label = UiStyle.label(offer["text"], TEXT_SIZE)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_child(heading)
	text.add_child(level_line)
	text.add_child(body)
	card.add_child(text)
	_row.add_child(card)
	return card
