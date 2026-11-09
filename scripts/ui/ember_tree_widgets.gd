class_name EmberTreeWidgets
extends RefCounted
## Builds the Ember Tree screen's standard pieces (cards, buttons, badges) in its cold
## stone style with ember highlights (EmberTreePalette), so the screen and its side panel look the same and say it only once.
## Every piece ignores the mouse unless it is meant to be clicked.

const CARD_PADDING := 12
## A scroll bar's width, in canvas pixels.
const SCROLL_BAR_WIDTH := 10.0
## A skill's video clip frame keeps a 16:9 shape; this is its height for each pixel of width.
const PREVIEW_ASPECT := 9.0 / 16.0
## The clip frame is never taller than this, so long cards still fit.
const PREVIEW_MAX_HEIGHT := 64.0
const PREVIEW_PLACEHOLDER := "Video preview coming soon"


## A see-through slate card with a bevelled stone edge.
static func make_card() -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", card_style())
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return card


## The game's panel (PixelPanelStyle): a pixel frame lit on the top and left (`border`),
## shaded on the bottom and right (`border_dark`), rounded corners, a drop shadow and room inside.
static func card_style(background: Color = EmberTreePalette.PANEL, border: Color = EmberTreePalette.PANEL_EDGE,
		border_dark: Color = EmberTreePalette.PANEL_EDGE_DARK) -> PixelPanelStyle:
	var style := PixelPanelStyle.new()
	style.bg_color = background
	style.border_color = border
	style.border_dark_color = border_dark
	style.set_content_margin_all(CARD_PADDING)
	return style


static func make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	# No keyboard focus: Tab toggles the tree and must not move focus to the button instead.
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", EmberTreeFonts.TEXT_SIZE)
	button.add_theme_color_override("font_color", EmberTreePalette.CREAM)
	button.add_theme_color_override("font_hover_color", EmberTreePalette.GOLD)
	button.add_theme_color_override("font_pressed_color", EmberTreePalette.GOLD)
	button.add_theme_color_override("font_disabled_color", EmberTreePalette.GREY)
	button.add_theme_stylebox_override("normal", _button_style(EmberTreePalette.BUTTON_FILL, EmberTreePalette.BUTTON_EDGE, EmberTreePalette.BUTTON_EDGE_DARK))
	button.add_theme_stylebox_override("hover", _button_style(EmberTreePalette.HOT_FILL, EmberTreePalette.HOT_EDGE, EmberTreePalette.HOT_EDGE_DARK))
	var pressed := _button_style(EmberTreePalette.HOT_FILL, EmberTreePalette.HOT_EDGE, EmberTreePalette.HOT_EDGE_DARK)
	# Pushed in: the bevel flips and the words sink by one frame pixel.
	pressed.is_inset = true
	pressed.shadow_color = Color.TRANSPARENT
	pressed.content_margin_top += pressed.unit
	pressed.content_margin_bottom -= pressed.unit
	button.add_theme_stylebox_override("pressed", pressed)
	var disabled := _button_style(EmberTreePalette.OFF_FILL, EmberTreePalette.OFF_EDGE, EmberTreePalette.OFF_EDGE_DARK)
	disabled.shadow_color = Color.TRANSPARENT
	button.add_theme_stylebox_override("disabled", disabled)
	return button


## Gives a scroll bar the panels' look: a dark inset track and a stone grabber that lights up
## (Godot's default grey bar would be the one thing on the screen not in the game's style).
static func style_scroll_bar(bar: ScrollBar) -> void:
	bar.custom_minimum_size.x = SCROLL_BAR_WIDTH
	var track := card_style(EmberTreePalette.WELL, EmberTreePalette.OFF_EDGE, EmberTreePalette.DIM)
	track.is_inset = true
	track.shadow_color = Color.TRANSPARENT
	track.set_content_margin_all(0)
	bar.add_theme_stylebox_override("scroll", track)
	bar.add_theme_stylebox_override("scroll_focus", track)
	for state: String in ["grabber", "grabber_highlight", "grabber_pressed"]:
		var is_lit := state != "grabber"
		var grabber := card_style(EmberTreePalette.HOT_FILL if is_lit else EmberTreePalette.BUTTON_FILL,
				EmberTreePalette.HOT_EDGE if is_lit else EmberTreePalette.PANEL_EDGE,
				EmberTreePalette.HOT_EDGE_DARK if is_lit else EmberTreePalette.BUTTON_EDGE_DARK)
		grabber.shadow_color = Color.TRANSPARENT
		grabber.set_content_margin_all(SCROLL_BAR_WIDTH / 2.0)
		bar.add_theme_stylebox_override(state, grabber)


## A small orange badge with a short grey note beside it, e.g. "COMING SOON".
static func make_badge_row(badge_text: String, note_text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var badge := PanelContainer.new()
	var badge_style := card_style(EmberTreePalette.HOT_FILL, EmberTreePalette.ORANGE, EmberTreePalette.DEEP)
	badge_style.shadow_color = Color.TRANSPARENT
	badge_style.content_margin_left = 6
	badge_style.content_margin_right = 6
	badge_style.content_margin_top = 2
	badge_style.content_margin_bottom = 2
	badge.add_theme_stylebox_override("panel", badge_style)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(UiLabel.make(EmberTreeFonts.TEXT_SIZE, EmberTreePalette.ORANGE, badge_text))
	row.add_child(badge)
	var note := UiLabel.make(EmberTreeFonts.TEXT_SIZE, EmberTreePalette.GREY, note_text)
	note.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(note)
	return row


## A thin stone line across a card, `width` long.
static func make_divider(width: float) -> ColorRect:
	var divider := ColorRect.new()
	divider.color = EmberTreePalette.DIVIDER
	divider.custom_minimum_size = Vector2(width, 1)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return divider


## Wrapping rich text (BBCode) `width` wide, as tall as its text, in cream.
static func make_rich_text(width: float) -> RichTextLabel:
	var rich_text := RichTextLabel.new()
	rich_text.bbcode_enabled = true
	rich_text.fit_content = true
	rich_text.scroll_active = false
	rich_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rich_text.custom_minimum_size.x = width
	rich_text.add_theme_color_override("default_color", EmberTreePalette.CREAM)
	rich_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rich_text


## An empty dark frame where a skill's video clip will play, with a placeholder note.
static func make_preview_frame(width: float) -> PanelContainer:
	var frame := PanelContainer.new()
	# Inset (shaded on top), like a screen set into the card.
	var style := card_style(EmberTreePalette.WELL, EmberTreePalette.DIM, EmberTreePalette.SLATE)
	style.is_inset = true
	style.shadow_color = Color.TRANSPARENT
	style.set_content_margin_all(0)
	frame.add_theme_stylebox_override("panel", style)
	frame.custom_minimum_size = Vector2(width, minf(PREVIEW_MAX_HEIGHT, roundf(width * PREVIEW_ASPECT)))
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var note := UiLabel.make(EmberTreeFonts.TEXT_SIZE, EmberTreePalette.GREY, PREVIEW_PLACEHOLDER)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	frame.add_child(note)
	return frame


static func _button_style(background: Color, border: Color, border_dark: Color) -> PixelPanelStyle:
	var style := card_style(background, border, border_dark)
	# One pixel less on top: Monogram's line keeps room above the letters, so even margins
	# would leave the words sitting low in the button.
	style.content_margin_top = 3
	style.content_margin_bottom = 5
	return style
