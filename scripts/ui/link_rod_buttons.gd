class_name LinkRodButtons
extends RefCounted
## The Link Rod screen's buttons, built on the Ember Tree's buttons: full-width row buttons
## for chips and slots (the selected one is lit by the ember), and small hack buttons.

const ROW_HEIGHT := 24
## Room beside a small button's text, its frame (PixelPanelStyle, 4 canvas pixels) included.
const SMALL_PADDING := 9
## Room above and below it: less than the frame, since Monogram's line already leaves room
## above the letters.
const SMALL_PADDING_TOP_BOTTOM := 3


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
	for state: String in ["normal", "hover", "pressed", "disabled"]:
		var style := button.get_theme_stylebox(state).duplicate() as PixelPanelStyle
		style.content_margin_left = SMALL_PADDING
		style.content_margin_right = SMALL_PADDING
		style.content_margin_top = SMALL_PADDING_TOP_BOTTOM
		style.content_margin_bottom = SMALL_PADDING_TOP_BOTTOM
		button.add_theme_stylebox_override(state, style)
	return button


## Lights the button with the ember while it is the selected chip; the usual stone otherwise.
static func mark_selected(button: Button, is_selected: bool) -> void:
	var style := button.get_theme_stylebox("normal").duplicate() as PixelPanelStyle
	style.border_color = LinkRodPalette.SELECTED_EDGE if is_selected else EmberTreePalette.BUTTON_EDGE
	style.border_dark_color = LinkRodPalette.SELECTED_EDGE_DARK if is_selected else EmberTreePalette.BUTTON_EDGE_DARK
	style.bg_color = LinkRodPalette.SELECTED_FILL if is_selected else EmberTreePalette.BUTTON_FILL
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("disabled", style if is_selected else button.get_theme_stylebox("disabled"))
