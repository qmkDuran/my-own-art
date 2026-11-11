"""Cinder wildkin: Emberkit, its bond form Hearthfox, and Kindlemoth."""
from __future__ import annotations

from pix import Canvas, blush, eye


def _flame(c: Canvas, s: float, x: float, y: float, h: float, lean: float = 0.0) -> None:
    """A three-tongue flame rising from (x, y)."""
    c.part(c.leaf(x * s, y * s, (x + lean) * s, (y - h) * s, h * 0.42 * s), "ember", 3, contour=False)
    c.part(c.leaf((x + 1) * s, y * s, (x + lean * 0.6 + 4) * s, (y - h * 0.65) * s, h * 0.22 * s), "ember", 4, contour=False)
    c.part(c.leaf((x - 1) * s, y * s, (x + lean * 0.4 - 3) * s, (y - h * 0.55) * s, h * 0.2 * s), "ember", 4, contour=False)
    c.fill(c.leaf(x * s, (y - 1) * s, (x + lean * 0.5) * s, (y - h * 0.4) * s, h * 0.13 * s), "sun")


def emberkit(c: Canvas, view: str, s: float = 1.0) -> None:
    """A sitting fox kit; the tip of its tail is a small, steady flame it warms its paws on."""
    if view == "back":
        return _emberkit_back(c, s)
    c.part(c.taper([(52 * s, 66 * s), (64 * s, 60 * s), (68 * s, 48 * s)], 5 * s, 6 * s), "ember", 2)
    _flame(c, s, 68, 46, 18, 3)
    c.part(c.ellipse(46 * s, 59 * s, 15 * s, 15 * s), "ember", 2)
    c.part(c.ellipse(40 * s, 60 * s, 8 * s, 11 * s), "ink", 5, contour=False)
    for x in (37, 47):
        c.part(c.ellipse(x * s, 73 * s, 4.5 * s, 3 * s), "ink", 5)
    c.part(c.leaf(26 * s, 28 * s, 16 * s, 8 * s, 6 * s), "ember", 2)
    c.part(c.leaf(44 * s, 27 * s, 52 * s, 7 * s, 6 * s), "ember", 1)
    c.fill(c.leaf(26 * s, 26 * s, 19 * s, 12 * s, 2.4 * s), "rose3")
    c.fill(c.circle(16.5 * s, 9.5 * s, 2.5 * s) & c.leaf(26 * s, 28 * s, 16 * s, 8 * s, 6 * s), "bark0")
    c.fill(c.circle(51.5 * s, 8.5 * s, 2.5 * s) & c.leaf(44 * s, 27 * s, 52 * s, 7 * s, 6 * s), "bark0")
    c.part(c.ellipse(35 * s, 35 * s, 14 * s, 12 * s), "ember", 2, gloss=True)
    c.part(c.ellipse(28 * s, 41 * s, 9 * s, 6 * s) | c.poly([(19 * s, 40 * s), (36 * s, 36 * s), (34 * s, 46 * s)]), "ink", 5)
    c.part(c.ellipse(19 * s, 40 * s, 2.5 * s, 2 * s), "ink", 1, contour=False)
    if s >= 0.6:
        eye(c, round(27 * s), round(30 * s), 6, 4)
        eye(c, round(39 * s), round(31 * s), 5, 3)
        blush(c, round(25 * s), round(38 * s))
        blush(c, round(41 * s), round(38 * s))
    else:
        c.dot(round(28 * s), round(31 * s) + 1, "ink")
        c.dot(round(40 * s), round(31 * s) + 1, "ink")


def _emberkit_back(c: Canvas, s: float) -> None:
    c.part(c.ellipse(40 * s, 60 * s, 18 * s, 17 * s), "ember", 2)
    c.part(c.taper([(30 * s, 70 * s), (16 * s, 64 * s), (12 * s, 50 * s)], 6 * s, 7 * s), "ember", 2)
    _flame(c, s, 12, 48, 20, -3)
    c.part(c.leaf(36 * s, 28 * s, 26 * s, 6 * s, 7 * s), "ember", 1)
    c.part(c.leaf(56 * s, 28 * s, 66 * s, 6 * s, 7 * s), "ember", 2)
    c.fill(c.circle(26.5 * s, 7.5 * s, 2.8 * s) & c.leaf(36 * s, 28 * s, 26 * s, 6 * s, 7 * s), "bark0")
    c.fill(c.circle(65.5 * s, 7.5 * s, 2.8 * s) & c.leaf(56 * s, 28 * s, 66 * s, 6 * s, 7 * s), "bark0")
    c.part(c.ellipse(46 * s, 36 * s, 16 * s, 14 * s), "ember", 2, gloss=True)
    c.part(c.ellipse(58 * s, 45 * s, 5 * s, 4 * s), "ink", 5, contour=False)


