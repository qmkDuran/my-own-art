"""Tallow, the last lit city: timber-and-soot houses with warm windows, the Great Lantern on its iron tower,
Fenn's forge, Lio's archive, market stalls, and the service objects (Nim's map table, the lockers, the ledger).
Windows and flames are on the emissive layer so the city glows in its own dark."""
from __future__ import annotations

import random

from pix import Spr
from props import _finish


def house(seed: int, w: int = 112, h: int = 104) -> Spr:
    """A narrow Tallow house: soot-dark timber over plaster, a steep roof, lit windows (someone is home)."""
    rnd = random.Random(seed)
    s = Spr(w, h)
    wall_top = int(h * 0.42)
    s.rect(8, wall_top, w - 9, h - 3, "earth")
    for x in range(8, w - 8, 16):
        s.rect(x, wall_top, x + 2, h - 3, "earth_dk")
    s.line([(8, wall_top + 18), (w - 9, wall_top + 18)], "earth_dk", width=2)
    roof = rnd.choice(["rust", "stone_dk", "ember_dk"])
    s.poly([(2, wall_top + 2), (w / 2, 4), (w - 3, wall_top + 2)], roof)
    s.poly([(2, wall_top + 2), (w / 2, 4), (w / 2 + 3, 7), (10, wall_top + 2)], "stone" if roof == "stone_dk" else "rust")
    for k in range(5):
        y = 12 + k * (wall_top - 12) // 5
        s.line([(w / 2 - (y - 4) * w / (2 * wall_top), y), (w / 2 + (y - 4) * w / (2 * wall_top), y)], "ink")
    s.rect(int(w * 0.62), 8, int(w * 0.62) + 7, 24, "stone_dk")
    door_x = rnd.choice([int(w * 0.2), int(w * 0.5)])
    s.rect(door_x, h - 26, door_x + 13, h - 3, "ink")
    s.px(door_x + 10, h - 14, "amber")
    for wx in (int(w * 0.2) if door_x != int(w * 0.2) else int(w * 0.5), int(w * 0.75)):
        s.rect(wx, wall_top + 24, wx + 11, wall_top + 35, "ink")
        if rnd.random() < 0.75:
            s.rect(wx + 1, wall_top + 25, wx + 10, wall_top + 34, "amber", glow=True)
            s.line([(wx + 6, wall_top + 25), (wx + 6, wall_top + 34)], "ember_dk")
    return _finish(s, "flame", {roof, "rust"})


def great_lantern() -> Spr:
    """The Great Lantern: an iron tower, braced and riveted, carrying a lantern the size of a house."""
    s = Spr(112, 208)
    s.poly([(30, 204), (82, 204), (66, 90), (46, 90)], "stone_dk")
    for y in range(100, 204, 14):
        w = 8 + (y - 90) * 0.24
        s.line([(56 - w, y), (56 + w, y)], "ink")
        s.line([(56 - w, y), (56 + w * 0.6, y - 12)], "stone")
    s.rect(34, 80, 78, 92, "ink")
    s.rect(24, 30, 88, 82, "ink")
    s.rect(28, 34, 84, 78, "amber", glow=True)
    s.rect(36, 40, 76, 72, "gold", glow=True)
    s.rect(46, 46, 66, 66, "sun", glow=True)
    for x in (44, 56, 68):
        s.line([(x, 34), (x, 78)], "ink", width=2)
    s.poly([(20, 30), (56, 4), (92, 30)], "ink")
    s.rect(52, 0, 60, 6, "stone_dk")
    s.line([(22, 30), (90, 30)], "stone")
    return _finish(s, "stone_lt", {"stone_dk"})


