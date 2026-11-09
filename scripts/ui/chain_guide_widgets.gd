class_name ChainGuideWidgets
extends RefCounted
## Builds the chain guide's small pieces (cards, key caps, section titles, wrapped text) in
## the Ember Tree's dark style with Monogram text, tinted by element. Apollo palette only.
## Nothing here catches the mouse unless it is meant to be clicked.

const TEXT_SIZE := EmberTreeFonts.TEXT_SIZE
const LARGE_SIZE := EmberTreeFonts.LARGE_SIZE
const ROW_GAP := 6
const KEY_CAP_PADDING := 4


## A see-through dark card edged in `edge_color`.
static func make_card(edge_color: Color) -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", card_style(edge_color))
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return card


static func card_style(edge_color: Color) -> StyleBoxFlat:
	return EmberTreeWidgets.card_style(EmberTreePalette.PANEL, Color(edge_color, 0.8))


static func make_column(separation: int = ROW_GAP) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", separation)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return column


static func make_row(separation: int = ROW_GAP) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", separation)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return row


static func make_label(text: String, color: Color, font_size: int = TEXT_SIZE) -> Label:
	var label := UiLabel.make(font_size, color, text)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label


## Text that wraps to the width of its column.
static func make_wrapped(text: String, color: Color) -> Label:
	var label := make_label(text, color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label


## A key on the keyboard, e.g. "W" or "1": gold letters in a framed dark box.
static func make_key_cap(keys: String, color: Color = EmberTreePalette.GOLD) -> PanelContainer:
	var cap := PanelContainer.new()
	var style := EmberTreeWidgets.card_style(ApolloPalette.NIGHT, color)
	style.shadow_size = 0
	style.set_corner_radius_all(2)
	style.content_margin_left = KEY_CAP_PADDING
	style.content_margin_right = KEY_CAP_PADDING
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	cap.add_theme_stylebox_override("panel", style)
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cap.add_child(make_label(keys, color))
	return cap


## A small upper-case heading, e.g. "SIGNAL SKILL", in `color`.
static func make_section_title(text: String, color: Color) -> Label:
	return make_label(text.to_upper(), color)


## A thin line across a card in `color`.
static func make_divider(color: Color) -> ColorRect:
	var divider := ColorRect.new()
	divider.color = Color(color, 0.4)
	divider.custom_minimum_size = Vector2(0, 1)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return divider


## Fills the rest of a row, pushing what follows to its right end.
static func make_spacer() -> Control:
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return spacer


## "[icon] Rooted": a status's icon and its name in its colour.
static func make_status_chip(status_name: String) -> HBoxContainer:
	var chip := make_row(4)
	chip.add_child(ChainGuideIcon.status(status_name))
	chip.add_child(make_label(ChainStatusIcons.name_of(status_name), ChainStatusIcons.color_of(status_name)))
	return chip


## A number as short as it reads: 6.0 -> "6", 1.5 -> "1.5".
static func short_number(value: float) -> String:
	return str(int(value)) if is_equal_approx(value, roundf(value)) else "%.1f" % value
