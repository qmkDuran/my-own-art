"""World props drawn with the shading toolkit: trees, bushes, rocks, signs, fences, houses, interior furniture,
the Wellspring and the brambles. Each returns a Canvas; build_art.py writes them (and withered twins)."""
from __future__ import annotations

from pix import Canvas

T = 16


def tree() -> Canvas:
    """A round broadleaf tree, 32x40, occupying a 2x2 block (trunk on the lower row)."""
    c = Canvas(32, 40)
    c.part(c.rect(12, 26, 20, 38) | c.ellipse(16, 38, 6, 2), "bark", 2)
    c.fill(c.rect(12, 26, 14, 37), "bark3")
    crown = c.circle(16, 15, 13) | c.circle(8, 20, 7) | c.circle(24, 20, 7) | c.circle(16, 24, 9)
    c.part(crown, "leaf", 3, shade=0.25)
    for cx, cy, r in ((11, 11, 4), (20, 9, 4), (23, 17, 4), (10, 20, 3.5), (17, 18, 4)):
        bump = c.circle(cx, cy, r) & crown
        c.fill(bump & ~c.circle(cx - 1, cy - 1, r - 0.5), "leaf2")
    c.fill(c.circle(10, 9, 2) & crown, "leaf4")
    c.fill(c.circle(19, 7, 1.6) & crown, "leaf4")
    return c.finish()


def pine() -> Canvas:
    """A tall evergreen, 32x40, for the grove's edge."""
    c = Canvas(32, 40)
    c.part(c.rect(14, 30, 18, 39), "bark", 1)
    for top, half, base in ((2, 6, 12), (8, 10, 22), (16, 14, 32)):
        c.part(c.poly([(16, top), (16 - half, base), (16 + half, base)]), "teal", 1, shade=0.3)
    return c.finish()


def bush() -> Canvas:
    c = Canvas(T, T)
    c.part(c.ellipse(8, 9, 7.5, 6.5) | c.circle(5, 7, 4) | c.circle(11, 7, 4), "leaf", 2, gloss=True)
    c.dot(5, 6, "leaf4")
    c.dot(10, 5, "leaf4")
    return c.finish()


def rock() -> Canvas:
    c = Canvas(T, T)
    c.part(c.ellipse(8, 10, 7, 5.5) | c.ellipse(7, 7, 5, 4.5), "stone", 2, gloss=True)
    c.fill(c.rect(9, 9, 12, 10), "stone1")
    return c.finish()


def sign() -> Canvas:
    c = Canvas(T, T)
    c.part(c.rect(7, 9, 9, 16), "bark", 1)
    c.part(c.rect(2, 2, 14, 10), "bark", 3)
    for y in (4, 6):
        c.fill(c.rect(4, y, 12, y + 1), "bark1")
    return c.finish()


def mailbox() -> Canvas:
    c = Canvas(T, 24)
    c.part(c.rect(7, 12, 9, 24), "bark", 1)
    c.part(c.rect(3, 4, 13, 12) | c.ellipse(8, 5, 5, 3), "water", 2, gloss=True)
    c.fill(c.rect(12, 2, 14, 7), "ember2")
    return c.finish()


def fence(mask: int) -> Canvas:
    """A fence cell joined toward its neighbours: mask bits N=1, E=2, S=4, W=8."""
    c = Canvas(T, T)
    if mask & 8:
        c.part(c.rect(0, 6, 8, 8) | c.rect(0, 10, 8, 12), "bark", 3, contour=False)
    if mask & 2:
        c.part(c.rect(8, 6, 16, 8) | c.rect(8, 10, 16, 12), "bark", 3, contour=False)
    if mask & 1:
        c.part(c.rect(7, 0, 9, 8), "bark", 3, contour=False)
    if mask & 4:
        c.part(c.rect(7, 8, 9, 16), "bark", 3, contour=False)
    c.part(c.rect(6, 3, 10, 14), "bark", 3)
    c.fill(c.rect(6, 3, 10, 4), "sand2")
    return c.finish()


