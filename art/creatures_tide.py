"""Tide wildkin: Ripplet, its bond form Rivermane, and Drizzlesnail."""
from __future__ import annotations

from pix import Canvas, blush, eye


def ripplet(c: Canvas, view: str, s: float = 1.0) -> None:
    """An otter pup with a droplet curl on its head; it floats on its back to nap."""
    if view == "back":
        return _ripplet_back(c, s)
    c.part(c.taper([(52 * s, 70 * s), (64 * s, 70 * s), (72 * s, 64 * s)], 4 * s, 2.5 * s), "water", 2)
    c.part(c.ellipse(44 * s, 58 * s, 14 * s, 16 * s), "water", 3)
    c.part(c.ellipse(40 * s, 60 * s, 8 * s, 12 * s), "ink", 5, contour=False)
    for x in (36, 50):
        c.part(c.ellipse(x * s, 74 * s, 5 * s, 3 * s), "water", 2)
    c.part(c.capsule(31 * s, 52 * s, 36 * s, 58 * s, 3 * s), "water", 3)
    c.part(c.capsule(50 * s, 52 * s, 46 * s, 58 * s, 3 * s), "water", 2)
    for x in (24, 46):
        c.part(c.circle(x * s, 26 * s, 4 * s), "water", 2)
        c.fill(c.circle(x * s, 26 * s, 2 * s), "rose2")
    c.part(c.ellipse(35 * s, 35 * s, 14 * s, 12 * s), "water", 3, gloss=True)
    c.part(c.ellipse(32 * s, 41 * s, 9 * s, 6 * s), "ink", 5)
    c.part(c.leaf(36 * s, 25 * s, 30 * s, 12 * s, 4 * s), "water", 4)
    c.fill(c.circle(31 * s, 15 * s, 1.2 * s), "sky")
    c.part(c.ellipse(29 * s, 38 * s, 2.5 * s, 2 * s), "ink", 1, contour=False)
    if s >= 0.6:
        eye(c, round(25 * s), round(31 * s), 5, 4)
        eye(c, round(38 * s), round(31 * s), 5, 4)
        for x in (21, 22, 38, 39):
            c.dot(round(x * s), round(42 * s), "ink2")
        blush(c, round(22 * s), round(37 * s))
        blush(c, round(41 * s), round(37 * s))
    else:
        c.dot(round(26 * s), round(32 * s), "ink")
        c.dot(round(39 * s), round(32 * s), "ink")


def _ripplet_back(c: Canvas, s: float) -> None:
    c.part(c.taper([(30 * s, 72 * s), (16 * s, 72 * s), (8 * s, 64 * s)], 5 * s, 3 * s), "water", 2)
    c.part(c.ellipse(40 * s, 58 * s, 17 * s, 19 * s), "water", 3)
    for x in (30, 60):
        c.part(c.circle(x * s, 22 * s, 4.5 * s), "water", 2)
    c.part(c.ellipse(45 * s, 32 * s, 16 * s, 14 * s), "water", 3, gloss=True)
    c.part(c.leaf(44 * s, 20 * s, 38 * s, 6 * s, 4.5 * s), "water", 4)


