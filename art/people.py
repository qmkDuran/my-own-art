"""Overworld people: 16x32 frames, hand-placed pixel templates recoloured per character.

A frame is a head template (rows 8-19) over a body template (rows 20-31). Letters are colour slots:
O outline, H/h hair (light/shade), S/s skin, E eye, T/t top, P/p legs or skirt, B boots, A accent, W white.
Sheet layout (9 frames): down stand, down step L, down step R, up stand, up step L, up step R, left stand,
left step 1, left step 2 (right is the left frames mirrored in the game)."""
from __future__ import annotations

from PIL import Image

from palette import rgb

W, H = 16, 32
HEAD_DOWN = [
    "......OOOO......",
    "....OOHHHHOO....",
    "...OHHHHHHHHO...",
    "..OHHHHHHHHHHO..",
    "..OHHHHHHHHHHO..",
    "..OHhHHhHHhHhO..",
    "..OhSShSSSShSO..",
    "..OSSSSSSSSSSO..",
    "..OSSESSSSESSO..",
    "..OSSESSSSESSO..",
    "...OsSSSSSSsO...",
    "....OOssssOO....",
]
HEAD_UP = [
    "......OOOO......",
    "....OOHHHHOO....",
    "...OHHHHHHHHO...",
    "..OHHHHHHHHHHO..",
    "..OHHHHHHHHHHO..",
    "..OHHHHHHHHHHO..",
    "..OHHHHHHHHHHO..",
    "..OHhHHHHHHhHO..",
    "..OhHhHHHHhHhO..",
    "..OShhhhhhhhSO..",
    "...OSShhhhSSO...",
    "....OOssssOO....",
]
HEAD_LEFT = [
    "......OOOOO.....",
    "....OOHHHHHO....",
    "...OHHHHHHHHO...",
    "..OHHHHHHHHHHO..",
    "..OHHHHHHHHHHO..",
    "..OhHHHHHHHHhO..",
    "..OShSHHHHHhHO..",
    ".OSSSSSHHHHhHO..",
    ".OSESSSShHHHO...",
    ".OSESSSSShHHO...",
    "..OsSSSSShhO....",
    "...OOsssOOO.....",
]
BODY_DOWN = [
    "....OTTTTTTO....",
    "...OTTWWWWTTO...",
    "..OTTTAAAATTTO..",
    "..OTtTTTTTTtTO..",
    "..OStTTTTTTtSO..",
    "..OSOTTTTTTOSO..",
    "...OOPPPPPPOO...",
    "....OPPPPPPO....",
    "....OPpOOpPO....",
    "....OPpOOpPO....",
    "....OBBOOBBO....",
    ".....OO..OO.....",
]
BODY_DOWN_STEP = [
    "....OTTTTTTO....",
    "...OTTWWWWTTO...",
    "..OTTTAAAATTTO..",
    "..OTtTTTTTTtTO..",
    "..OStTTTTTTtSO..",
    "..OSOTTTTTTOSO..",
    "...OOPPPPPPOO...",
    "....OPPPPPPO....",
    "....OPpOOpPO....",
    "....OPpOOBBO....",
    "....OBBO.OO.....",
    ".....OO.........",
]
BODY_UP = [
    "....OTTTTTTO....",
    "...OTTTTTTTTO...",
    "..OTTTTTTTTTTO..",
    "..OTtTTTTTTtTO..",
    "..OStTTTTTTtSO..",
    "..OSOTTTTTTOSO..",
    "...OOPPPPPPOO...",
    "....OPPPPPPO....",
    "....OPpOOpPO....",
    "....OPpOOpPO....",
    "....OBBOOBBO....",
    ".....OO..OO.....",
]
BODY_UP_STEP = [
    "....OTTTTTTO....",
    "...OTTTTTTTTO...",
    "..OTTTTTTTTTTO..",
    "..OTtTTTTTTtTO..",
    "..OStTTTTTTtSO..",
    "..OSOTTTTTTOSO..",
    "...OOPPPPPPOO...",
    "....OPPPPPPO....",
    "....OPpOOpPO....",
    "....OPpOOBBO....",
    "....OBBO.OO.....",
    ".....OO.........",
]
BODY_LEFT = [
    ".....OTTTO......",
    "....OWTTTTO.....",
    "....OATTTTO.....",
    "....OTtTTtO.....",
    "....OTSStTO.....",
    "....OTSStTO.....",
    ".....OPPPO......",
    ".....OPPpO......",
    ".....OPPpO......",
    ".....OPPpO......",
    ".....OBBBO......",
    "......OOO.......",
]
BODY_LEFT_STEP = [
    ".....OTTTO......",
    "....OWTTTTO.....",
    "....OATTTTO.....",
    "....OTtTTtO.....",
    "...OSStTTtO.....",
    "...OSSOTTTO.....",
    ".....OPPPO......",
    "....OPPOPpO.....",
    "....OPpOOpPO....",
    "...OBBO..OpO....",
    "...OBBO..OBBO...",
    "....OO....OO....",
]
SKIRT_DOWN = [
    "...OOPPPPPPOO...",
    "...OPPPPPPPPO...",
    "..OPPpPPPPpPPO..",
    "..OPpPPPPPPpPO..",
    "...OOSOOOOSOO...",
    "....OBBOOBBO....",
]
SKIRT_DOWN_STEP = [
    "...OOPPPPPPOO...",
    "...OPPPPPPPPO...",
    "..OPPpPPPPpPPO..",
    "..OPpPPPPPPpPO..",
    "...OOSOOOOBBO...",
    "....OBBO..OO....",
]
SKIRT_LEFT = [
    ".....OPPPO......",
    "....OPPPPpO.....",
    "....OPPPPpO.....",
    "...OPPPPPpPO....",
    "....OOSOSOO.....",
    "....OBBOBBO.....",
]
SKIRT_LEFT_STEP = [
    ".....OPPPO......",
    "....OPPPPpO.....",
    "....OPPPPpO.....",
    "...OPPPPPpPO....",
    "...OBBOOOSOO....",
    "....OO..OBBO....",
]


