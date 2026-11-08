class_name TrainerCustomizer
extends Control
## The trainer customisation screen: a big preview of the trainer, left/right pickers
## for each style and colour, and Randomize and Done buttons.
##
## Parked for now: nothing in the game opens it yet. Done emits `look_chosen` with a copy
## of the chosen look, for the new-game flow to hand to the Trainer.

signal look_chosen(look: TrainerLook)

const COLOR_BACKGROUND := Color(0.035, 0.039, 0.078)
const COLOR_PANEL := Color(0.09, 0.125, 0.22)
const COLOR_COAL := Color(0.063, 0.078, 0.122)
const COLOR_CREAM := Color(0.906, 0.835, 0.702)
const COLOR_GREY := Color(0.506, 0.592, 0.588)
const COLOR_DIM := Color(0.224, 0.29, 0.314)
const COLOR_ORANGE := Color(0.871, 0.62, 0.255)
const FONT_SIZE := 8

## The look being edited.
var look := TrainerLook.new()
## The label showing the current choice, by TrainerLook property name.
var _value_labels: Dictionary = {}

@onready var _background: ColorRect = %Background
@onready var _preview_frame: Panel = %PreviewFrame
@onready var _preview: LayeredTrainerSprite = %Preview
@onready var _pickers: VBoxContainer = %Pickers
@onready var _randomize_button: Button = %RandomizeButton
@onready var _done_button: Button = %DoneButton


func _ready() -> void:
	theme = _build_theme()
	_background.color = COLOR_BACKGROUND
	_preview_frame.add_theme_stylebox_override("panel", _box(COLOR_PANEL, COLOR_DIM))
	for picker: Dictionary in _picker_definitions():
		_add_picker_row(picker)
	_randomize_button.pressed.connect(_on_randomize_pressed)
	_done_button.pressed.connect(_on_done_pressed)
	_show_look()
	_done_button.grab_focus()


## Each picker: its label, the TrainerLook property it changes, and the choices in order.
func _picker_definitions() -> Array[Dictionary]:
	return [
		{"label": "Hair", "property": "hair_style", "options": range(TrainerLook.HAIR_STYLE_COUNT)},
		{"label": "Hair colour", "property": "hair_ramp", "options": TrainerPresets.ramp_names(TrainerPresets.HAIR)},
		{"label": "Top", "property": "top_style", "options": range(TrainerLook.TOP_STYLE_COUNT)},
		{"label": "Top colour", "property": "top_ramp", "options": TrainerPresets.ramp_names(TrainerPresets.OUTFIT)},
		{"label": "Bottoms", "property": "bottom_ramp", "options": TrainerPresets.ramp_names(TrainerPresets.OUTFIT)},
		{"label": "Shoes", "property": "shoes_ramp", "options": TrainerPresets.ramp_names(TrainerPresets.OUTFIT)},
		{"label": "Skin", "property": "skin_ramp", "options": TrainerPresets.ramp_names(TrainerPresets.SKIN)},
	]


func _add_picker_row(picker: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	var name_label := _label(picker["label"], COLOR_GREY, 52)
	var value_label := _label("", COLOR_CREAM, 64)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(name_label)
	row.add_child(_arrow_button("<", picker, -1))
	row.add_child(value_label)
	row.add_child(_arrow_button(">", picker, 1))
	_pickers.add_child(row)
	_value_labels[picker["property"]] = value_label


func _arrow_button(text: String, picker: Dictionary, step: int) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(13, 13)
	button.pressed.connect(_step_choice.bind(picker, step))
	return button


func _label(text: String, color: Color, width: float) -> Label:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size.x = width
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", color)
	return label


## Moves one picker to its previous (-1) or next (+1) choice, wrapping around.
func _step_choice(picker: Dictionary, step: int) -> void:
	var options: Array = picker["options"]
	var property: String = picker["property"]
	var index := options.find(look.get(property))
	look.set(property, options[wrapi(index + step, 0, options.size())])
	_show_look()


func _show_look() -> void:
	_preview.apply_look(look)
	for property: String in _value_labels:
		(_value_labels[property] as Label).text = _choice_text(look.get(property))


## Styles read "Style 1"; ramp names such as "sunny_blonde" read "Sunny Blonde".
func _choice_text(choice: Variant) -> String:
	if choice is int:
		return "Style %d" % (choice + 1)
	return String(choice).capitalize()


func _on_randomize_pressed() -> void:
	look = TrainerLook.random()
	_show_look()


func _on_done_pressed() -> void:
	look_chosen.emit(look.duplicate())


func _build_theme() -> Theme:
	var ui_theme := Theme.new()
	ui_theme.default_font_size = FONT_SIZE
	ui_theme.set_color("font_color", "Label", COLOR_CREAM)
	ui_theme.set_color("font_color", "Button", COLOR_CREAM)
	ui_theme.set_color("font_hover_color", "Button", COLOR_ORANGE)
	ui_theme.set_color("font_focus_color", "Button", COLOR_ORANGE)
	ui_theme.set_color("font_pressed_color", "Button", COLOR_ORANGE)
	ui_theme.set_stylebox("normal", "Button", _box(COLOR_COAL, COLOR_DIM))
	ui_theme.set_stylebox("hover", "Button", _box(COLOR_COAL, COLOR_ORANGE))
	ui_theme.set_stylebox("pressed", "Button", _box(COLOR_DIM, COLOR_ORANGE))
	ui_theme.set_stylebox("focus", "Button", _box(Color.TRANSPARENT, COLOR_ORANGE))
	return ui_theme


func _box(fill: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(2)
	box.content_margin_left = 3
	box.content_margin_right = 3
	box.content_margin_top = 0
	box.content_margin_bottom = 0
	return box
