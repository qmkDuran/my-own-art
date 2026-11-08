class_name EmberTreeWidgets
extends RefCounted
## Builds the Ember Tree screen's standard pieces (cards, buttons, badges) in its warm,
## dark style, so the screen and its side panel look the same and say it only once.
## Every piece ignores the mouse unless it is meant to be clicked.

const CARD_PADDING := 12
const CARD_CORNER := 4


## A see-through dark card with a warm edge.
static func make_card() -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", card_style(EmberTreePalette.PANEL, EmberTreePalette.PANEL_EDGE))
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return card


## A box with a thin border, rounded corners, room inside and a soft shadow.
static func card_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(CARD_CORNER)
	style.set_content_margin_all(CARD_PADDING)
	style.shadow_color = Color(EmberTreePalette.BACKGROUND, 0.35)
	style.shadow_size = 6
	return style


static func make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	# No keyboard focus: Tab toggles the tree and must not move focus to the button instead.
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 11)
	button.add_theme_color_override("font_color", EmberTreePalette.CREAM)
	button.add_theme_color_override("font_hover_color", EmberTreePalette.GOLD)
	button.add_theme_color_override("font_pressed_color", EmberTreePalette.GOLD)
	button.add_theme_color_override("font_disabled_color", EmberTreePalette.DIM)
	button.add_theme_stylebox_override("normal", _button_style(EmberTreePalette.EMBER_DARK, Color(EmberTreePalette.ORANGE, 0.5)))
	button.add_theme_stylebox_override("hover", _button_style(EmberTreePalette.DEEP, EmberTreePalette.GOLD))
	button.add_theme_stylebox_override("pressed", _button_style(EmberTreePalette.DEEP, EmberTreePalette.GOLD))
	button.add_theme_stylebox_override("disabled", _button_style(EmberTreePalette.COAL, Color(EmberTreePalette.DIM, 0.6)))
	return button


## A small orange badge with a short grey note beside it, e.g. "COMING SOON".
static func make_badge_row(badge_text: String, note_text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var badge := PanelContainer.new()
	var badge_style := card_style(EmberTreePalette.EMBER_DARK, Color(EmberTreePalette.ORANGE, 0.7))
	badge_style.shadow_size = 0
	badge_style.set_corner_radius_all(3)
	badge_style.content_margin_left = 5
	badge_style.content_margin_right = 5
	badge_style.content_margin_top = 1
	badge_style.content_margin_bottom = 1
	badge.add_theme_stylebox_override("panel", badge_style)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(UiLabel.make(8, EmberTreePalette.ORANGE, badge_text))
	row.add_child(badge)
	var note := UiLabel.make(9, EmberTreePalette.GREY, note_text)
	note.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(note)
	return row


static func _button_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := card_style(background, border)
	style.shadow_size = 0
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style