def rivermane(c: Canvas, view: str, s: float = 1.0) -> None:
    """Ripplet grown: a long otter whose mane runs like a stream and never quite stops dripping."""
    back = view == "back"
    sx = (lambda x: (80 - x) * s) if back else (lambda x: x * s)
    c.part(c.taper([(sx(58), 66 * s), (sx(70), 70 * s), (sx(77), 60 * s)], 5 * s, 2 * s), "water", 2)
    c.part(c.leaf(sx(74), 62 * s, sx(78), 50 * s, 4 * s), "water", 4, contour=False)
    for x0, base in ((54, 1), (30, 1), (60, 2), (36, 2)):
        c.part(c.capsule(sx(x0), 60 * s, sx(x0 - 1), 75 * s, 3.4 * s), "water", base, contour=base > 1)
    c.part(c.ellipse(sx(46), 56 * s, 20 * s, 11 * s), "water", 2)
    if not back:
        c.part(c.ellipse(sx(36), 60 * s, 12 * s, 6 * s), "ink", 5, contour=False)
    c.part(c.capsule(sx(32), 52 * s, sx(28), 36 * s, 8 * s), "water", 2)
    c.part(c.ellipse(sx(28), 30 * s, 12 * s, 10 * s), "water", 2, gloss=not back)
    for k in range(4):
        c.part(c.leaf(sx(30 + k * 6), (22 + k * 8) * s, sx(44 + k * 6), (30 + k * 8) * s, 5 * s), "water", 3)
        c.fill(c.leaf(sx(32 + k * 6), (22 + k * 8) * s, sx(42 + k * 6), (27 + k * 8) * s, 1.6 * s), "sky")
    c.part(c.leaf(sx(30), 22 * s, sx(36), 6 * s, 4 * s), "water", 4)
    c.part(c.leaf(sx(26), 22 * s, sx(18), 9 * s, 3.4 * s), "water", 3)
    c.fill(c.circle(sx(37), 9 * s, 1.3 * s), "sky")
    if back:
        return
    c.part(c.ellipse(sx(20), 35 * s, 8 * s, 5 * s), "ink", 5)
    c.part(c.ellipse(sx(14), 33 * s, 2.4 * s, 2 * s), "ink", 1, contour=False)
    if s >= 0.6:
        eye(c, round(sx(19)), round(26 * s), 5, 4)
        eye(c, round(sx(30)), round(26 * s), 5, 3)
        blush(c, round(sx(17)), round(32 * s))
    else:
        c.dot(round(sx(20)), round(27 * s), "ink")


def drizzlesnail(c: Canvas, view: str, s: float = 1.0) -> None:
    """A snail carrying its own little rain cloud; its shell rings like a bell when it rains."""
    back = view == "back"
    c.part(c.taper([(22 * s, 66 * s), (44 * s, 70 * s), (66 * s, 70 * s), (76 * s, 73 * s)], 8 * s, 2.5 * s), "teal", 2)
    shell = c.ellipse(48 * s, 52 * s, 20 * s, 19 * s)
    c.part(shell, "water", 2, gloss=True)
    for r, tone in ((14, "water3"), (9, "water2"), (4.5, "water3")):
        ring = c.circle((50 - (14 - r) * 0.25) * s, (53 + (14 - r) * 0.15) * s, r * s) & ~c.circle((50 - (14 - r) * 0.25) * s, (53 + (14 - r) * 0.15) * s, (r - 1.2) * s)
        c.flat(ring & shell, "deep1")
        del tone
    c.part(c.ellipse(46 * s, 22 * s, 12 * s, 6 * s) | c.circle(39 * s, 20 * s, 6 * s) | c.circle(52 * s, 18 * s, 7 * s), "ink", 5)
    for x in (38, 46, 54):
        c.part(c.leaf(x * s, 29 * s, (x - 1) * s, 33 * s, 1.2 * s), "water", 3, contour=False)
    if back:
        return
    c.part(c.ellipse(24 * s, 54 * s, 9 * s, 10 * s), "teal", 3, gloss=True)
    for x0, x1 in ((20, 15), (27, 29)):
        c.part(c.capsule(x0 * s, 46 * s, x1 * s, 36 * s, 1.4 * s), "teal", 2, contour=False)
        c.part(c.circle(x1 * s, 35 * s, 2.6 * s), "teal", 3)
    if s >= 0.6:
        eye(c, round(18 * s), round(51 * s), 5, 3)
        eye(c, round(26 * s), round(51 * s), 5, 3)
        blush(c, round(17 * s), round(58 * s))
        blush(c, round(28 * s), round(58 * s))
    else:
        c.dot(round(20 * s), round(53 * s), "ink")