ROOFS = {"home": ("ember", 1), "healer": ("teal", 1), "shop": ("plum", 1), "neighbor": ("water", 1)}


def house(kind: str, door_col: int) -> Canvas:
    """A cottage, 64x64: tiled roof with eaves, plaster wall on a stone footing, windows, a door on the wall."""
    c = Canvas(64, 64)
    ramp, base = ROOFS[kind]
    c.part(c.rect(4, 30, 60, 62), "ink", 5, shade=0.12)
    c.fill(c.rect(4, 58, 60, 62), "stone2")
    c.fill(c.rect(4, 58, 60, 59), "stone3")
    for x in (4, 59):
        c.fill(c.rect(x, 30, x + 1, 58), "bark2")
    roof = c.poly([(0, 34), (8, 4), (56, 4), (64, 34)])
    c.part(roof, ramp, base + 1, shade=0.15)
    for y in range(8, 34, 5):
        c.fill(c.rect(0, y, 64, y + 1) & roof, _tone(ramp, base))
    c.fill(c.rect(0, 32, 64, 35) & c.poly([(0, 32), (64, 32), (64, 35), (0, 35)]), _tone(ramp, base - 1))
    c.part(c.rect(46, 0, 52, 12), "stone", 1)
    _door(c, door_col * T)
    for col in range(4):
        if col != door_col and col in (0, 3) or (col != door_col and abs(col - door_col) > 1):
            _window(c, col * T + 3)
    if kind == "healer":
        _emblem(c, 32 if door_col != 2 else 16, 20, "leaf")
    if kind == "shop":
        _awning(c, door_col)
    return c.finish()


def _tone(ramp: str, i: int) -> str:
    from palette import RAMPS
    tones = RAMPS[ramp]
    return tones[max(0, min(i, len(tones) - 1))]


def _door(c: Canvas, x: int) -> None:
    c.part(c.rect(x + 2, 40, x + 14, 58) | c.ellipse(x + 8, 41, 6, 3), "bark", 2)
    c.fill(c.rect(x + 7, 40, x + 8, 58), "bark1")
    c.dot(x + 11, 49, "ember4")
    c.fill(c.rect(x + 1, 58, x + 15, 60), "stone1")


def _window(c: Canvas, x: int) -> None:
    c.part(c.rect(x, 40, x + 10, 50), "bark", 1)
    c.fill(c.rect(x + 1, 41, x + 9, 49), "water3")
    c.fill(c.rect(x + 1, 41, x + 4, 44), "sky")
    c.fill(c.rect(x + 5, 41, x + 5, 49) | c.rect(x + 1, 45, x + 9, 46), "bark1")
    c.fill(c.rect(x - 1, 50, x + 11, 52), "bark3")
    c.fill(c.rect(x, 52, x + 10, 54), "leaf2")
    for k in range(0, 10, 3):
        c.dot(x + k + 1, 52, "rose2")


def _emblem(c: Canvas, x: int, y: int, kind: str) -> None:
    c.part(c.circle(x, y, 6), "ink", 5)
    c.part(c.leaf(x - 3, y + 3, x + 3, y - 3, 2.5), "leaf", 3, contour=False)


def _awning(c: Canvas, door_col: int) -> None:
    for i, x in enumerate(range(6, 58, 6)):
        c.part(c.rect(x, 34, x + 6, 39), "ember" if i % 2 else "ink", 3 if i % 2 else 5, contour=False)


# --- interiors -----------------------------------------------------------------------------------------------
def wall() -> Canvas:
    """Interior back wall, 16x32: plaster above a wooden wainscot."""
    c = Canvas(T, 32)
    c.fill(c.rect(0, 0, T, 20), "paper")
    c.fill(c.rect(0, 0, T, 2), "bark1")
    for x in (4, 12):
        c.fill(c.rect(x, 6, x + 1, 7), "fog")
    c.fill(c.rect(0, 20, T, 32), "bark2")
    c.fill(c.rect(0, 20, T, 22), "bark3")
    c.fill(c.rect(0, 31, T, 32), "bark0")
    for x in (0, 8):
        c.fill(c.rect(x, 22, x + 1, 31), "bark1")
    return c


