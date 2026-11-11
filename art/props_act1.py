"""Props for the rest of Act 1: the ways between zones (road gate, cave mouth), the Ember Road's burnt farms, and
Moth Hollow's caves. Same rules as props.py: bottom-centre anchor, palette only, outline, top rim."""
from __future__ import annotations

import math
import random

from pix import Spr, dither_fill
from props import _finish, _prism


# ------------------------------------------------------------------ ways between zones
def road_gate() -> Spr:
    """Two posts and a crossbeam over the road, an unlit iron lamp swinging from it: the edge of a zone."""
    s = Spr(72, 84)
    for x in (10, 58):
        s.rect(x, 18, x + 4, 81, "earth_dk")
        s.line([(x + 1, 18), (x + 1, 81)], "earth")
    s.rect(4, 14, 68, 19, "earth")
    s.line([(4, 14), (68, 14)], "earth_lt")
    s.line([(36, 19), (36, 30)], "stone_dk")
    s.rect(31, 30, 41, 42, "ink")
    s.rect(32, 32, 40, 40, "glass_dp")
    s.poly([(30, 30), (36, 25), (42, 30)], "ink")
    s.rect(14, 46, 30, 52, "earth_lt")
    s.line([(16, 49), (28, 49)], "earth_dk")
    return _finish(s, "earth_lt", {"earth"})


def cave_mouth() -> Spr:
    """A mouth in the rock: a dark arch hung with moth silk, the cave breathing out cold."""
    s = Spr(120, 96)
    rnd = random.Random(21)
    pts = [(2, 94), (6, 50), (20, 22), (44, 8), (76, 8), (100, 22), (114, 50), (118, 94)]
    dither_fill(s, pts, "stone_dk", "stone", 0.2, 21)
    s.poly([(30, 94), (32, 56), (44, 36), (60, 30), (76, 36), (88, 56), (90, 94)], "void")
    s.poly([(36, 94), (38, 62), (60, 44), (82, 62), (84, 94)], "ink")
    for k in range(9):
        x = 36 + k * 6 + rnd.uniform(-2, 2)
        s.line([(x, 34 + (k % 3) * 4), (x + rnd.uniform(-3, 3), 52 + rnd.uniform(0, 14))], "pale")
    for x, y in ((14, 60), (100, 56), (52, 14)):
        s.ellipse(x, y, 5, 3, "stone_lt")
    return _finish(s, "mist", {"stone", "stone_dk"})


# ------------------------------------------------------------------ the Ember Road
def scarecrow() -> Spr:
    """A field's scarecrow, burnt; its pumpkin of a head is a cracked lantern with nothing in it."""
    s = Spr(36, 60)
    s.line([(18, 58), (18, 14)], "earth_dk", width=2)
    s.line([(5, 26), (31, 26)], "earth_dk", width=2)
    s.poly([(10, 24), (26, 24), (28, 44), (8, 44)], "rust")
    s.poly([(10, 24), (14, 24), (12, 44), (8, 44)], "ember_dk")
    for k in range(4):
        s.line([(9 + k * 5, 44), (8 + k * 5, 48)], "amber")
    s.line([(4, 26), (2, 30)], "amber")
    s.line([(32, 26), (34, 30)], "amber")
    s.rect(13, 8, 23, 18, "ink")
    s.rect(14, 10, 22, 16, "glass_dp")
    s.line([(15, 10), (20, 16)], "glass_dk")
    s.poly([(12, 8), (18, 3), (24, 8)], "ink")
    return _finish(s, "earth_lt", {"rust"})


