"""Small UI glyphs: element badges (10x10), mood marks (12x12), item icons (16x16), the Trust heart."""
from __future__ import annotations

from pix import Canvas


def element(kind: str) -> Canvas:
    c = Canvas(10, 10)
    if kind == "bloom":
        c.part(c.leaf(2, 8, 8, 1, 3), "leaf", 3, contour=False)
        c.fill(c.capsule(2, 8, 6, 4, 0.5), "leaf1")
    elif kind == "cinder":
        c.part(c.leaf(5, 9, 5, 0, 3.4), "ember", 2, contour=False)
        c.fill(c.leaf(5, 9, 5, 4, 1.6), "sun")
    elif kind == "tide":
        c.part(c.circle(5, 6, 3.5) | c.poly([(5, 0), (2, 5), (8, 5)]), "water", 3, contour=False)
        c.dot(3, 5, "sky")
    elif kind == "gale":
        c.part(c.capsule(1, 3, 7, 3, 0.8) | c.capsule(3, 6, 9, 6, 0.8), "teal", 2, contour=False)
        c.dot(8, 2, "teal3")
        c.dot(2, 7, "teal3")
    else:
        c.part(c.poly([(1, 8), (3, 2), (7, 1), (9, 6), (8, 9)]), "stone", 2, contour=False)
    return c.finish()


def mood(kind: str) -> Canvas:
    c = Canvas(12, 12)
    if kind == "wary":
        c.part(c.poly([(6, 1), (11, 10), (1, 10)]), "ember", 3, contour=False)
        c.fill(c.rect(5.5, 4, 6.5, 7.5), "ink")
        c.dot(6, 8, "ink")
    elif kind == "playful":
        c.part(c.poly([(6, 0), (7.5, 4.5), (12, 5), (8.5, 7.5), (10, 12), (6, 9), (2, 12), (3.5, 7.5), (0, 5), (4.5, 4.5)]), "ember", 4, contour=False)
    elif kind == "hungry":
        c.part(c.circle(6, 7, 4.5), "rose", 1, contour=False, gloss=True)
        c.fill(c.leaf(6, 3, 10, 1, 1.4), "leaf3")
    else:
        c.part(c.circle(6, 6, 5) & ~c.circle(8.5, 4.5, 4.2), "plum", 3, contour=False)
    return c.finish()


def item(kind: str) -> Canvas:
    c = Canvas(16, 16)
    if kind == "sunberry":
        for x, y in ((6, 9), (10, 9), (8, 6)):
            c.part(c.circle(x, y, 3.2), "ember", 3, gloss=True)
        c.part(c.leaf(8, 4, 12, 1, 1.8), "leaf", 3, contour=False)
    elif kind == "smoky_nut":
        c.part(c.ellipse(8, 10, 5, 5), "bark", 3, gloss=True)
        c.part(c.ellipse(8, 6, 6, 2.6), "bark", 1)
        c.fill(c.rect(7.5, 2, 8.5, 4), "bark0")
    elif kind == "sweet_kelp":
        c.part(c.taper([(4, 14), (6, 9), (5, 4), (8, 1)], 1.6, 1.0), "teal", 2, contour=False)
        c.part(c.taper([(9, 14), (12, 9), (10, 5), (12, 2)], 1.6, 1.0), "teal", 3, contour=False)
    elif kind == "mending_salve":
        c.part(c.rect(3, 6, 13, 14), "ink", 5)
        c.part(c.rect(2, 3, 14, 6), "leaf", 2)
        c.fill(c.leaf(6, 12, 10, 8, 1.6), "leaf3")
    elif kind == "spring_tonic":
        c.part(c.rect(6, 1, 10, 5), "bark", 3)
        c.part(c.ellipse(8, 10, 5, 5), "water", 3, gloss=True)
    else:
        c.part(c.circle(8, 8, 5), "plum", 2, gloss=True)
    return c.finish()


def heart(kind: str) -> Canvas:
    """A Trust heart: full, half (left half filled) or empty."""
    c = Canvas(9, 8)
    shape = c.circle(2.5, 2.8, 2.4) | c.circle(6.5, 2.8, 2.4) | c.poly([(0.2, 3.5), (8.8, 3.5), (4.5, 8)])
    c.fill(shape, "dusk")
    if kind == "full":
        c.part(shape, "rose", 2, contour=False, gloss=True)
    elif kind == "half":
        c.part(shape & c.rect(0, 0, 4.5, 8), "rose", 2, contour=False)
    return c.finish()


def cursor() -> Canvas:
    c = Canvas(6, 8)
    c.fill(c.poly([(0, 0), (5, 4), (0, 8)]), "ember3")
    return c.finish()
