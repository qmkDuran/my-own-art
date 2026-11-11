"""Stone and Gale wildkin: Cobblemole and Puffwren."""
from __future__ import annotations

import math

from pix import Canvas, blush, closed_eye, eye


def cobblemole(c: Canvas, view: str, s: float = 1.0) -> None:
    """A stout mole wearing a coat of smooth river stones; it hums while it digs."""
    back = view == "back"
    c.part(c.ellipse(42 * s, 58 * s, 24 * s, 17 * s), "bark", 2)
    plates = [(30, 46, 9), (44, 42, 10), (58, 48, 9), (38, 56, 8), (52, 58, 8)]
    if back:
        plates += [(26, 60, 7), (62, 62, 7), (44, 66, 7)]
    for x, y, r in plates:
        c.part(c.ellipse(x * s, y * s, r * s, r * 0.8 * s), "stone", 2, gloss=True)
    if back:
        for x in (26, 58):
            c.part(c.ellipse(x * s, 74 * s, 7 * s, 3.5 * s), "bark", 1)
        return
    c.part(c.ellipse(26 * s, 62 * s, 12 * s, 10 * s), "bark", 3, gloss=True)
    c.part(c.ellipse(17 * s, 66 * s, 4 * s, 3.2 * s), "rose", 2, gloss=True)
    for x in (22, 40):
        c.part(c.ellipse(x * s, 73 * s, 6 * s, 3.5 * s), "bark", 5)
        for k in range(3):
            c.part(c.capsule((x - 4 + k * 3) * s, 75 * s, (x - 5 + k * 3) * s, 78 * s, 1 * s), "ink", 5, contour=False, light=False)
    if s >= 0.6:
        closed_eye(c, round(21 * s), round(58 * s), 4)
        closed_eye(c, round(30 * s), round(58 * s), 4)
        blush(c, round(20 * s), round(62 * s))
        blush(c, round(31 * s), round(62 * s))
    else:
        c.dot(round(22 * s), round(59 * s), "ink")


def puffwren(c: Canvas, view: str, s: float = 1.0) -> None:
    """A round wren puffed up like a dandelion clock; it rides warm updrafts all day."""
    back = view == "back"
    c.part(c.leaf(56 * s, 52 * s, 72 * s, 40 * s, 5 * s), "teal", 2)
    c.part(c.leaf(56 * s, 54 * s, 74 * s, 50 * s, 4 * s), "teal", 1)
    for x in (36, 46):
        c.part(c.capsule(x * s, 66 * s, (x - 1) * s, 75 * s, 1.2 * s), "ember", 3, contour=False)
    body = c.circle(42 * s, 50 * s, 19 * s)
    c.part(body, "ink", 5, gloss=True)
    for k in range(10):
        a = k * 0.63
        c.part(c.circle((42 + math.cos(a) * 17) * s, (50 + math.sin(a) * 17) * s, 4 * s), "ink", 5, contour=False)
    wx = 44 if not back else 40
    c.part(c.leaf(wx * s, 46 * s, (wx + 20) * s, 60 * s, 7 * s), "teal", 2, gloss=True)
    c.part(c.leaf((wx + 4) * s, 52 * s, (wx + 18) * s, 62 * s, 3 * s), "teal", 1, contour=False)
    c.part(c.leaf(40 * s, 32 * s, 34 * s, 20 * s, 3 * s), "teal", 3)
    c.part(c.leaf(43 * s, 32 * s, 46 * s, 22 * s, 2.5 * s), "teal", 2)
    if back:
        return
    c.part(c.poly([(19 * s, 46 * s), (28 * s, 43 * s), (28 * s, 49 * s)]), "ember", 3)
    if s >= 0.6:
        eye(c, round(28 * s), round(40 * s), 5, 4)
        eye(c, round(38 * s), round(41 * s), 5, 3)
        blush(c, round(27 * s), round(48 * s))
        blush(c, round(39 * s), round(48 * s))
    else:
        c.dot(round(29 * s), round(41 * s), "ink")
