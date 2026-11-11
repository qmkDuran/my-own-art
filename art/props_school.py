"""Act 3's schoolhouse in the Town of One Tuesday: worn floorboards, rows of desks, a blackboard with the same
lesson chalked on it every afternoon, shelves of books nobody has finished. All drawn in code."""
from __future__ import annotations

import random

from pix import Spr, clock_dial
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


ROOM_W, ROOM_H = 640, 416          # the classroom's floor; the walls are built around it


def floor() -> Spr:
    """Worn floorboards running east-west, staggered joints, a darker threshold where the door is."""
    rnd = random.Random(111)
    s = Spr(ROOM_W, ROOM_H)
    s.rect(0, 0, ROOM_W - 1, ROOM_H - 1, "earth")
    for y in range(0, ROOM_H, 12):
        shade = rnd.choice(["earth", "earth", "earth_lt", "earth_dk"])
        s.rect(0, y + 1, ROOM_W - 1, y + 10, shade)
        s.line([(0, y + 11), (ROOM_W - 1, y + 11)], "earth_dk")
        x = rnd.randint(-80, 0)
        while x < ROOM_W:
            x += rnd.randint(90, 170)
            s.line([(x, y + 1), (x, y + 10)], "earth_dk")
        for _ in range(4):
            s.px(rnd.randint(0, ROOM_W - 1), y + rnd.randint(3, 8), "skin_dk")    # nail heads, knots
    s.rect(ROOM_W // 2 - 72, ROOM_H - 10, ROOM_W // 2 + 72, ROOM_H - 1, "earth_dk")  # the door's threshold
    return s


def wall_north() -> Spr:
    """The back wall seen face-on: plaster over a dark wainscot, two tall windows (lit: someone keeps a lamp in the
    yard), the blackboard, the wall clock stopped at four, and a row of coat pegs."""
    s = Spr(ROOM_W + 32, 120)
    s.rect(0, 0, ROOM_W + 31, 8, "earth_dk")                         # the wall's top
    s.rect(0, 8, ROOM_W + 31, 119, "stone")
    s.rect(0, 84, ROOM_W + 31, 119, "earth_dk")                      # wainscot
    s.line([(0, 84), (ROOM_W + 31, 84)], "earth_lt")
    for x in range(8, ROOM_W + 31, 24):
        s.line([(x, 86), (x, 118)], "ink")
    for wx in (90, ROOM_W - 58):
        s.rect(wx - 22, 20, wx + 22, 72, "earth")
        s.rect(wx - 18, 24, wx + 18, 68, "flame")
        s.rect(wx - 18, 24, wx + 18, 30, "amber", glow=True)
        s.line([(wx, 23), (wx, 69)], "earth_dk")
        s.line([(wx - 19, 46), (wx + 19, 46)], "earth_dk")
    bx = (ROOM_W + 32) // 2
    s.rect(bx - 90, 22, bx + 90, 76, "earth")                        # the blackboard
    s.rect(bx - 86, 25, bx + 86, 72, "moss_dk")
    for y, w in ((34, 120), (44, 96), (54, 140)):
        s.line([(bx - 78, y), (bx - 78 + w, y)], "pale")
    s.ellipse(bx + 66, 36, 5, 5, "bone")
    s.line([(bx + 62, 36), (bx + 70, 36)], "stone")
    s.rect(bx - 88, 73, bx + 88, 76, "earth_lt")
    clock_dial(s, bx + 150, 34, 11)                                  # the wall clock, stopped at four
    s.rect(bx + 148, 46, bx + 152, 70, "earth_dk")
    s.ellipse(bx + 150, 72, 4, 4, "gold")
    for k in range(7):                                               # coat pegs, a scarf, a satchel
        x = 170 + k * 14 if k < 4 else ROOM_W - 200 + k * 14
        s.rect(x, 78, x + 1, 81, "earth_lt")
    s.poly([(184, 81), (190, 81), (191, 100), (183, 100)], "rust")
    s.rect(ROOM_W - 148, 82, ROOM_W - 140, 96, "glass_dk")
    return _finish(s, "earth_lt", {"earth_dk"})


def wall_side() -> Spr:
    """An east or west wall seen from above: a dark timber top with its plastered inner edge."""
    s = Spr(16, ROOM_H + 16)
    s.rect(0, 0, 15, ROOM_H + 15, "earth_dk")
    s.rect(2, 0, 13, ROOM_H + 15, "ink")
    s.line([(14, 0), (14, ROOM_H + 15)], "stone")
    return s


def wall_south(w: int) -> Spr:
    """The front wall (nearest the viewer): only its top and a sliver of its face show."""
    s = Spr(w, 24)
    s.rect(0, 0, w - 1, 23, "earth_dk")
    s.rect(0, 2, w - 1, 9, "ink")
    s.rect(0, 10, w - 1, 23, "stone_dk")
    s.line([(0, 10), (w - 1, 10)], "stone")
    return s


def master_desk() -> Spr:
    """The schoolmaster's desk: broad, a bell, a ledger, an apple nobody eats."""
    s = Spr(64, 38)
    s.rect(3, 10, 60, 30, "earth")
    s.rect(3, 8, 60, 12, "earth_lt")
    s.line([(3, 8), (60, 8)], "skin_lt")
    for x in (5, 56):
        s.rect(x, 30, x + 3, 36, "earth_dk")
    s.rect(12, 4, 24, 8, "rust")                                      # ledger
    s.ellipse(44, 5, 3, 3, "gold")                                    # the school bell
    s.rect(43, 0, 45, 3, "earth_dk")
    s.ellipse(52, 6, 2, 2, "blood")                                   # the apple
    return _finish(s, "skin_lt", {"earth_lt"})


def stove() -> Spr:
    """A pot-bellied iron stove with its pipe; the only warm thing in the room, the fire low behind the grate."""
    s = Spr(36, 76)
    s.rect(16, 0, 20, 34, "stone_dk")
    s.ellipse(18, 52, 13, 16, "ink")
    s.ellipse(17, 50, 11, 14, "stone_dk")
    s.rect(11, 52, 24, 58, "ember_dk")
    s.rect(12, 53, 23, 57, "flame", glow=True)
    s.line([(12, 55), (23, 55)], "ink")
    s.rect(8, 66, 28, 70, "stone_dk")
    for x in (10, 25):
        s.rect(x, 70, x + 2, 75, "ink")
    return _finish(s, "stone_lt", {"stone_dk"})


MANIFEST: dict[str, dict] = {
    "class_floor": {"draw": floor, "foot": [0, 0], "flat": True},
    "class_wall_n": {"draw": wall_north, "foot": [ROOM_W + 32, 16]},
    "class_wall_side": {"draw": wall_side, "foot": [16, ROOM_H]},
    "class_wall_s": {"draw": lambda: wall_south(240), "foot": [200, 14]},
    "master_desk": {"draw": master_desk, "foot": [58, 10]},
    "stove": {"draw": stove, "foot": [26, 10], "light": "flame"},
    "desk_a": {"draw": lambda: desk(101), "foot": [30, 10]},
    "desk_b": {"draw": lambda: desk(102), "foot": [30, 10]},
    "blackboard": {"draw": blackboard, "foot": [48, 8]},
    "bookshelf_a": {"draw": lambda: bookshelf(103), "foot": [36, 12]},
    "bookshelf_b": {"draw": lambda: bookshelf(104), "foot": [36, 12]},
}
