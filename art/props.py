"""Props of the Glasswood and Tallow's wall. Every prop is drawn so its ground contact sits on the bottom-centre
anchor; MANIFEST gives each one's canvas, frames and collision footprint (written to game/data/props.json, which the
zone generator and the layout check read: one source of truth for what a prop occupies)."""
from __future__ import annotations

import math
import random

from pix import Spr, dither_fill


def _finish(s: Spr, rim: str = "mist", only: set[str] | None = None) -> Spr:
    s.outline()
    s.recolor_edge(0, -1, rim, only=only)
    return s


# ------------------------------------------------------------------ glass trees
def _prism(s: Spr, base: tuple[float, float], ang: float, length: float, width: float, cols: tuple[str, str, str]) -> None:
    """One crystal: a long hexagonal prism pointing along ang (radians, 0 = up)."""
    dx, dy = math.sin(ang), -math.cos(ang)
    nx, ny = -dy, dx
    bx, by = base
    tip = (bx + dx * length, by + dy * length)
    shoulder = (bx + dx * length * 0.75, by + dy * length * 0.75)
    pts = [(bx + nx * width, by + ny * width), (shoulder[0] + nx * width, shoulder[1] + ny * width), tip,
           (shoulder[0] - nx * width, shoulder[1] - ny * width), (bx - nx * width, by - ny * width)]
    s.poly(pts, cols[1])
    s.poly([pts[0], pts[1], tip, (bx + dx * length * 0.7, by + dy * length * 0.7)], cols[0])
    s.line([(bx + nx * 0.5, by + ny * 0.5), (tip[0], tip[1])], cols[2])


def glass_tree(w: int, h: int, seed: int) -> Spr:
    rnd = random.Random(seed)
    s = Spr(w, h)
    cx, ground = w / 2, h - 3
    s.poly([(cx - 4, ground), (cx + 4, ground), (cx + 2, ground - h * 0.45), (cx - 2, ground - h * 0.45)], "glass_dp")
    s.line([(cx - 1, ground), (cx - 1, ground - h * 0.45)], "glass_dk")
    for k in range(3):                                          # roots of glass running into the moss
        a = (-1, 1, 0.3)[k]
        s.line([(cx, ground - 2), (cx + a * 8, ground)], "glass_dp", width=2)
    crown = ground - h * 0.40
    shards = []
    for _ in range(int(w * 0.6)):
        ang = rnd.uniform(-1.25, 1.25)
        length = rnd.uniform(h * 0.18, h * 0.42) * (1.0 - abs(ang) * 0.3)
        off = (rnd.uniform(-w * 0.12, w * 0.12), rnd.uniform(-h * 0.08, h * 0.06))
        shards.append((ang, length, off))
    shards.sort(key=lambda t: -t[1])
    for ang, length, off in shards:
        cols = rnd.choice([("glass_dp", "glass_dk", "glass"), ("glass_dk", "glass", "glass_lt"), ("glass", "glass_lt", "glint")])
        _prism(s, (cx + off[0], crown + off[1]), ang, length, rnd.uniform(2.0, 3.6), cols)
    s.outline()
    s.recolor_edge(0, -1, "glint", only={"glass", "glass_lt"})
    for _ in range(4):                                           # a few glints catch any light (emissive)
        x, y = rnd.randrange(w), rnd.randrange(int(h * 0.1), int(h * 0.6))
        if s.opaque(x, y) and s.color_at(x, y)[:3] != (11, 10, 18):
            s.px(x, y, "glint", glow=True)
    return s


def dead_tree(seed: int) -> Spr:
    """An ordinary dead oak the glass has half taken: black branches, glass at the tips."""
    rnd = random.Random(seed)
    s = Spr(72, 104)
    cx, ground = 36, 101
    s.poly([(cx - 5, ground), (cx + 5, ground), (cx + 3, 50), (cx - 2, 50)], "earth_dk")
    s.line([(cx + 2, ground), (cx + 1, 52)], "earth")

    def branch(x: float, y: float, ang: float, length: float, depth: int) -> None:
        ex, ey = x + math.sin(ang) * length, y - math.cos(ang) * length
        s.line([(x, y), (ex, ey)], "earth_dk", width=max(1, depth))
        if depth <= 1:
            _prism(s, (ex, ey), ang, rnd.uniform(5, 9), 1.6, ("glass_dk", "glass", "glass_lt"))
            return
        for d in (-0.5, 0.45):
            branch(ex, ey, ang + d + rnd.uniform(-0.2, 0.2), length * 0.7, depth - 1)

    for a in (-0.7, -0.15, 0.5):
        branch(cx, 54, a, 20, 3)
    return _finish(s, "earth_lt", {"earth_dk"})


