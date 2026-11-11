"""Bloom wildkin: Mossfawn, its bond form Grovehart, and Thistlehog. Each draw function paints one view
("front" faces the viewer, three-quarter to the left; "back" is seen from behind, three-quarter to the right)."""
from __future__ import annotations

from pix import Canvas, blush, eye


def _fawn_legs(c: Canvas, s: float, back: bool) -> None:
    far = [(50, 56, 52, 73), (31, 56, 30, 73)]
    near = [(56, 57, 59, 74), (37, 57, 37, 74)]
    for x0, y0, x1, y1 in far:
        c.part(c.capsule(x0 * s, y0 * s, x1 * s, y1 * s, 2.2 * s), "bark", 1, contour=False)
    for x0, y0, x1, y1 in near:
        c.part(c.capsule(x0 * s, y0 * s, x1 * s, y1 * s, 2.4 * s), "bark", 3)
    for x0, y0, x1, y1 in far + near:
        hoof = c.rect((x1 - 4) * s, (y1 - 1.5) * s, (x1 + 4) * s, (y1 + 3) * s)
        c.fill(hoof & c.capsule(x0 * s, y0 * s, x1 * s, y1 * s, 2.8 * s), "bark0")


def mossfawn(c: Canvas, view: str, s: float = 1.0) -> None:
    """A fawn whose back is a moss blanket; a sprout grows between its ears."""
    if view == "back":
        return _mossfawn_back(c, s)
    _fawn_legs(c, s, False)
    c.part(c.ellipse(46 * s, 50 * s, 17 * s, 11 * s), "bark", 3)
    c.part(c.ellipse(64 * s, 44 * s, 4 * s, 4 * s), "ink", 5, contour=True)
    c.part(c.ellipse(48 * s, 43 * s, 15 * s, 7 * s) | c.ellipse(57 * s, 45 * s, 7 * s, 5 * s), "leaf", 3, gloss=True)
    for x in (38, 47, 56):
        c.part(c.leaf(x * s, 41 * s, (x + 3) * s, 35 * s, 2.4 * s), "leaf", 4, contour=False)
    for x, y in ((40, 53), (47, 55), (53, 51)):
        c.fill(c.circle(x * s, y * s, 1.4 * s), "sand3")
    c.part(c.capsule(33 * s, 46 * s, 29 * s, 33 * s, 6 * s), "bark", 3)
    c.part(c.leaf(22 * s, 20 * s, 7 * s, 14 * s, 4.2 * s), "bark", 3)
    c.part(c.leaf(34 * s, 20 * s, 47 * s, 12 * s, 4.2 * s), "bark", 2)
    c.fill(c.leaf(23 * s, 20 * s, 10 * s, 15.5 * s, 1.8 * s), "rose3")
    c.part(c.ellipse(28 * s, 27 * s, 10 * s, 9 * s), "bark", 3, gloss=True)
    c.part(c.ellipse(22 * s, 32 * s, 6.5 * s, 4.6 * s), "bark", 5)
    c.part(c.capsule(28 * s, 18 * s, 29 * s, 11 * s, 1 * s), "leaf", 2, contour=False)
    c.part(c.leaf(29 * s, 12 * s, 22 * s, 7 * s, 2.6 * s), "leaf", 3)
    c.part(c.leaf(29 * s, 12 * s, 36 * s, 6 * s, 2.6 * s), "leaf", 4)
    _face(c, s, 22, 22, 16, 31)


def _face(c: Canvas, s: float, ex: int, ey: int, nx: int, ny: int) -> None:
    if s >= 0.6:
        eye(c, round(ex * s), round(ey * s), 6, 4)
        eye(c, round((ex + 11) * s), round((ey + 1) * s), 5, 3)
        c.dot(round(nx * s), round(ny * s), "ink")
        c.dot(round(nx * s) + 1, round(ny * s), "ink")
        blush(c, round((ex - 1) * s), round((ey + 8) * s))
    else:
        c.dot(round(ex * s) + 1, round(ey * s) + 1, "ink")
        c.dot(round(ex * s) + 1, round(ey * s) + 2, "ink")
        c.dot(round((ex + 10) * s), round(ey * s) + 1, "ink")


