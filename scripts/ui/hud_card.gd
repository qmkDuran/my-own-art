class_name HudCard
extends RefCounted
## Builds the HUD's cards (the skill tooltip, the discovery toast) in the Ember Tree's card
## style, so every panel in the game is one family: the same see-through dark background,
## bevelled warm frame, rounded pixel corners, drop shadow and Monogram font from the shared
## UI theme (PixelPanelStyle).
##
## The HUD runs at the game's 640×360 and the Ember Tree on the finer UI canvas (GameView).
## A HUD card is laid out in UI pixels and shown scaled down to the game's pixels
## (GameView.ui_to_game_scale, 2/3 at 1080p), so its text (EmberTreeFonts.TEXT_SIZE) and its
## one-pixel edge land on whole window pixels exactly as the Ember Tree's do, and stay crisp.
## Room between the card's outer edge and its text, in card pixels, frame included (smaller
## than the Ember Tree's, to keep the HUD's cards small next to the fight).
const PADDING_SIDES := 10
const PADDING_TOP_BOTTOM := 7


## An empty card at the UI canvas's pixel size, using the shared UI theme. Add its content
## as usual.
static func make() -> PanelContainer:
	var card := PanelContainer.new()
	card.theme = EmberTreeFonts.ui_theme()
	card.scale = Vector2.ONE * GameView.ui_to_game_scale()
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := EmberTreeWidgets.card_style()
	style.content_margin_left = PADDING_SIDES
	style.content_margin_right = PADDING_SIDES
	style.content_margin_top = PADDING_TOP_BOTTOM
	style.content_margin_bottom = PADDING_TOP_BOTTOM
	card.add_theme_stylebox_override("panel", style)
	return card


## How big the card shows on the HUD, in game pixels.
static func size_on_screen(card: Control) -> Vector2:
	return card.size * card.scale