def crystal(w: int, h: int, seed: int) -> Spr:
    rnd = random.Random(seed)
    s = Spr(w, h)
    for k in range(5):
        ang = rnd.uniform(-0.7, 0.7)
        _prism(s, (w / 2 + rnd.uniform(-w * 0.2, w * 0.2), h - 3), ang, rnd.uniform(h * 0.4, h * 0.85), rnd.uniform(2, 3.5),
               ("glass_dk", "glass", "glint") if k % 2 else ("glass", "glass_lt", "glint"))
    s.outline()
    s.px(w / 2, h * 0.4, "glint", glow=True)
    return s


def rock(w: int, h: int, seed: int) -> Spr:
    rnd = random.Random(seed)
    s = Spr(w, h)
    pts = [(2, h - 2), (3, h * 0.5), (w * 0.3, 3), (w * 0.7, 2 + rnd.random() * 2), (w - 3, h * 0.45), (w - 2, h - 2)]
    dither_fill(s, pts, "stone", "stone_dk", 0.18, seed)
    s.poly([(3, h * 0.5), (w * 0.3, 3), (w * 0.7, 3), (w * 0.5, h * 0.45)], "stone_lt")
    s.line([(w * 0.5, h * 0.45), (w * 0.55, h - 3)], "stone_dk")
    s.poly([(2, h - 2), (w - 2, h - 2), (w - 3, h - 5), (3, h - 5)], "moss_lt")
    return _finish(s, "pale", {"stone_lt"})


# ------------------------------------------------------------------ buildings and set-pieces
def hut() -> Spr:
    """The woodcutter's hut: a log cabin, shingle roof, a dark door; glass creeping up the east corner."""
    s = Spr(112, 96)
    s.rect(14, 46, 98, 92, "earth")
    for y in range(48, 92, 5):
        s.line([(14, y), (98, y)], "earth_dk")
        s.line([(14, y + 1), (98, y + 1)], "earth_lt")
    s.rect(14, 46, 17, 92, "earth_dk")
    s.rect(95, 46, 98, 92, "earth_dk")
    s.poly([(6, 50), (56, 10), (106, 50)], "rust")
    for k in range(6):
        y = 18 + k * 6
        x0, x1 = 56 - (y - 10) * 1.25, 56 + (y - 10) * 1.25
        s.line([(x0, y), (x1, y)], "ember_dk")
    s.poly([(6, 50), (56, 10), (60, 13), (14, 50)], "ember")
    s.rect(30, 6, 36, 22, "stone_dk")                                  # chimney
    s.rect(30, 6, 36, 7, "stone")
    s.rect(48, 62, 64, 92, "void")                                     # door
    s.rect(46, 60, 66, 61, "earth_dk")
    s.px(61, 77, "amber")
    s.rect(24, 60, 36, 70, "ink")                                      # window (dark: nobody home)
    s.line([(30, 60), (30, 70)], "earth_dk")
    s.line([(24, 65), (36, 65)], "earth_dk")
    s.rect(76, 60, 88, 70, "ink")
    s.line([(82, 60), (82, 70)], "earth_dk")
    for k in range(6):                                                 # glass taking the east corner
        _prism(s, (92 - k * 3, 92 - k * 4), 0.25 - k * 0.12, 10 + k * 3, 2.5, ("glass_dk", "glass", "glint"))
    s.outline()
    s.recolor_edge(0, -1, "flame", only={"ember", "rust"})
    s.px(88, 70, "glint", glow=True)
    return s


def woodpile() -> Spr:
    s = Spr(36, 24)
    for row, n in ((0, 4), (1, 3), (2, 2)):
        for k in range(n):
            x = 5 + k * 7 + row * 3.5
            y = 19 - row * 6
            s.ellipse(x, y, 3.5, 3, "earth")
            s.ellipse(x, y, 2, 1.5, "earth_lt")
            s.px(x, y, "earth_dk")
    return _finish(s, "earth_lt", {"earth"})