def forge() -> Spr:
    """The Ember Forge: an open-fronted smithy, the hearth roaring, an anvil out front."""
    s = Spr(128, 104)
    s.rect(6, 40, 122, 100, "stone_dk")
    s.poly([(0, 44), (20, 14), (108, 14), (128, 44)], "rust")
    s.line([(0, 44), (128, 44)], "ember_dk", width=2)
    s.rect(92, 0, 104, 30, "stone")
    s.rect(18, 50, 110, 100, "ink")
    s.rect(30, 60, 66, 92, "stone")
    s.rect(34, 66, 62, 90, "ember", glow=True)
    s.rect(40, 72, 56, 88, "flame", glow=True)
    s.rect(44, 78, 52, 86, "gold", glow=True)
    s.rect(76, 82, 100, 88, "stone_lt")
    s.rect(82, 88, 94, 100, "stone")
    for x in (72, 104):
        s.line([(x, 58), (x + 4, 72)], "stone_lt", width=2)
    return _finish(s, "flame", {"rust"})


def archive() -> Spr:
    """The Archive of Rewritten Things: a pale stone hall, shelves of jars glowing in the windows."""
    s = Spr(128, 112)
    s.rect(8, 44, 120, 108, "stone_lt")
    for x in range(14, 120, 26):
        s.rect(x, 44, x + 6, 108, "pale")
    s.poly([(2, 46), (64, 10), (126, 46)], "stone")
    s.poly([(2, 46), (64, 10), (64, 16), (12, 46)], "stone_lt")
    s.rect(54, 76, 74, 108, "ink")
    s.poly([(54, 76), (64, 66), (74, 76)], "ink")
    for wx in (22, 92):
        s.rect(wx, 58, wx + 16, 80, "ink")
        for k in range(3):
            s.ellipse(wx + 4 + k * 4, 66 + (k % 2) * 6, 2, 3, ("violet_lt", "glint", "amber")[k], glow=True)
    return _finish(s, "bone", {"stone_lt", "stone"})


def stall(seed: int) -> Spr:
    rnd = random.Random(seed)
    s = Spr(64, 60)
    cloth = rnd.choice(["rust", "glass_dk", "violet"])
    s.rect(6, 34, 58, 56, "earth")
    s.line([(6, 40), (58, 40)], "earth_dk")
    for x in (8, 54):
        s.rect(x, 14, x + 2, 56, "earth_dk")
    s.poly([(2, 18), (8, 6), (56, 6), (62, 18)], cloth)
    for x in range(4, 62, 8):
        s.poly([(x, 18), (x + 4, 18), (x + 2, 22)], cloth)
    for k in range(5):
        s.ellipse(14 + k * 9, 32, 3, 3, rnd.choice(["amber", "glass_lt", "bone", "ember"]))
    return _finish(s, "pale", {cloth})


def crates() -> Spr:
    s = Spr(36, 30)
    s.rect(2, 12, 20, 28, "earth")
    s.rect(16, 4, 34, 28, "earth_lt")
    for x0, y0, x1, y1 in ((2, 12, 20, 28), (16, 4, 34, 28)):
        s.line([(x0, y0), (x1, y1)], "earth_dk")
    return _finish(s)


def map_table() -> Spr:
    """Nim's map table: every road she has seen, pinned flat under stones."""
    s = Spr(52, 36)
    s.rect(4, 12, 48, 22, "earth")
    s.rect(6, 22, 9, 34, "earth_dk")
    s.rect(43, 22, 46, 34, "earth_dk")
    s.poly([(6, 12), (46, 12), (44, 4), (8, 4)], "bone")
    s.line([(10, 8), (24, 6), (32, 10), (42, 7)], "rust")
    s.line([(14, 10), (20, 5)], "glass")
    s.ellipse(36, 8, 2, 2, "stone")
    s.px(24, 6, "amber", glow=True)
    return _finish(s, "earth_lt", {"earth"})


def lockers() -> Spr:
    """Fenn's lockers: riveted iron boxes, each with a padlock the size of a fist."""
    s = Spr(52, 44)
    for k in range(3):
        x = 3 + k * 16
        s.rect(x, 6, x + 14, 42, "stone")
        s.rect(x + 1, 6, x + 2, 42, "stone_lt")
        s.rect(x + 5, 20, x + 9, 25, "amber")
    s.rect(2, 4, 50, 7, "stone_dk")
    return _finish(s, "pale", {"stone"})


