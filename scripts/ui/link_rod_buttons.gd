class_name LinkRodButtons
extends RefCounted
## The Link Rod screen's buttons, built on the Ember Tree's warm buttons: full-width row
## buttons for chips and slots (a cyan edge marks the selected one), and small hack buttons.

const ROW_HEIGHT := 24
const SMALL_PADDING := 6


## A left-aligned, full-width button for a chip or a slot.
static func make_row_button() -> Button:
	var button := EmberTreeWidgets.make_button("")
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size.y = ROW_HEIGHT
	button.clip_text = true
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	return button


## A small button for a hack or an action on the chip card.
static func make_small_button(text: String) -> Button:
	var button := EmberTreeWidgets.make_button(text)
	for state in ["normal", "hover", "pressed", "disabled"]:
		var style := button.get_theme_stylebox(state).duplicate() as StyleBoxFlat
		style.content_margin_left = SMALL_PADDING
		style.content_margin_right = SMALL_PADDING
		style.content_margin_top = 1
		style.content_margin_bottom = 1
		button.add_theme_stylebox_override(state, style)
	return button


## Gives the button a cyan edge while it is the selected chip, the usual warm one otherwise.
static func mark_selected(button: Button, is_selected: bool) -> void:
	var edge := LinkRodPalette.SELECTED_EDGE if is_selected else Color(EmberTreePalette.ORANGE, 0.5)
	var style := button.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
	style.border_color = edge
	style.bg_color = EmberTreePalette.DEEP if is_selected else EmberTreePalette.EMBER_DARK
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("disabled", style if is_selected else button.get_theme_stylebox("disabled"))
