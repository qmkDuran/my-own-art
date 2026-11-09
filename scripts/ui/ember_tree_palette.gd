class_name EmberTreePalette
extends RefCounted
## The Ember Tree screen's colour roles, all taken from ApolloPalette.
## Shared by the tree, the side panel and the bars so they stay one warm, dark style.

const BACKGROUND := ApolloPalette.OUTLINE
const OUTLINE := ApolloPalette.OUTLINE
const CREAM := ApolloPalette.CREAM
const GREY := ApolloPalette.STONE_LIGHT
const DIM := ApolloPalette.STONE
const COAL := ApolloPalette.NIGHT
const EMBER_DARK := ApolloPalette.COAL_DARK
const ORANGE := ApolloPalette.ORANGE
const RED := ApolloPalette.RED_LIGHT
const GOLD := ApolloPalette.GOLD
const DEEP := ApolloPalette.BRICK
## A number that gets better if the pointed-at ember is ignited.
const BETTER := ApolloPalette.GREEN_LIGHT

## See-through versions of the dark background for panels laid over the tree.
const PANEL := Color(BACKGROUND, 0.92)
const PANEL_EDGE := Color(ORANGE, 0.55)
const BAR := Color(BACKGROUND, 0.72)

## Each branch's label colour, so the three directions read apart at a glance.
const BRANCH_COLORS := {"inferno": RED, "flurry": GOLD, "bruiser": CREAM}

## How a node looks in each state (see EmberTreeNodeState), shared with the legend.
## SEALED = its ring has not opened yet (Emberoo must Awaken), so it is fainter than LOCKED.
const NODE_FILL := {
	EmberTreeNodeState.LEARNED: DEEP, EmberTreeNodeState.AVAILABLE: EMBER_DARK,
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
