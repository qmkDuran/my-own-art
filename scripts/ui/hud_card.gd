class_name HudCard
extends RefCounted
## Builds the HUD's cards (the skill tooltip, the discovery toast) in the Ember Tree's card
## style, so every panel in the game is one family: the same see-through dark background,
## warm edge, rounded corners, soft shadow and Monogram font from the shared UI theme.
##
## The HUD runs at 480×270 and the Ember Tree at 960×540. A HUD card is laid out on the
## Ember Tree's canvas (twice the game's resolution) and shown at half size, so its text
## (EmberTreeFonts.TEXT_SIZE: one font pixel = two screen pixels) and its one-pixel edge are
## exactly as fine as the Ember Tree's, and stay crisp.

## A card's own pixels per game pixel is 1 / CANVAS_SCALE.
const CANVAS_SCALE := 0.5
## Room between the card's edge and its text, in card pixels (smaller than the Ember Tree's,
## to keep the HUD's cards small next to the fight).
const PADDING_SIDES := 8
const PADDING_TOP_BOTTOM := 5


## An empty card at half size, using the shared UI theme. Add its content as usual.
static func make() -> PanelContainer:
	var card := PanelContainer.new()
	card.theme = EmberTreeFonts.ui_theme()
	card.scale = Vector2.ONE * CANVAS_SCALE
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := EmberTreeWidgets.card_style(EmberTreePalette.PANEL, EmberTreePalette.PANEL_EDGE)
	style.content_margin_left = PADDING_SIDES
	style.content_margin_right = PADDING_SIDES
	style.content_margin_top = PADDING_TOP_BOTTOM
	style.content_margin_bottom = PADDING_TOP_BOTTOM
	card.add_theme_stylebox_override("panel", style)
	return card


## How big the card shows on the HUD, in game pixels.
static func size_on_screen(card: Control) -> Vector2:
	return card.size * CANVAS_SCALE
