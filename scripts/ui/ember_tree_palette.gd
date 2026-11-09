class_name EmberTreePalette
extends RefCounted
## The Ember Tree screen's colour roles, all taken from ApolloPalette. Shared by the tree,
## the side panel, the bars and every card in the game (EmberTreeWidgets, HudCard).
##
## Art direction v2 (DESIGN.md): the frames are cold, dark stone (slate, stone, night) like
## the gritty world; warm ember colours (gold, orange) only mark what is lit: highlights,
## the hovered or selected thing, learned embers and Emberoo's own things. Text stays light
## on dark for contrast.

const BACKGROUND := ApolloPalette.OUTLINE
const OUTLINE := ApolloPalette.OUTLINE
const CREAM := ApolloPalette.CREAM
## Secondary text: a light enough grey to read on the slate cards.
const GREY := ApolloPalette.GREY
const DIM := ApolloPalette.STONE
const COAL := ApolloPalette.NIGHT
const EMBER_DARK := ApolloPalette.COAL_DARK
const ORANGE := ApolloPalette.ORANGE
const RED := ApolloPalette.RED_LIGHT
const GOLD := ApolloPalette.GOLD
const DEEP := ApolloPalette.BRICK
## A number that gets better if the pointed-at ember is ignited.
const BETTER := ApolloPalette.GREEN_LIGHT
const ORANGE_DARK := ApolloPalette.ORANGE_DARK
const SLATE := ApolloPalette.SLATE

## Cards (PixelPanelStyle): a see-through cold slate fill, lit stone on the top and left,
## shaded on the bottom and right.
const PANEL := Color(ApolloPalette.DARK, 0.94)
const PANEL_EDGE := ApolloPalette.STONE_LIGHT
const PANEL_EDGE_DARK := ApolloPalette.SLATE
## A thin line across a card or under a screen's title bar.
const DIVIDER := ApolloPalette.STONE
## A plain button: a step lighter than the cards, with a quieter stone edge.
const BUTTON_FILL := ApolloPalette.SLATE
const BUTTON_EDGE := ApolloPalette.STONE
const BUTTON_EDGE_DARK := ApolloPalette.NIGHT
## Lit by the ember: a hovered, pressed or selected button, a learned thing.
const HOT_FILL := ApolloPalette.COAL
const HOT_EDGE := ApolloPalette.GOLD
const HOT_EDGE_DARK := ApolloPalette.ORANGE_DARK
## A button that can't be used right now: sunk into the dark.
const OFF_FILL := ApolloPalette.NIGHT
const OFF_EDGE := ApolloPalette.SLATE
const OFF_EDGE_DARK := ApolloPalette.OUTLINE
## Inset wells (a scroll bar's track, a video frame): darker than the card around them.
const WELL := ApolloPalette.NIGHT
const BAR := Color(BACKGROUND, 0.72)
## The tree's rings: cold stone where the stage is open, a fainter dashed line where not.
const RING_OPEN := Color(ApolloPalette.STONE_LIGHT, 0.35)
const RING_SEALED := Color(ApolloPalette.STONE, 0.7)
## The medallion round Emberoo in the middle: his ember frame and its slow glow.
const MEDALLION_FILL := ApolloPalette.NIGHT
const MEDALLION_EDGE := ApolloPalette.ORANGE_DARK
const MEDALLION_GLOW := ApolloPalette.GOLD

## Each branch's label colour, so the three directions read apart at a glance.
const BRANCH_COLORS := {"inferno": RED, "flurry": GOLD, "bruiser": CREAM}

## How a node looks in each state (see EmberTreeNodeState), shared with the legend.
## Learned embers glow warm; the rest are cold stone. SEALED = its ring has not opened yet
## (Emberoo must Awaken), so it is fainter than LOCKED.
const NODE_FILL := {
	EmberTreeNodeState.LEARNED: DEEP, EmberTreeNodeState.AVAILABLE: SLATE,
	EmberTreeNodeState.LOCKED: COAL, EmberTreeNodeState.SEALED: COAL,
}
const NODE_EDGE := {
	EmberTreeNodeState.LEARNED: GOLD, EmberTreeNodeState.AVAILABLE: CREAM,
	EmberTreeNodeState.LOCKED: DIM, EmberTreeNodeState.SEALED: Color(DIM, 0.6),
}
## Tint over a node's icon art: its own colours, faded on a node whose ring is still sealed.
const NODE_ICON_TINT := {
	EmberTreeNodeState.LEARNED: Color.WHITE, EmberTreeNodeState.AVAILABLE: Color.WHITE,
	EmberTreeNodeState.LOCKED: Color.WHITE, EmberTreeNodeState.SEALED: Color(Color.WHITE, 0.45),
}
