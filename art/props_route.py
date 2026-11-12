"""Route props for the trainer prototype: leafy daylight trees (two shapes) and tall grass tufts (the patches wild
creatures roam in). Same kit and finishing as Lanternfall's props (outline, rims); greens from the creature accents."""
from __future__ import annotations

import random

from pix import Spr


def leafy_tree(w: int, h: int, seed: int) -> Spr:
    """A round broadleaf tree: trunk, a lumpy canopy in three greens, light from the upper left."""
    s = Spr(w, h)
    rnd = random.Random(seed)
    cx, base = w // 2, h - 3
    s.rect(cx - 3, base - 26, cx + 3, base, "earth")
    s.rect(cx - 3, base - 26, cx - 2, base, "earth_lt")
    s.line([(cx + 2, base - 18), (cx + 9, base - 28)], "earth", 2)
    top = 6
    canopy_h = base - 22 - top
    blobs = [(cx + rnd.randint(-w // 4, w // 4), top + rnd.randint(canopy_h // 4, canopy_h * 3 // 4), rnd.randint(w // 6, w // 4))
             for _ in range(7)]
    blobs.append((cx, top + canopy_h // 2, w // 3))
    for x, y, r in blobs:
        s.ellipse(x, y + 3, r, r * 0.85, "leaf_dk")
    for x, y, r in blobs:
        s.ellipse(x - 1, y, r - 1, (r - 1) * 0.85, "leaf")
    for x, y, r in blobs:
        s.ellipse(x - r * 0.35, y - r * 0.35, r * 0.45, r * 0.38, "leaf_lt")
    for _ in range(18):
        x, y = rnd.randint(6, w - 6), rnd.randint(top + 2, base - 26)
        if s.opaque(x, y):
            s.px(x, y, "leaf_dk")
    s.outline()
    s.recolor_edge(-1, -1, "leaf_lt", only={"leaf"})
    return s


def tall_grass(seed: int) -> Spr:
    """A tuft of tall grass blades (creatures half hide in it)."""
    s = Spr(28, 20)
    rnd = random.Random(seed)
    for k in range(9):
        x = 3 + k * 2.7 + rnd.uniform(-1, 1)
        hgt = rnd.randint(10, 17)
        lean = rnd.uniform(-3, 3)
        col = ("leaf_dk", "leaf", "leaf_lt")[k % 3]
        s.line([(x, 19), (x + lean, 19 - hgt)], col, 2)
    s.outline()
    return s


MANIFEST = {
    "tree_leafy_a": {"draw": lambda: leafy_tree(64, 88, 7), "foot": [10, 8]},
    "tree_leafy_b": {"draw": lambda: leafy_tree(56, 76, 21), "foot": [10, 8]},
    "tall_grass": {"frames": [lambda: tall_grass(1), lambda: tall_grass(2), lambda: tall_grass(3)], "foot": [0, 0]},
}