def _with_skirt(body: list[str], skirt: list[str]) -> list[str]:
    return body[:6] + skirt


def frames(skirt: bool) -> list[list[str]]:
    """The nine frame templates (head + body) in sheet order."""
    bd, bds, bl, bls = BODY_DOWN, BODY_DOWN_STEP, BODY_LEFT, BODY_LEFT_STEP
    bu, bus = BODY_UP, BODY_UP_STEP
    if skirt:
        bd, bds = _with_skirt(bd, SKIRT_DOWN), _with_skirt(bds, SKIRT_DOWN_STEP)
        bu, bus = _with_skirt(bu, SKIRT_DOWN), _with_skirt(bus, SKIRT_DOWN_STEP)
        bl, bls = _with_skirt(bl, SKIRT_LEFT), _with_skirt(bls, SKIRT_LEFT_STEP)
    mirror = lambda rows: [r[::-1] for r in rows]
    return [
        HEAD_DOWN + bd, HEAD_DOWN + bds, HEAD_DOWN + mirror(bds),
        HEAD_UP + bu, HEAD_UP + bus, HEAD_UP + mirror(bus),
        HEAD_LEFT + bl, HEAD_LEFT + bls, HEAD_LEFT + bl,
    ]


def _style_hair(rows: list[str], style: str, view: str) -> list[str]:
    """Hair variations drawn over the base template: long, bun, cap, ponytail."""
    grid = [list("." * W) for _ in range(8)] + [list(r) for r in rows]
    if style == "long":
        _long_hair(grid, view)
    elif style == "bun":
        for y, row in ((5, "......OOOO......"), (6, ".....OHHHhO....."), (7, ".....OHhhhO.....")):
            grid[y] = list(row)
    elif style == "cap":
        _cap(grid, view)
    elif style == "tail":
        _ponytail(grid, view)
    return ["".join(r) for r in grid]


def _long_hair(grid: list[list[str]], view: str) -> None:
    """Hair falling to the shoulders: a strand each side (front), a curtain (back), behind the ear (side)."""
    if view == "left":
        for y in range(17, 24):
            grid[y][10:14] = list("OHhO") if y < 23 else list("OOOO")
        return
    for y in range(16, 24):
        for x, out in ((2, 1), (13, 14)):
            grid[y][x] = "H" if y < 23 else "O"
            grid[y][out] = "O"
    if view == "up":
        for y in range(17, 23):
            for x in range(3, 13):
                grid[y][x] = "h" if x in (3, 12) else "H"