def stump() -> Spr:
    s = Spr(28, 26)
    s.rect(6, 12, 20, 23, "earth")
    s.ellipse(13, 12, 7, 3, "earth_lt")
    s.ellipse(13, 12, 4, 1.5, "earth")
    s.line([(14, 11), (19, 2)], "earth_dk", width=2)                 # the axe, left where it was
    s.poly([(17, 0), (23, 1), (22, 6), (18, 4)], "stone_lt")
    s.line([(4, 23), (22, 23)], "earth_dk")
    return _finish(s)


def chest(opened: bool) -> Spr:
    s = Spr(30, 26)
    s.rect(3, 11, 26, 23, "earth")
    s.rect(3, 15, 26, 16, "earth_dk")
    s.rect(3, 11, 5, 23, "stone_dk")
    s.rect(24, 11, 26, 23, "stone_dk")
    if opened:
        s.rect(3, 4, 26, 9, "earth_dk")
        s.rect(5, 9, 24, 12, "void")
        s.rect(8, 10, 21, 11, "gold", glow=True)
    else:
        s.poly([(3, 11), (5, 6), (24, 6), (26, 11)], "earth_lt")
        s.rect(13, 10, 16, 14, "amber")
        s.px(14, 12, "ink")
    return _finish(s, "earth_lt", {"earth"})


def waylamp(lit: bool) -> Spr:
    """An iron way-lamp on a post: the Lamplighters' old road. Lit, it holds back the Dusk around it."""
    s = Spr(28, 76)
    s.rect(12, 18, 15, 72, "stone_dk")
    s.rect(13, 18, 13, 72, "stone")
    s.rect(8, 69, 19, 73, "stone")
    s.line([(14, 18), (14, 12)], "stone_dk")
    s.poly([(7, 10), (14, 4), (21, 10)], "ink")
    s.rect(8, 10, 20, 22, "ink")
    if lit:
        s.rect(9, 11, 19, 21, "amber", glow=True)
        s.rect(11, 13, 17, 19, "gold", glow=True)
        s.rect(13, 14, 15, 18, "sun", glow=True)
    else:
        s.rect(9, 11, 19, 21, "glass_dp")
        s.line([(10, 12), (13, 15)], "glass_dk")
    s.line([(14, 10), (14, 22)], "ink")
    s.rect(9, 23, 19, 24, "stone_dk")
    return _finish(s, "stone_lt", {"stone_dk"})


def menhir(seed: int) -> Spr:
    rnd = random.Random(seed)
    s = Spr(28, 52)
    lean = rnd.uniform(-2, 2)
    pts = [(5, 49), (4 + lean, 14), (9 + lean, 3), (18 + lean, 2), (23 + lean, 12), (23, 49)]
    dither_fill(s, pts, "stone", "stone_dk", 0.15, seed)
    s.poly([(4 + lean, 14), (9 + lean, 3), (12 + lean, 4), (9 + lean, 49), (5, 49)], "stone_dk")
    s.ellipse(15 + lean / 2, 22, 4, 4, "stone_dk")                      # the old sun-mark carved by Lamplighters
    s.ellipse(15 + lean / 2, 22, 2, 2, "amber", glow=True)
    s.poly([(4, 49), (24, 49), (23, 45), (5, 45)], "moss_lt")
    return _finish(s, "pale", {"stone"})