def wall_window() -> Canvas:
    c = wall()
    c.part(c.rect(3, 5, 13, 16), "bark", 1, contour=False)
    c.fill(c.rect(4, 6, 12, 15), "water4")
    c.fill(c.rect(4, 6, 7, 9), "sky")
    c.fill(c.rect(8, 6, 8, 15) | c.rect(4, 10, 12, 11), "bark1")
    return c


def bed() -> Canvas:
    c = Canvas(T, 32)
    c.part(c.rect(1, 2, 15, 30), "bark", 2)
    c.part(c.rect(2, 4, 14, 10), "ink", 5)
    c.part(c.rect(2, 11, 14, 28), "water", 3)
    c.fill(c.rect(2, 11, 14, 13), "cream")
    return c.finish()


def table() -> Canvas:
    c = Canvas(32, 24)
    for x in (4, 26):
        c.part(c.rect(x, 12, x + 2, 23), "bark", 1)
    c.part(c.rect(1, 4, 31, 15), "bark", 3)
    c.fill(c.rect(10, 6, 16, 10), "cream")
    c.part(c.circle(22, 8, 3), "ember", 3)
    return c.finish()


def shelf() -> Canvas:
    c = Canvas(32, 32)
    c.part(c.rect(1, 0, 31, 31), "bark", 2)
    for y in (8, 18, 28):
        c.fill(c.rect(3, y, 29, y + 2), "bark1")
    cols = ["ember2", "water2", "leaf2", "plum2", "sun", "rose2"]
    for i, x in enumerate(range(4, 28, 4)):
        c.fill(c.rect(x, 2 + (i % 2), x + 3, 8), cols[i % len(cols)])
        c.fill(c.rect(x, 12 + (i % 3), x + 3, 18), cols[(i + 2) % len(cols)])
    c.part(c.ellipse(10, 25, 4, 3), "ember", 3)
    c.part(c.ellipse(22, 25, 4, 3), "stone", 3)
    return c.finish()


def counter() -> Canvas:
    c = Canvas(48, 24)
    c.part(c.rect(0, 6, 48, 23), "bark", 2)
    c.fill(c.rect(0, 6, 48, 9), "sand2")
    for x in range(4, 48, 8):
        c.fill(c.rect(x, 12, x + 1, 22), "bark1")
    return c.finish()


def plant() -> Canvas:
    c = Canvas(T, 24)
    c.part(c.poly([(4, 15), (12, 15), (11, 23), (5, 23)]), "ember", 2)
    for x0, x1, y1 in ((8, 3, 4), (8, 13, 5), (8, 8, 1), (8, 2, 11), (8, 14, 11)):
        c.part(c.leaf(8, 15, x1, y1, 2.5), "leaf", 3)
    return c.finish()


def rug() -> Canvas:
    c = Canvas(32, 16)
    c.part(c.ellipse(16, 8, 15, 7), "rose", 1, light=False)
    c.fill(c.ellipse(16, 8, 11, 4.5), "rose2")
    c.fill(c.ellipse(16, 8, 6, 2), "sun")
    return c


def basin() -> Canvas:
    """The mender's spring basin: a stone bowl of glowing water."""
    c = Canvas(32, 24)
    c.part(c.ellipse(16, 14, 15, 9), "stone", 2)
    c.fill(c.ellipse(16, 12, 11, 5), "water3")
    c.fill(c.ellipse(13, 11, 4, 1.5), "sky")
    return c.finish()


def stove() -> Canvas:
    c = Canvas(T, 32)
    c.part(c.rect(1, 8, 15, 31), "stone", 1)
    c.part(c.rect(5, 0, 11, 9), "stone", 1)
    c.fill(c.rect(4, 18, 12, 26), "ember1")
    c.fill(c.rect(5, 21, 11, 26), "ember3")
    c.fill(c.rect(6, 23, 10, 26), "sun")
    return c.finish()