def farmhouse() -> Spr:
    """A farmhouse the Dusk burned from the inside: stone walls standing, the roof gone to black ribs."""
    s = Spr(128, 100)
    s.rect(12, 44, 116, 96, "stone")
    for y in range(48, 96, 8):
        off = 0 if (y // 8) % 2 else 6
        for x in range(12 + off, 116, 14):
            s.rect(x, y, x + 12, y + 6, "stone_lt" if (x * y) % 7 else "stone")
    s.rect(12, 44, 16, 96, "stone_dk")
    s.poly([(40, 44), (52, 30), (60, 44)], "stone")
    for x in range(14, 116, 12):                                    # charred rafters
        s.line([(x, 44), (64, 12 + abs(x - 64) * 0.4)], "ink", width=2)
    s.line([(14, 44), (64, 12), (114, 44)], "ember_dk", width=2)
    s.rect(54, 66, 72, 96, "void")
    s.rect(24, 60, 36, 72, "void")
    s.rect(92, 60, 104, 72, "void")
    s.px(30, 70, "ember", glow=True)
    s.line([(12, 46), (116, 46)], "ink")
    return _finish(s, "pale", {"stone_lt", "stone"})


def haystack() -> Spr:
    s = Spr(44, 32)
    s.ellipse(22, 20, 19, 10, "earth_lt")
    s.ellipse(22, 14, 14, 9, "amber")
    s.ellipse(18, 12, 6, 4, "gold")
    s.ellipse(28, 22, 9, 5, "ink")                                  # the burnt side
    for k in range(6):
        s.line([(8 + k * 5, 26), (10 + k * 5, 16)], "earth")
    return _finish(s, "gold", {"amber"})


def well() -> Spr:
    s = Spr(36, 44)
    s.ellipse(18, 32, 14, 8, "stone")
    s.ellipse(18, 30, 10, 5, "void")
    s.rect(4, 32, 32, 40, "stone")
    s.line([(4, 36), (32, 36)], "stone_dk")
    s.rect(6, 6, 8, 32, "earth_dk")
    s.rect(28, 6, 30, 32, "earth_dk")
    s.poly([(2, 8), (18, 0), (34, 8)], "rust")
    s.line([(18, 8), (18, 26)], "stone_lt")
    return _finish(s, "pale", {"stone"})


def lamp_shrine() -> Spr:
    """A roadside Lamplighter shrine: a stone niche where travellers left oil. Teague left a note."""
    s = Spr(32, 46)
    s.poly([(4, 44), (6, 10), (16, 2), (26, 10), (28, 44)], "stone")
    s.poly([(4, 44), (6, 10), (12, 5), (10, 44)], "stone_dk")
    s.rect(10, 14, 22, 28, "void")
    s.ellipse(16, 24, 3, 3, "ember_dk")
    s.rect(18, 30, 24, 36, "bone")
    s.line([(19, 32), (23, 32)], "stone")
    s.ellipse(16, 8, 3, 3, "amber", glow=True)
    return _finish(s, "pale", {"stone"})


# ------------------------------------------------------------------ Moth Hollow
def stalagmite(w: int, h: int, seed: int) -> Spr:
    rnd = random.Random(seed)
    s = Spr(w, h)
    pts = [(2, h - 2), (w * 0.3, h * 0.4), (w * 0.45, 3), (w * 0.6, h * 0.35), (w - 2, h - 2)]
    dither_fill(s, pts, "stone_dk", "stone", 0.18, seed)
    s.poly([(w * 0.3, h * 0.4), (w * 0.45, 3), (w * 0.5, h * 0.45), (w * 0.4, h - 2), (2, h - 2)], "ink")
    for _ in range(3):
        y = rnd.uniform(h * 0.4, h * 0.9)
        s.line([(w * 0.35, y), (w * 0.62, y + 2)], "stone_lt")
    return _finish(s, "mist", {"stone"})


def cocoon_pod(seed: int) -> Spr:
    """A moth cocoon on the cave floor: pale silk, something faintly lit inside."""
    rnd = random.Random(seed)
    s = Spr(30, 40)
    s.ellipse(15, 22, 10, 16, "pale")
    s.ellipse(17, 22, 6, 12, "mist")
    for k in range(5):
        y = 10 + k * 6
        s.line([(6, y), (24, y + rnd.uniform(-2, 2))], "bone")
    s.ellipse(15, 24, 3, 5, "amber", glow=True)
    s.line([(15, 6), (14, 0)], "pale")
    return _finish(s, "bone", {"pale"})


def silk_web() -> Spr:
    """Silk strung between two stones: the Matron's road markers."""
    s = Spr(56, 40)
    s.ellipse(6, 32, 5, 6, "stone_dk")
    s.ellipse(50, 30, 5, 7, "stone_dk")
    for k in range(6):
        s.line([(8, 28 - k * 3), (48, 26 - k * 2.5)], "pale")
    for k in range(4):
        x = 14 + k * 9
        s.line([(x, 14), (x + 2, 30)], "mist")
    return _finish(s, "bone", {"stone_dk"})


def hedge(seed: int) -> Spr:
    """A burnt bramble hedgerow: black thorny mass, a few embers still alive in it. Nothing walks through."""
    rnd = random.Random(seed)
    s = Spr(44, 36)
    for _ in range(9):
        x, y = rnd.uniform(8, 36), rnd.uniform(12, 28)
        s.ellipse(x, y, rnd.uniform(5, 9), rnd.uniform(4, 7), rnd.choice(["ink", "ember_dk", "night"]))
    for _ in range(10):
        x, y = rnd.uniform(4, 40), rnd.uniform(6, 30)
        a = rnd.uniform(0, math.tau)
        s.line([(x, y), (x + math.cos(a) * 5, y + math.sin(a) * 4)], "earth_dk")
    for _ in range(3):
        s.px(rnd.uniform(10, 34), rnd.uniform(10, 26), "ember", glow=True)
    return _finish(s, "rust", {"ember_dk"})


def boat() -> Spr:
    """A ferry punt tied up at the bank, its lantern pole bent: the river took it halfway into the sky once."""
    s = Spr(80, 36)
    s.poly([(4, 18), (76, 18), (70, 30), (10, 30)], "earth")
    s.poly([(4, 18), (76, 18), (74, 21), (6, 21)], "earth_lt")
    for x in range(14, 70, 12):
        s.line([(x, 21), (x, 29)], "earth_dk")
    s.line([(64, 18), (70, 2), (76, 4)], "stone_lt")
    s.rect(72, 4, 76, 10, "ink")
    s.rect(73, 5, 75, 9, "glass_lt", glow=True)
    return _finish(s, "earth_lt", {"earth"})


def dock() -> Spr:
    s = Spr(64, 40)
    for x in range(4, 60, 8):
        s.rect(x, 10, x + 7, 30, "earth" if (x // 8) % 2 else "earth_lt")
        s.line([(x + 7, 10), (x + 7, 30)], "earth_dk")
    for x in (6, 56):
        s.rect(x, 4, x + 3, 38, "earth_dk")
    return _finish(s, "earth_lt", {"earth"})


def rising_drops(seed: int) -> Spr:
    """Water falling up from a pool: a column of drops, the river's strangeness in one picture."""
    rnd = random.Random(seed)
    s = Spr(28, 72)
    for _ in range(26):
        x, y = rnd.uniform(6, 22), rnd.uniform(4, 64)
        s.ellipse(x, y, 1, rnd.choice([1, 2]), rnd.choice(["glass_lt", "glint", "glass"]), glow=rnd.random() < 0.4)
    s.ellipse(14, 66, 10, 3, "glass")
    return s


def pillar(seed: int) -> Spr:
    """A broken column standing out of the flood, weed to the waterline."""
    rnd = random.Random(seed)
    s = Spr(30, 72)
    h = rnd.randint(40, 66)
    s.rect(7, 72 - h, 22, 70, "stone")
    s.rect(7, 72 - h, 10, 70, "stone_dk")
    s.rect(18, 72 - h, 20, 70, "stone_lt")
    s.poly([(6, 72 - h), (23, 72 - h), (20, 72 - h - 6), (11, 72 - h - 3)], "stone_lt")
    s.rect(5, 58, 24, 70, "moss_dk")
    s.line([(5, 58), (24, 58)], "moss_lt")
    return _finish(s, "pale", {"stone_lt", "stone"})


def bell_frame() -> Spr:
    """A belfry frame fallen out of its tower: two posts, a beam, a cracked bell still hanging."""
    s = Spr(44, 76)
    for x in (4, 36):
        s.rect(x, 10, x + 4, 74, "earth_dk")
    s.rect(2, 8, 42, 13, "earth")
    s.line([(22, 13), (22, 20)], "stone_dk")
    s.poly([(12, 44), (14, 26), (22, 20), (30, 26), (32, 44)], "earth")
    s.poly([(12, 44), (14, 26), (18, 22), (17, 44)], "earth_dk")
    s.rect(10, 43, 34, 46, "earth_lt")
    s.line([(24, 24), (20, 40)], "ink")                          # the crack
    s.ellipse(22, 46, 3, 2, "stone")
    return _finish(s, "gold", {"earth"})


def lectern_note() -> Spr:
    s = Spr(24, 40)
    s.rect(10, 16, 13, 38, "stone_dk")
    s.rect(4, 36, 19, 39, "stone_dk")
    s.poly([(1, 16), (23, 16), (21, 8), (3, 8)], "stone")
    s.poly([(4, 15), (20, 15), (18, 9), (6, 9)], "bone")
    s.line([(7, 12), (17, 11)], "rust")
    return _finish(s, "pale", {"stone"})


def clock_post() -> Spr:
    """A street clock on an iron post, stopped at four. Every clock in Hollin's Ford says four."""
    s = Spr(28, 80)
    s.rect(12, 26, 15, 78, "stone_dk")
    s.rect(7, 74, 20, 78, "stone")
    s.ellipse(14, 16, 11, 11, "ink")
    s.ellipse(14, 16, 9, 9, "bone")
    s.line([(14, 16), (14, 9)], "ink")
    s.line([(14, 16), (19, 19)], "ink")
    s.rect(4, 4, 24, 6, "stone_dk")
    return _finish(s, "pale", {"stone_dk"})


MANIFEST: dict[str, dict] = {
    "clock_post": {"draw": clock_post, "foot": [10, 6]},
    "pillar_a": {"draw": lambda: pillar(91), "foot": [16, 8]},
    "pillar_b": {"draw": lambda: pillar(92), "foot": [16, 8]},
    "bell_frame": {"draw": bell_frame, "foot": [36, 10]},
    "lectern_note": {"draw": lectern_note, "foot": [16, 8]},
    "boat": {"draw": boat, "foot": [0, 0]},
    "dock": {"draw": dock, "foot": [0, 0]},
    "rising_drops": {"draw": lambda: rising_drops(81), "foot": [0, 0], "light": "glass_lt"},
    "hedge_a": {"draw": lambda: hedge(61), "foot": [30, 10]},
    "hedge_b": {"draw": lambda: hedge(62), "foot": [30, 10]},
    "road_gate": {"draw": road_gate, "foot": [0, 0]},
    "cave_mouth": {"draw": cave_mouth, "foot": [0, 0]},
    "scarecrow": {"draw": scarecrow, "foot": [10, 6]},
    "farmhouse": {"draw": farmhouse, "foot": [104, 30]},
    "haystack": {"draw": haystack, "foot": [36, 12]},
    "well": {"draw": well, "foot": [28, 12]},
    "lamp_shrine": {"draw": lamp_shrine, "foot": [22, 8]},
    "stalagmite_a": {"draw": lambda: stalagmite(28, 52, 31), "foot": [18, 8]},
    "stalagmite_b": {"draw": lambda: stalagmite(40, 76, 32), "foot": [24, 10]},
    "cocoon_pod": {"draw": lambda: cocoon_pod(33), "foot": [16, 8], "light": "amber"},
    "silk_web": {"draw": silk_web, "foot": [0, 0]},
}