def _mossfawn_back(c: Canvas, s: float) -> None:
    for x0, y0, x1, y1 in [(30, 58, 28, 76), (54, 58, 57, 76)]:
        c.part(c.capsule(x0 * s, y0 * s, x1 * s, y1 * s, 3.4 * s), "bark", 2, contour=False)
    c.part(c.ellipse(40 * s, 54 * s, 20 * s, 14 * s), "bark", 3)
    c.part(c.ellipse(26 * s, 48 * s, 4.5 * s, 4.5 * s), "ink", 5)
    c.part(c.ellipse(40 * s, 47 * s, 18 * s, 10 * s), "leaf", 3, gloss=True)
    for x in (28, 38, 48):
        c.part(c.leaf(x * s, 42 * s, (x + 4) * s, 34 * s, 3 * s), "leaf", 4, contour=False)
    _rear_head(c, s, 53, 32, 10)
    c.part(c.capsule(53 * s, 23 * s, 54 * s, 15 * s, 1.2 * s), "leaf", 2, contour=False)
    c.part(c.leaf(54 * s, 16 * s, 46 * s, 11 * s, 3 * s), "leaf", 3)
    c.part(c.leaf(54 * s, 16 * s, 62 * s, 10 * s, 3 * s), "leaf", 4)


def _rear_head(c: Canvas, s: float, hx: float, hy: float, r: float) -> None:
    """A deer head seen from behind and a little to the side: neck, ears, the snout tip peeking out."""
    c.part(c.capsule((hx - 4) * s, (hy + 16) * s, (hx - 1) * s, (hy + 4) * s, 6 * s), "bark", 3)
    c.part(c.ellipse((hx + r * 0.75) * s, (hy + 5) * s, 5.5 * s, 4 * s), "bark", 5)
    c.part(c.leaf((hx - 5) * s, (hy - 5) * s, (hx - 19) * s, (hy - 12) * s, 4.5 * s), "bark", 2)
    c.part(c.ellipse(hx * s, hy * s, r * s, (r - 1) * s), "bark", 3, gloss=True)
    c.part(c.leaf((hx + 5) * s, (hy - 6) * s, (hx + 17) * s, (hy - 13) * s, 4.5 * s), "bark", 3)
    c.fill(c.leaf((hx + 6) * s, (hy - 6) * s, (hx + 15) * s, (hy - 11.5) * s, 1.6 * s), "rose3")


def grovehart(c: Canvas, view: str, s: float = 1.0) -> None:
    """Mossfawn grown tall: branch antlers in leaf and blossom, a mantle of moss and flowers."""
    if view == "back":
        return _grovehart_back(c, s)
    for x0, y0, x1, y1, base in [(54, 54, 57, 76, 1), (30, 54, 27, 76, 1), (60, 56, 64, 77, 3), (37, 56, 35, 77, 3)]:
        c.part(c.capsule(x0 * s, y0 * s, x1 * s, y1 * s, 2.7 * s), "bark", base, contour=base > 1)
        c.fill(c.rect((x1 - 4) * s, (y1 - 2) * s, (x1 + 4) * s, (y1 + 3) * s) & c.capsule(x0 * s, y0 * s, x1 * s, y1 * s, 3 * s), "bark0")
    c.part(c.ellipse(47 * s, 47 * s, 21 * s, 12 * s), "bark", 3)
    c.part(c.ellipse(68 * s, 41 * s, 4 * s, 5 * s), "ink", 5)
    c.part(c.ellipse(50 * s, 39 * s, 19 * s, 8 * s) | c.ellipse(36 * s, 42 * s, 9 * s, 7 * s), "leaf", 3, gloss=True)
    for x, y, col in ((40, 36, "rose3"), (52, 34, "sun"), (61, 38, "rose3"), (47, 41, "cream")):
        c.fill(c.circle(x * s, y * s, 1.8 * s), col)
        c.dot(round(x * s), round(y * s), "ember3")
    c.part(c.capsule(31 * s, 42 * s, 25 * s, 27 * s, 6.5 * s), "bark", 3)
    _antler(c, s, 1)
    _antler(c, s, -1)
    c.part(c.leaf(17 * s, 21 * s, 4 * s, 16 * s, 4 * s), "bark", 3)
    c.fill(c.leaf(18 * s, 21 * s, 7 * s, 17.5 * s, 1.6 * s), "rose3")
    c.part(c.ellipse(24 * s, 23 * s, 9 * s, 9 * s), "bark", 3, gloss=True)
    c.part(c.ellipse(17 * s, 29 * s, 6.5 * s, 4.5 * s), "bark", 5)
    _face(c, s, 18, 19, 11, 28)


