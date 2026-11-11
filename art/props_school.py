"""Act 3's schoolhouse in the Town of One Tuesday: worn floorboards, rows of desks, a blackboard with the same
lesson chalked on it every afternoon, shelves of books nobody has finished. All drawn in code."""
from __future__ import annotations

import random

from pix import Spr
from props import _finish


def desk(seed: int) -> Spr:
    """A child's desk with its bench: a slanted lid, an inkwell, a slate left mid-sum."""
    rnd = random.Random(seed)
    s = Spr(34, 30)
    s.poly([(3, 9), (31, 9), (30, 17), (4, 17)], "earth_lt")         # slanted lid
    s.line([(3, 9), (31, 9)], "skin_lt")
    s.rect(4, 17, 30, 19, "earth")
    for x in (5, 28):
        s.rect(x, 19, x + 1, 27, "earth_dk")
    s.rect(6, 24, 28, 25, "earth_dk")                                   # the bench rail
    s.ellipse(25, 11, 2, 1.5, "ink")                                    # inkwell
    if rnd.random() < 0.7:
        s.rect(8, 11, 16, 15, "stone_dk")                               # a slate
        s.line([(9, 13), (14, 13)], "pale")
    return _finish(s, "skin_lt", {"earth_lt"})


def blackboard() -> Spr:
    """The blackboard on its easel. Today's lesson, every day: 'Tuesday. The sun is resting. Be quiet.'"""
    s = Spr(64, 60)
    for x in (8, 54):
        s.line([(x, 6), (x + (-4 if x < 30 else 4), 58)], "earth_dk", width=2)
    s.rect(4, 6, 60, 38, "earth")
    s.rect(7, 9, 57, 35, "moss_dk")
    for y, w in ((14, 36), (20, 28), (26, 40)):
        s.line([(11, y), (11 + w, y)], "pale")                         # chalk lines
    s.ellipse(50, 15, 3, 3, "bone")                                     # a chalk sun, asleep
    s.line([(48, 15), (52, 15)], "stone")
    s.rect(6, 37, 58, 39, "earth_lt")                                   # chalk ledge
    s.px(20, 38, "bone")
    return _finish(s, "earth_lt", {"earth"})


def bookshelf(seed: int) -> Spr:
    """A tall shelf of school books; the interior's walls are lined with them."""
    rnd = random.Random(seed)
    s = Spr(40, 64)
    s.rect(3, 4, 37, 62, "earth_dk")
    s.rect(5, 6, 35, 60, "ink")
    for shelf in range(4):
        y = 6 + shelf * 14
        s.rect(5, y + 12, 35, y + 13, "earth")
        x = 6
        while x < 33:
            bw = rnd.randint(2, 4)
            bh = rnd.randint(7, 11)
            s.rect(x, y + 12 - bh, min(x + bw - 1, 34), y + 11, rnd.choice(["rust", "glass_dk", "moss", "violet", "earth_lt", "ember_dk"]))
            x += bw
    s.rect(3, 2, 37, 5, "earth")
    return _finish(s, "earth_lt", {"earth", "earth_dk"})


MANIFEST: dict[str, dict] = {
    "desk_a": {"draw": lambda: desk(101), "foot": [30, 10]},
    "desk_b": {"draw": lambda: desk(102), "foot": [30, 10]},
    "blackboard": {"draw": blackboard, "foot": [48, 8]},
    "bookshelf_a": {"draw": lambda: bookshelf(103), "foot": [36, 12]},
    "bookshelf_b": {"draw": lambda: bookshelf(104), "foot": [36, 12]},
}