def tower() -> Spr:
    """A ruined watchtower: a stone drum with the wooden lookout above it broken and glassed over."""
    s = Spr(96, 128)
    s.rect(18, 50, 78, 124, "stone")
    for y in range(54, 124, 8):
        off = 0 if (y // 8) % 2 else 6
        for x in range(18 + off, 78, 12):
            s.rect(x, y, x + 10, y + 6, "stone_lt" if (x + y) % 3 else "stone")
            s.line([(x, y + 7), (x + 11, y + 7)], "stone_dk")
    s.rect(18, 50, 24, 124, "stone_dk")
    s.rect(40, 92, 56, 124, "void")                                     # doorway
    s.poly([(40, 92), (48, 84), (56, 92)], "void")
    s.rect(14, 44, 82, 52, "stone_dk")
    for x in (16, 30, 64, 76):                                          # broken posts of the lookout
        s.rect(x, 18 + (x % 7), x + 3, 44, "earth_dk")
    s.line([(16, 26), (79, 30)], "earth", width=2)
    for k in range(5):
        _prism(s, (30 + k * 9, 44), -0.4 + k * 0.2, 14 + (k % 2) * 8, 3, ("glass_dk", "glass", "glint"))
    s.outline()
    s.recolor_edge(0, -1, "pale", only={"stone_lt", "stone"})
    return s


def statue_fisher() -> Spr:
    """Old Brennick, the woodcutter, turned to glass where he sat fishing. The line still hangs in the water."""
    s = Spr(48, 48)
    s.rect(8, 34, 26, 44, "earth_dk")                                   # the crate he sits on
    s.line([(8, 39), (26, 39)], "earth")
    s.poly([(10, 34), (24, 34), (22, 18), (12, 18)], "glass")
    s.poly([(10, 34), (15, 34), (14, 18), (12, 18)], "glass_dk")
    s.ellipse(17, 14, 5, 5, "glass_lt")
    s.ellipse(17, 10, 6, 2, "glass")                                    # his hat
    s.line([(22, 26), (30, 31)], "glass", width=2)
    s.line([(30, 31), (46, 10)], "glass_lt")                            # rod
    s.line([(46, 10), (46, 44)], "pale")                                # line
    s.line([(14, 34), (14, 44)], "glass_dk", width=2)
    s.line([(21, 34), (24, 44)], "glass_dk", width=2)
    s.outline()
    s.recolor_edge(0, -1, "glint", only={"glass", "glass_lt"})
    s.px(18, 13, "glint", glow=True)
    return s


def statue_deer() -> Spr:
    s = Spr(52, 48)
    s.ellipse(26, 24, 12, 7, "glass")
    s.ellipse(22, 22, 8, 4, "glass_lt")
    for x0, x1 in ((18, 14), (22, 20), (31, 34), (34, 39)):
        s.line([(x0, 28), (x1, 44)], "glass_dk", width=2)
    s.poly([(34, 20), (38, 8), (44, 9), (40, 22)], "glass")
    s.ellipse(41, 9, 4, 3, "glass_lt")
    for d in (-1, 1):
        s.line([(40, 6), (40 + d * 5, 0), (40 + d * 7, 2)], "glass_lt")
    s.outline()
    s.recolor_edge(0, -1, "glint", only={"glass", "glass_lt"})
    s.px(43, 9, "glint", glow=True)
    return s


def cart() -> Spr:
    s = Spr(68, 44)
    s.poly([(6, 18), (60, 14), (62, 30), (8, 34)], "earth")
    s.line([(6, 22), (60, 18)], "earth_dk")
    s.line([(7, 28), (61, 24)], "earth_dk")
    s.poly([(6, 18), (60, 14), (58, 12), (6, 15)], "earth_lt")
    s.ellipse(18, 34, 7, 7, "earth_dk")
    s.ellipse(18, 34, 5, 5, "void")
    s.line([(13, 34), (23, 34)], "earth")
    s.line([(18, 29), (18, 39)], "earth")
    s.poly([(48, 30), (56, 41), (52, 42), (44, 32)], "earth_dk")       # the broken wheel lies apart
    s.rect(22, 6, 32, 14, "earth_lt")                                   # crates of lamp-oil it was hauling
    s.rect(34, 4, 44, 13, "earth")
    s.line([(22, 10), (32, 10)], "earth_dk")
    s.line([(4, 30), (-2, 40)], "earth_dk", width=2)
    return _finish(s, "earth_lt", {"earth"})


def cairn() -> Spr:
    """Teague Morrow's cairn: stones heaped over nothing, his cold lantern on top, a note pinned under it."""
    s = Spr(36, 44)
    for k, (x, y, rx) in enumerate(((18, 38, 14), (16, 31, 11), (19, 25, 8))):
        s.ellipse(x, y, rx, 5, "stone" if k % 2 else "stone_lt")
        s.ellipse(x - 2, y - 1, rx - 4, 2, "stone_lt" if k % 2 else "pale")
    s.rect(15, 9, 22, 21, "ink")
    s.rect(16, 11, 21, 19, "glass_dp")
    s.poly([(14, 9), (18, 5), (23, 9)], "ink")
    s.rect(23, 26, 28, 31, "bone")
    s.line([(24, 28), (27, 28)], "earth_lt")
    return _finish(s, "pale", {"stone"})


def campfire() -> Spr:
    s = Spr(30, 18)
    for a in range(8):
        x = 15 + math.cos(a * math.tau / 8) * 11
        y = 9 + math.sin(a * math.tau / 8) * 5
        s.ellipse(x, y, 2.5, 2, "stone")
    s.line([(9, 9), (21, 10)], "ink", width=2)
    s.line([(11, 12), (20, 7)], "earth_dk", width=2)
    s.px(15, 9, "ember_dk")
    return _finish(s)


def bedroll() -> Spr:
    s = Spr(30, 14)
    s.rect(3, 4, 26, 10, "rust")
    s.rect(3, 4, 8, 10, "bone")
    s.line([(9, 4), (9, 10)], "ember_dk")
    s.line([(18, 4), (18, 10)], "ember_dk")
    return _finish(s)


def signpost() -> Spr:
    s = Spr(36, 44)
    s.rect(16, 10, 19, 42, "earth_dk")
    s.poly([(4, 10), (28, 10), (33, 14), (28, 18), (4, 18)], "earth")
    s.line([(7, 14), (24, 14)], "earth_dk")
    s.poly([(30, 21), (8, 21), (3, 25), (8, 29), (30, 29)], "earth")
    s.line([(10, 25), (27, 25)], "earth_dk")
    return _finish(s, "earth_lt", {"earth"})


def reeds(seed: int) -> Spr:
    rnd = random.Random(seed)
    s = Spr(20, 22)
    for _ in range(6):
        x = rnd.uniform(4, 16)
        _prism(s, (x, 20), rnd.uniform(-0.4, 0.4), rnd.uniform(8, 17), 1.0, ("glass_dk", "glass", "glass_lt"))
    s.outline()
    return s


def bridge(part: str) -> Spr:
    """A 32x32 plank tile; bridges run west-east, three tiles tall: north rail, deck, south rail."""
    s = Spr(32, 32)
    for x in range(0, 32, 8):
        s.rect(x, 0, x + 7, 31, "earth" if (x // 8) % 2 else "earth_lt")
        s.line([(x + 7, 0), (x + 7, 31)], "earth_dk")
        s.px(x + 2, 6, "earth_dk")
        s.px(x + 3, 25, "earth_dk")
    if part == "north":
        s.rect(0, 0, 31, 4, "earth_dk")
        s.rect(0, 1, 31, 2, "earth_lt")
    if part == "south":
        s.rect(0, 26, 31, 31, "earth_dk")
        s.rect(0, 27, 31, 28, "earth")
    return s


def wall() -> Spr:
    """A 96 px section of Tallow's outer wall: big dark blocks, soot streaks, a walkway lip at the top."""
    s = Spr(96, 112)
    s.rect(0, 14, 95, 111, "stone")
    for row, y in enumerate(range(16, 112, 12)):
        off = 0 if row % 2 else 12
        for x in range(-12 + off, 96, 24):
            s.rect(x + 1, y + 1, x + 22, y + 10, "stone_lt" if (x + y) % 5 else "stone")
            s.line([(x, y + 11), (x + 23, y + 11)], "stone_dk")
            s.line([(x + 23, y), (x + 23, y + 11)], "stone_dk")
    for x in (14, 58, 80):
        s.line([(x, 20), (x + 2, 70)], "stone_dk", width=3)               # soot
    s.rect(0, 4, 95, 14, "stone_dk")
    for x in range(0, 96, 16):
        s.rect(x, 0, x + 9, 6, "stone_dk")                                 # crenels
    s.rect(0, 104, 95, 111, "moss_dk")
    return s


def gate() -> Spr:
    s = Spr(128, 112)
    base = wall()
    s.img.paste(base.img, (0, 0))
    s.img.paste(base.img.crop((0, 0, 32, 112)), (96, 0))
    s.rect(40, 40, 88, 111, "void")
    s.ellipse(64, 42, 24, 16, "void")
    for x in range(42, 88, 8):
        s.line([(x, 30), (x, 92)], "stone_dk", width=2)                   # the raised portcullis bars
    s.rect(40, 88, 88, 92, "stone_dk")
    s.rect(36, 30, 40, 111, "stone_dk")
    s.rect(88, 30, 92, 111, "stone_dk")
    s.rect(58, 18, 70, 28, "ink")
    s.rect(60, 20, 68, 26, "amber", glow=True)                             # the gate lamp
    s.rect(62, 21, 66, 25, "sun", glow=True)
    return s


def note() -> Spr:
    """A page pinned to a stake: optional lore, readable from the path."""
    s = Spr(18, 26)
    s.line([(9, 25), (9, 8)], "earth_dk", width=2)
    s.poly([(2, 3), (15, 2), (16, 13), (3, 14)], "bone")
    s.line([(4, 6), (13, 5)], "stone")
    s.line([(4, 9), (12, 8)], "stone")
    s.px(9, 3, "rust")
    return _finish(s, "sun", {"bone"})


def cocoon(broken: bool) -> Spr:
    """Nim, held in a shell of glass by the Glazier. Broken: shards on the ground and nobody inside."""
    s = Spr(44, 60)
    if broken:
        for k in range(7):
            _prism(s, (6 + k * 5, 57), -0.9 + k * 0.3, 6 + (k % 3) * 3, 2, ("glass_dk", "glass", "glint"))
        s.outline()
        return s
    s.ellipse(22, 34, 15, 24, "glass_dk")
    s.ellipse(22, 34, 12, 21, "glass")
    s.ellipse(22, 22, 4, 4, "skin_lt")                                # a small figure curled inside
    s.rect(18, 26, 26, 44, "moss_lt")
    s.rect(17, 19, 27, 21, "glass_dk")
    s.line([(12, 18), (16, 50)], "glint", glow=True)
    s.line([(30, 14), (32, 30)], "glass_lt")
    for k in range(4):
        _prism(s, (10 + k * 8, 58), -0.5 + k * 0.33, 10 + (k % 2) * 6, 2.5, ("glass_dk", "glass_lt", "glint"))
    s.outline()
    s.recolor_edge(0, -1, "glint", only={"glass_dk"})
    return s


MANIFEST: dict[str, dict] = {
    # name: canvas, footprint (w, h) centred on the bottom anchor, emits light?, frames
    "tree_a": {"draw": lambda: glass_tree(64, 96, 1), "foot": [10, 8]},
    "tree_b": {"draw": lambda: glass_tree(80, 116, 2), "foot": [12, 8]},
    "tree_c": {"draw": lambda: glass_tree(56, 80, 3), "foot": [10, 8]},
    "tree_dead": {"draw": lambda: dead_tree(4), "foot": [10, 8]},
    "crystal": {"draw": lambda: crystal(32, 32, 5), "foot": [16, 8], "light": "glass_lt"},
    "crystal_big": {"draw": lambda: crystal(48, 52, 6), "foot": [26, 10], "light": "glass_lt"},
    "rock_a": {"draw": lambda: rock(28, 20, 7), "foot": [24, 10]},
    "rock_b": {"draw": lambda: rock(36, 26, 8), "foot": [32, 12]},
    "hut": {"draw": hut, "foot": [84, 30]},
    "woodpile": {"draw": woodpile, "foot": [32, 10]},
    "stump": {"draw": stump, "foot": [16, 8]},
    "chest": {"frames": [lambda: chest(False), lambda: chest(True)], "foot": [24, 10]},
    "waylamp": {"frames": [lambda: waylamp(False), lambda: waylamp(True)], "foot": [12, 8]},
    "menhir_a": {"draw": lambda: menhir(10), "foot": [18, 8]},
    "menhir_b": {"draw": lambda: menhir(11), "foot": [18, 8]},
    "tower": {"draw": tower, "foot": [60, 30]},
    "statue_fisher": {"draw": statue_fisher, "foot": [20, 10]},
    "statue_deer": {"draw": statue_deer, "foot": [30, 10]},
    "cart": {"draw": cart, "foot": [56, 14]},
    "cairn": {"draw": cairn, "foot": [26, 10]},
    "campfire": {"draw": campfire, "foot": [24, 10]},
    "bedroll": {"draw": bedroll, "foot": [0, 0]},
    "signpost": {"draw": signpost, "foot": [8, 6]},
    "reeds": {"draw": lambda: reeds(12), "foot": [0, 0]},
    "bridge_north": {"draw": lambda: bridge("north"), "foot": [0, 0], "flat": True},
    "bridge_deck": {"draw": lambda: bridge("deck"), "foot": [0, 0], "flat": True},
    "bridge_south": {"draw": lambda: bridge("south"), "foot": [0, 0], "flat": True},
    "wall": {"draw": wall, "foot": [0, 0]},
    "gate": {"draw": gate, "foot": [0, 0]},
    "note": {"draw": note, "foot": [8, 6]},
    "cocoon": {"frames": [lambda: cocoon(False), lambda: cocoon(True)], "foot": [26, 10]},
}