def _antler(c: Canvas, s: float, side: int) -> None:
    bx = 24 + side * 5
    tip = (bx + side * 12, 4)
    main = c.taper([(bx, 16), (bx + side * 4, 10), tip], 1.8 * s, 1.0 * s) if s == 1 else None
    pts = [(bx * s, 16 * s), ((bx + side * 4) * s, 10 * s), (tip[0] * s, tip[1] * s)]
    c.part(c.taper(pts, 1.8 * s, 1.0 * s), "bark", 2, contour=False)
    c.part(c.taper([((bx + side * 3) * s, 11 * s), ((bx - side * 2) * s, 4 * s)], 1.2 * s, 0.9 * s), "bark", 2, contour=False)
    c.part(c.leaf(tip[0] * s, tip[1] * s, (tip[0] + side * 7) * s, (tip[1] + 3) * s, 2.4 * s), "leaf", 3)
    c.part(c.leaf((bx - side * 2) * s, 4 * s, (bx - side * 6) * s, -1 * s, 2.2 * s), "leaf", 4)
    c.fill(c.circle((bx + side * 5) * s, 9 * s, 1.6 * s), "rose2")
    del main


def _grovehart_back(c: Canvas, s: float) -> None:
    for x0, y0, x1, y1 in [(27, 60, 25, 78), (56, 60, 59, 78)]:
        c.part(c.capsule(x0 * s, y0 * s, x1 * s, y1 * s, 3.6 * s), "bark", 2, contour=False)
    c.part(c.ellipse(41 * s, 56 * s, 22 * s, 14 * s), "bark", 3)
    c.part(c.ellipse(24 * s, 50 * s, 4.5 * s, 5.5 * s), "ink", 5)
    c.part(c.ellipse(41 * s, 48 * s, 21 * s, 10 * s), "leaf", 3, gloss=True)
    for x, y, col in ((28, 45, "rose3"), (40, 42, "sun"), (52, 44, "rose3"), (46, 50, "cream")):
        c.fill(c.circle(x * s, y * s, 2 * s), col)
        c.dot(round(x * s), round(y * s), "ember3")
    for side in (1, -1):
        bx = 54 + side * 5
        c.part(c.taper([(bx * s, 27 * s), ((bx + side * 5) * s, 18 * s), ((bx + side * 13) * s, 10 * s)], 2 * s, 1.1 * s), "bark", 2, contour=False)
        c.part(c.leaf((bx + side * 13) * s, 10 * s, (bx + side * 20) * s, 13 * s, 2.6 * s), "leaf", 3)
        c.part(c.taper([((bx + side * 4) * s, 20 * s), ((bx - side * 1) * s, 12 * s)], 1.3 * s, 1 * s), "bark", 2, contour=False)
        c.part(c.leaf((bx - side * 1) * s, 12 * s, (bx - side * 5) * s, 7 * s, 2.3 * s), "leaf", 4)
    _rear_head(c, s, 54, 33, 10.5)


def thistlehog(c: Canvas, view: str, s: float = 1.0) -> None:
    """A round hedgehog whose spines are thistle heads; it sneezes seeds when nervous."""
    spines = [(30, 40), (38, 33), (48, 31), (58, 34), (65, 42), (44, 38), (55, 40), (34, 45)]
    if view == "back":
        spines = [(24, 44), (32, 34), (42, 30), (52, 31), (61, 36), (66, 46), (38, 41), (50, 40), (58, 46), (30, 50), (45, 50)]
    for x, y in [(36, 72), (58, 72)]:
        c.part(c.ellipse(x * s, y * s, 5 * s, 3.5 * s), "bark", 1)
    body = c.ellipse(46 * s, 56 * s, 23 * s, 17 * s)
    c.part(body, "leaf", 2)
    for x, y in spines:
        c.part(c.leaf(x * s, (y + 9) * s, (x + (x - 46) * 0.25) * s, (y - 3) * s, 4.5 * s), "leaf", 2, contour=False)
        c.part(c.ellipse(x * s, (y - 1) * s, 4.2 * s, 3.6 * s), "plum", 2, gloss=True)
        for k in (-2, 0, 2):
            c.part(c.capsule((x + k) * s, (y - 3) * s, (x + k * 1.6) * s, (y - 7) * s, 0.7 * s), "plum", 3, contour=False, light=False)
    if view == "back":
        c.part(c.ellipse(46 * s, 68 * s, 12 * s, 4 * s), "leaf", 1, contour=False)
        return
    c.part(c.ellipse(27 * s, 58 * s, 13 * s, 11 * s), "bark", 5, gloss=True)
    c.part(c.ellipse(16 * s, 61 * s, 3.5 * s, 3 * s), "rose", 2)
    c.part(c.ellipse(33 * s, 70 * s, 4 * s, 2.5 * s), "bark", 4)
    eye(c, round(21 * s), round(53 * s), 5, 3)
    eye(c, round(31 * s), round(53 * s), 5, 3)
    blush(c, round(19 * s), round(60 * s))
    blush(c, round(33 * s), round(60 * s))