def hearthfox(c: Canvas, view: str, s: float = 1.0) -> None:
    """Emberkit grown: a tall fox with an ember ruff and a tail like a hearth fire banked for the night."""
    if view == "back":
        return _hearthfox_back(c, s)
    c.part(c.taper([(58 * s, 56 * s), (70 * s, 50 * s), (73 * s, 36 * s)], 6 * s, 7 * s), "ember", 2)
    _flame(c, s, 73, 34, 26, 2)
    for x0, x1, base in ((52, 54, 1), (33, 31, 1), (58, 61, 2), (39, 38, 2)):
        c.part(c.capsule(x0 * s, 56 * s, x1 * s, 75 * s, 3 * s), "ember", base, contour=base > 1)
        c.fill(c.rect((x1 - 4) * s, 72 * s, (x1 + 4) * s, 79 * s) & c.capsule(x0 * s, 56 * s, x1 * s, 75 * s, 3.2 * s), "bark0")
    c.part(c.ellipse(46 * s, 51 * s, 19 * s, 10 * s), "ember", 2)
    c.part(c.ellipse(32 * s, 47 * s, 10 * s, 12 * s), "ember", 3, gloss=True)
    for k in range(4):
        c.part(c.leaf((26 + k * 4) * s, (44 + k) * s, (24 + k * 4) * s, (58 + k) * s, 3 * s), "ember", 4, contour=False)
    c.part(c.leaf(22 * s, 22 * s, 13 * s, 2 * s, 5.5 * s), "ember", 2)
    c.part(c.leaf(38 * s, 21 * s, 46 * s, 1 * s, 5.5 * s), "ember", 1)
    _flame(c, s, 13, 6, 6, -1)
    _flame(c, s, 46, 5, 6, 1)
    c.part(c.ellipse(30 * s, 29 * s, 12 * s, 10 * s), "ember", 2, gloss=True)
    c.part(c.poly([(10 * s, 34 * s), (30 * s, 28 * s), (33 * s, 39 * s), (18 * s, 39 * s)]), "ink", 5)
    c.part(c.ellipse(11 * s, 34 * s, 2.4 * s, 2 * s), "ink", 1, contour=False)
    if s >= 0.6:
        eye(c, round(22 * s), round(25 * s), 5, 4)
        eye(c, round(34 * s), round(26 * s), 5, 3)
    else:
        c.dot(round(23 * s), round(26 * s), "ink")


def _hearthfox_back(c: Canvas, s: float) -> None:
    for x in (28, 54):
        c.part(c.capsule(x * s, 62 * s, x * s, 78 * s, 4 * s), "ember", 1, contour=False)
    c.part(c.ellipse(41 * s, 58 * s, 21 * s, 13 * s), "ember", 2)
    c.part(c.taper([(24 * s, 62 * s), (12 * s, 52 * s), (10 * s, 36 * s)], 7 * s, 8 * s), "ember", 2)
    _flame(c, s, 10, 32, 26, -2)
    c.part(c.ellipse(50 * s, 45 * s, 13 * s, 12 * s), "ember", 3)
    c.part(c.leaf(42 * s, 22 * s, 33 * s, 3 * s, 6 * s), "ember", 1)
    c.part(c.leaf(60 * s, 22 * s, 69 * s, 3 * s, 6 * s), "ember", 2)
    _flame(c, s, 33, 7, 6, -1)
    _flame(c, s, 69, 7, 6, 1)
    c.part(c.ellipse(51 * s, 30 * s, 14 * s, 12 * s), "ember", 2, gloss=True)


def kindlemoth(c: Canvas, view: str, s: float = 1.0) -> None:
    """A fuzzy moth with ember-eyed wings; it hums near lanterns and warm stones."""
    back = view == "back"
    for side in (-1, 1):
        cx = 40 + side * 18
        c.part(c.ellipse(cx * s, 38 * s, 17 * s, 13 * s, angle=side * -25), "ember", 2 if back else 3)
        c.part(c.ellipse((40 + side * 14) * s, 56 * s, 10 * s, 8 * s, angle=side * 30), "ember", 2)
        c.fill(c.circle((cx + side * 3) * s, 36 * s, 5 * s), "ember1")
        c.fill(c.circle((cx + side * 3) * s, 36 * s, 3 * s), "sun")
        c.fill(c.circle((40 + side * 16) * s, 57 * s, 2.5 * s), "cream")
    c.part(c.ellipse(40 * s, 58 * s, 7 * s, 12 * s), "ink", 5)
    for k in range(3):
        c.flat(c.rect(34 * s, (56 + k * 5) * s, 46 * s, (57 + k * 5) * s) & c.ellipse(40 * s, 58 * s, 7 * s, 12 * s), "fog")
    c.part(c.ellipse(40 * s, 40 * s, 10 * s, 9 * s), "ink", 5, gloss=not back)
    for side in (-1, 1):
        c.part(c.taper([((40 + side * 4) * s, 32 * s), ((40 + side * 10) * s, 20 * s), ((40 + side * 16) * s, 16 * s)], 1 * s, 1.2 * s), "bark", 2, contour=False)
        c.part(c.leaf((40 + side * 9) * s, 22 * s, (40 + side * 18) * s, 13 * s, 3 * s), "bark", 3, contour=False)
    if back:
        return
    eye(c, round(33 * s), round(37 * s), 6, 4)
    eye(c, round(43 * s), round(37 * s), 6, 4)
    blush(c, round(32 * s), round(45 * s))
    blush(c, round(45 * s), round(45 * s))