def mat() -> Canvas:
    c = Canvas(T, T)
    c.fill(c.rect(1, 4, 15, 14), "ember1")
    c.fill(c.rect(2, 5, 14, 13), "ember2")
    for x in range(3, 14, 2):
        c.dot(x, 4, "sand2")
        c.dot(x, 13, "sand2")
    return c


# --- the grove -------------------------------------------------------------------------------------------------
def wellspring() -> Canvas:
    """The Wellspring: a ring of mossy stones around a pool, 48x40 (withers to a dry, cracked bowl)."""
    c = Canvas(48, 40)
    c.part(c.ellipse(24, 24, 23, 15), "stone", 2)
    c.fill(c.ellipse(24, 22, 17, 9), "deep1")
    c.fill(c.ellipse(24, 23, 16, 8), "water2")
    c.fill(c.ellipse(20, 21, 7, 3), "water3")
    c.fill(c.ellipse(18, 20, 3, 1.3), "sky")
    for x, y in ((6, 22), (12, 32), (24, 37), (36, 32), (42, 22), (16, 13), (32, 13)):
        c.part(c.ellipse(x, y, 4, 3), "stone", 3)
        c.fill(c.ellipse(x - 1, y - 2, 2.5, 1.2), "leaf3")
    return c.finish()


def bramble() -> Canvas:
    """A knot of thorny dead vines that blocks a path until the land heals."""
    c = Canvas(T, T)
    for pts in (((1, 14), (6, 6), (12, 2)), ((3, 3), (9, 9), (15, 13)), ((2, 9), (8, 12), (14, 6))):
        c.part(c.taper(list(pts), 1.4, 1.0), "plum", 0, contour=False, light=False)
    for x, y in ((5, 7), (10, 10), (8, 4), (12, 5), (4, 12)):
        c.dot(x, y - 1, "plum2")
        c.dot(x + 1, y, "dusk")
    return c.finish()


def stump() -> Canvas:
    c = Canvas(T, T)
    c.part(c.rect(3, 7, 13, 14) | c.ellipse(8, 14, 5, 1.5), "bark", 2)
    c.part(c.ellipse(8, 7, 5, 2.5), "bark", 4, contour=False)
    c.dot(8, 7, "bark2")
    return c.finish()


def mushrooms() -> Canvas:
    c = Canvas(T, T)
    for x, y, r in ((5, 10, 3), (11, 12, 2.5)):
        c.part(c.rect(x - 1, y, x + 1, y + 4), "ink", 5, contour=False)
        c.part(c.ellipse(x, y, r, r * 0.7), "ember", 2, gloss=True)
        c.dot(x - 1, y - 1, "cream")
    return c.finish()


def shore_rocks() -> Canvas:
    c = Canvas(T, T)
    c.part(c.ellipse(5, 10, 4, 3), "stone", 2)
    c.part(c.ellipse(11, 11, 3.5, 2.5), "stone", 3)
    return c.finish()


def bridge() -> Canvas:
    """Bridge planks over water (drawn on the water cell)."""
    c = Canvas(T, T)
    c.fill(c.rect(0, 1, T, 15), "bark3")
    for x in range(0, T, 4):
        c.fill(c.rect(x, 1, x + 1, 15), "bark2")
    c.fill(c.rect(0, 0, T, 1) | c.rect(0, 15, T, 16), "bark1")
    c.fill(c.rect(0, 1, T, 2), "sand1")
    return c


def bridge_v() -> Canvas:
    c = Canvas(T, T)
    c.fill(c.rect(1, 0, 15, T), "bark3")
    for y in range(0, T, 4):
        c.fill(c.rect(1, y, 15, y + 1), "bark2")
    c.fill(c.rect(0, 0, 1, T) | c.rect(15, 0, 16, T), "bark1")
    return c
