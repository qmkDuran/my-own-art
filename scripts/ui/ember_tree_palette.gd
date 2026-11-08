class_name EmberTreePalette
extends RefCounted
## The Ember Tree screen's colours, all from the Apollo palette (see DESIGN.md, "Art").
## Shared by the tree, the side panel and the bars so they stay one warm, dark style.

const BACKGROUND := Color(0.035, 0.039, 0.078)          # Apollo 090a14
const OUTLINE := Color(0.035, 0.039, 0.078)             # Apollo 090a14
const CREAM := Color(0.906, 0.835, 0.702)               # Apollo e7d5b3
const GREY := Color(0.341, 0.447, 0.467)                # Apollo 577277
const DIM := Color(0.224, 0.29, 0.314)                  # Apollo 394a50
const COAL := Color(0.063, 0.078, 0.122)                # Apollo 10141f
const EMBER_DARK := Color(0.141, 0.082, 0.153)          # Apollo 241527
const ORANGE := Color(0.871, 0.62, 0.255)               # Apollo de9e41
const RED := Color(0.812, 0.341, 0.235)                 # Apollo cf573c
const GOLD := Color(0.91, 0.757, 0.439)                 # Apollo e8c170
const DEEP := Color(0.376, 0.173, 0.173)                # Apollo 602c2c

## See-through versions of the dark background for panels laid over the tree.
const PANEL := Color(BACKGROUND, 0.8)
const PANEL_EDGE := Color(ORANGE, 0.55)
const BAR := Color(BACKGROUND, 0.72)

## Each branch's label colour, so the three directions read apart at a glance.
const BRANCH_COLORS := {"inferno": RED, "flurry": GOLD, "bruiser": CREAM}

## How a node looks in each state (see EmberTreeCanvas.state_of), shared with the legend.
## "sealed" = its ring has not opened yet (Emberoo must evolve), so it is fainter than "locked".
const NODE_FILL := {"learned": DEEP, "available": EMBER_DARK, "locked": COAL, "sealed": COAL}
const NODE_EDGE := {"learned": GOLD, "available": CREAM, "locked": DIM, "sealed": Color(DIM, 0.6)}
const NODE_ICON := {"learned": GOLD, "available": CREAM, "locked": DIM, "sealed": Color(DIM, 0.45)}
