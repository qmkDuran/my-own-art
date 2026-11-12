class_name ArenaPalette
extends RefCounted
## The colours an arena is drawn in: ground by style (meadow green, forest floor, ruin flagstones) and a wash per
## feature (water, mud, coals, ledge stone...), all palette names.

const GROUND: Dictionary = {"meadow": ["leaf", "leaf_dk"], "forest": ["moss_lt", "leaf_dk"], "ruins": ["stone_lt", "stone"],
	"hall": ["stone", "stone_dk"]}
const FEATURE: Dictionary = {
	ArenaLayout.F.SHALLOW: ["sea_lt", 0.7], ArenaLayout.F.DEEP: ["sea_dk", 1.0], ArenaLayout.F.MUD: ["earth", 0.95],
	ArenaLayout.F.ROCK: ["leaf_dk", 0.5], ArenaLayout.F.THICKET: ["leaf_dk", 1.0], ArenaLayout.F.ROOTS: ["earth_lt", 0.55],
	ArenaLayout.F.LEDGE: ["stone_lt", 1.0], ArenaLayout.F.RAMP: ["stone", 1.0], ArenaLayout.F.WALL: ["stone", 1.0],
	ArenaLayout.F.BRIDGE: ["earth_lt", 1.0], ArenaLayout.F.CRACKED: ["stone", 1.0], ArenaLayout.F.COALS: ["ember_dk", 1.0],
	ArenaLayout.F.THORNS: ["earth_dk", 0.6], ArenaLayout.F.FLAT: ["leaf_lt", 0.35], ArenaLayout.F.GRASS: ["leaf_dk", 0.35],
}


static func ground(style: String, alt: bool) -> Color:
	var pair: Array = GROUND.get(style, GROUND["meadow"])
	return Pal.c(String(pair[1] if alt else pair[0]))


## The wash over a cell's ground for its feature (transparent for none).
static func feature(f: int, _style: String) -> Color:
	if not FEATURE.has(f):
		return Color(0, 0, 0, 0)
	return Pal.c(String(FEATURE[f][0]), float(FEATURE[f][1]))
