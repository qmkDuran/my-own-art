"""LANTERNFALL palette: one limited, cohesive palette for every sprite, prop, tile and icon.

Three families meet in every scene: cold DUSK darks (blue-violet), GLASS (teal), and LANTERN warmth (ember to sun-white).
Earth/moss/stone are muted bridges between them. tools/check_art.py rejects any sprite pixel outside this table.
Mirrored in game/scripts/core/pal.gd for the shader and UI (keep in sync: tools/check_art.py compares them).
"""

PAL: dict[str, tuple[int, int, int]] = {
    # dusk darks
    "void": (11, 10, 18), "ink": (21, 19, 31), "night": (29, 27, 44), "dusk1": (42, 39, 64),
    "dusk2": (59, 55, 87), "dusk3": (85, 80, 122), "mist": (122, 118, 160), "pale": (180, 178, 207),
    "bone": (232, 228, 216),
    # lantern warmth
    "ember_dk": (74, 30, 26), "rust": (124, 47, 31), "ember": (194, 69, 30), "flame": (240, 122, 36),
    "amber": (247, 176, 67), "gold": (255, 215, 122), "sun": (255, 246, 214),
    # glass
    "glass_dp": (18, 48, 58), "glass_dk": (28, 74, 85), "glass": (47, 125, 132), "glass_lt": (87, 184, 176),
    "glint": (166, 240, 224),
    # moss / earth / stone
    "moss_dk": (26, 36, 32), "moss": (38, 53, 44), "moss_lt": (59, 77, 58), "earth_dk": (42, 32, 28),
    "earth": (67, 51, 42), "earth_lt": (107, 80, 64), "stone_dk": (44, 43, 51), "stone": (74, 72, 82),
    "stone_lt": (117, 114, 126),
    # accents
    "blood": (184, 40, 58), "rose": (232, 80, 90), "violet": (106, 61, 154), "violet_lt": (160, 112, 216),
    "skin_dk": (122, 74, 58), "skin": (176, 116, 88), "skin_lt": (214, 160, 124),
    # creature elements (the trainer prototype): leaf greens for Bloom, sea blues for Tide, bile for Rot
    "leaf_dk": (36, 84, 52), "leaf": (72, 146, 70), "leaf_lt": (150, 212, 104),
    "sea_dk": (30, 52, 112), "sea": (54, 102, 190), "sea_lt": (116, 176, 238),
    "bile_dk": (92, 100, 38), "bile": (176, 186, 62),
}

OUTLINE = "void"


def rgba(name: str, a: int = 255) -> tuple[int, int, int, int]:
    r, g, b = PAL[name]
    return (r, g, b, a)


def hexcode(name: str) -> str:
    return "%02x%02x%02x" % PAL[name]