def ledger() -> Spr:
    """The order's ledger on its lectern, by the Great Lantern."""
    s = Spr(28, 40)
    s.rect(12, 16, 15, 38, "earth_dk")
    s.rect(6, 36, 21, 39, "earth_dk")
    s.poly([(2, 16), (26, 16), (24, 8), (4, 8)], "rust")
    s.poly([(5, 15), (23, 15), (21, 9), (7, 9)], "bone")
    s.line([(14, 9), (14, 15)], "stone")
    return _finish(s, "earth_lt", {"rust"})


def bench() -> Spr:
    s = Spr(40, 22)
    s.rect(3, 8, 37, 11, "earth")
    s.line([(3, 8), (37, 8)], "earth_lt")
    s.rect(3, 3, 37, 5, "earth_dk")
    for x in (6, 33):
        s.rect(x, 11, x + 2, 20, "stone_dk")
    return _finish(s, "earth_lt", {"earth"})


def banner(seed: int) -> Spr:
    """A guild banner on an iron pole: the Lamplighters' sun-mark, the forge's hammer, the archive's jar."""
    rnd = random.Random(seed)
    s = Spr(24, 72)
    s.rect(3, 4, 5, 70, "stone_dk")
    s.ellipse(4, 3, 2, 2, "amber")
    cloth = rnd.choice(["rust", "glass_dk", "violet", "ember_dk"])
    s.poly([(6, 8), (22, 8), (22, 40), (14, 34), (6, 40)], cloth)
    s.line([(6, 8), (22, 8)], "gold")
    s.ellipse(14, 20, 4, 4, "gold")
    s.ellipse(14, 20, 2, 2, cloth)
    s.rect(1, 66, 8, 70, "stone")
    return _finish(s, "pale", {cloth})


def planter(seed: int) -> Spr:
    """A stone trough of hardy lantern-fern, the only green that grows under the Great Lantern."""
    rnd = random.Random(seed)
    s = Spr(36, 30)
    s.rect(3, 18, 33, 28, "stone")
    s.line([(3, 18), (33, 18)], "stone_lt")
    for _ in range(9):
        x = rnd.uniform(6, 30)
        s.line([(x, 18), (x + rnd.uniform(-4, 4), rnd.uniform(4, 12))], rnd.choice(["moss_lt", "moss", "glass_dk"]), width=2)
    s.px(16, 8, "amber", glow=True)
    return _finish(s, "pale", {"stone"})


def barrels() -> Spr:
    s = Spr(36, 30)
    for x, y in ((10, 20), (24, 22), (17, 12)):
        s.ellipse(x, y, 7, 8, "earth")
        s.line([(x - 6, y - 3), (x + 6, y - 3)], "stone_dk")
        s.line([(x - 6, y + 3), (x + 6, y + 3)], "stone_dk")
        s.ellipse(x, y - 7, 5, 2, "earth_lt")
    return _finish(s, "earth_lt", {"earth"})


MANIFEST: dict[str, dict] = {
    "bench": {"draw": bench, "foot": [36, 8]},
    "banner_a": {"draw": lambda: banner(71), "foot": [8, 6]},
    "banner_b": {"draw": lambda: banner(72), "foot": [8, 6]},
    "planter": {"draw": lambda: planter(73), "foot": [32, 10]},
    "barrels": {"draw": barrels, "foot": [30, 10]},
    "house_a": {"draw": lambda: house(41), "foot": [96, 30]},
    "house_b": {"draw": lambda: house(42, 96, 96), "foot": [80, 28]},
    "house_c": {"draw": lambda: house(43, 128, 112), "foot": [112, 32]},
    "great_lantern": {"draw": great_lantern, "foot": [52, 20], "light": "gold"},
    "forge": {"draw": forge, "foot": [116, 30], "light": "flame"},
    "archive": {"draw": archive, "foot": [112, 32]},
    "stall_a": {"draw": lambda: stall(51), "foot": [52, 14]},
    "stall_b": {"draw": lambda: stall(52), "foot": [52, 14]},
    "crates": {"draw": crates, "foot": [32, 12]},
    "map_table": {"draw": map_table, "foot": [44, 10]},
    "lockers": {"draw": lockers, "foot": [48, 10]},
    "ledger": {"draw": ledger, "foot": [16, 8]},
}