def _cap(grid: list[list[str]], view: str) -> None:
    for y in range(9, 13):
        grid[y] = ["A" if ch in "Hh" else ch for ch in grid[y]]
    if view == "down":
        grid[13] = list("..OAAAAAAAAAAO..")
        grid[14] = list(".OOOOOOOOOOOOOO.")
    elif view == "left":
        grid[13] = list("OOOAAAAAAAAAAO..")
        grid[14] = list("OAAAOOOOOOOhHO..")


def _ponytail(grid: list[list[str]], view: str) -> None:
    if view == "left":
        for y, row in ((11, "OOO"), (12, "HHO"), (13, "HhO"), (14, "HhO"), (15, "hO.")):
            grid[y][13:16] = list(row)
    elif view == "up":
        for y in range(18, 23):
            grid[y][7:9] = list("Hh")
        grid[23][7:9] = list("OO")


def render_sheet(colours: dict[str, str], style: str = "short", skirt: bool = False) -> Image.Image:
    """A 9-frame sheet (144x32) for one person."""
    slots = {"O": "ink", "E": "ink", "W": "cream", **colours}
    sheet = Image.new("RGBA", (W * 9, H), (0, 0, 0, 0))
    views = ["down"] * 3 + ["up"] * 3 + ["left"] * 3
    for i, rows in enumerate(frames(skirt)):
        grid = _style_hair(rows, style, views[i])
        for y, row in enumerate(grid):
            for x, ch in enumerate(row):
                if ch != ".":
                    sheet.putpixel((i * W + x, y), rgb(slots[ch]))
    return sheet


PEOPLE: dict[str, tuple[dict[str, str], str, bool]] = {
    "player": ({"H": "bark2", "h": "bark1", "S": "skin2", "s": "skin1", "T": "teal1", "t": "teal0",
                "P": "deep1", "p": "deep0", "B": "bark1", "A": "ember3"}, "short", False),
    "gran": ({"H": "fog", "h": "mist", "S": "skin2", "s": "skin1", "T": "plum1", "t": "plum0",
              "P": "plum2", "p": "plum1", "B": "bark1", "A": "rose2"}, "bun", True),
    "keeper": ({"H": "paper", "h": "fog", "S": "skin1", "s": "skin0", "T": "leaf1", "t": "leaf0",
                "P": "leaf2", "p": "leaf1", "B": "bark1", "A": "sun"}, "long", True),
    "mender": ({"H": "teal1", "h": "teal0", "S": "skin3", "s": "skin2", "T": "cream", "t": "fog",
                "P": "rose1", "p": "rose0", "B": "bark1", "A": "leaf3"}, "bun", True),
    "grocer": ({"H": "bark1", "h": "bark0", "S": "skin1", "s": "skin0", "T": "sand2", "t": "sand1",
                "P": "bark2", "p": "bark1", "B": "bark0", "A": "ember2"}, "cap", False),
    "juni": ({"H": "ember1", "h": "ember0", "S": "skin3", "s": "skin2", "T": "ember3", "t": "ember2",
              "P": "stone1", "p": "stone0", "B": "bark1", "A": "sun"}, "tail", False),
    "forager": ({"H": "bark3", "h": "bark2", "S": "skin2", "s": "skin1", "T": "leaf2", "t": "leaf1",
                 "P": "bark2", "p": "bark1", "B": "bark0", "A": "leaf4"}, "cap", False),
    "fisher": ({"H": "ink2", "h": "ink", "S": "skin1", "s": "skin0", "T": "water2", "t": "deep1",
                "P": "sand1", "p": "bark3", "B": "bark1", "A": "sun"}, "long", False),
    "kid": ({"H": "sun", "h": "ember4", "S": "skin3", "s": "skin2", "T": "rose2", "t": "rose1",
             "P": "water2", "p": "deep1", "B": "bark1", "A": "cream"}, "short", False),
    "elder": ({"H": "stone3", "h": "stone2", "S": "skin2", "s": "skin1", "T": "bark2", "t": "bark1",
               "P": "stone1", "p": "stone0", "B": "bark0", "A": "sand2"}, "short", False),
}
