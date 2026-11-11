"""Full-screen backdrops (320x180): the title vale (half withered, half healed) and the battle stages.
Battle platforms sit where the game puts the creatures (see data/ui.json "battle")."""
from __future__ import annotations

import random

import numpy as np

from palette import WITHER
from pix import INDEX, Canvas

W, H = 320, 180
FOE_PAD = (100, 80, 44, 10)
ALLY_PAD = (236, 148, 62, 13)


def _bands(c: Canvas, rows: list[tuple[int, str]]) -> None:
    """Horizontal colour bands from the top (y, colour) - stepped, never dithered."""
    for (y0, col), nxt in zip(rows, rows[1:] + [(c.h, "")]):
        c.fill(c.rect(0, y0, c.w, nxt[0]), col)


def _hills(c: Canvas, base: int, amp: float, freq: float, phase: float, ramp: str, tone: int) -> None:
    x, y = c.grid()
    top = base - amp * (np.sin(x * freq + phase) * 0.6 + np.sin(x * freq * 2.3 + phase * 1.7) * 0.4)
    c.part((y >= top) & (y < c.h), ramp, tone, shade=0.02, contour=False)


def _clouds(c: Canvas, spots: list[tuple[int, int]]) -> None:
    for cx, cy in spots:
        m = c.ellipse(cx, cy, 16, 5) | c.ellipse(cx - 8, cy - 2, 8, 5) | c.ellipse(cx + 6, cy - 4, 9, 6)
        c.fill(m, "cream")
        c.fill(m & c.rect(0, cy + 2, c.w, cy + 6), "fog")


def _treeline(c: Canvas, y: int, ramp: str, seed: int) -> None:
    rnd = random.Random(seed)
    m = c.rect(0, y, c.w, y + 30)
    for x in range(-6, c.w + 10, 9):
        m |= c.circle(x, y + rnd.uniform(-3, 3), rnd.uniform(7, 11))
    c.part(m, ramp, 2, shade=0.05, contour=False)


def _flowers(c: Canvas, y0: int, y1: int, count: int, seed: int) -> None:
    rnd = random.Random(seed)
    for _ in range(count):
        x, y = rnd.randrange(c.w), rnd.randrange(y0, y1)
        col = rnd.choice(["rose3", "sun", "cream", "plum3"])
        c.dot(x, y, col)
        c.dot(x, y + 1, "leaf2")


def _pad(c: Canvas, cx: int, cy: int, rx: int, ry: int, ramp: str) -> None:
    c.fill(c.ellipse(cx, cy + 2, rx, ry), "leaf1" if ramp == "leaf" else "dry1")
    c.part(c.ellipse(cx, cy, rx, ry), ramp, 4, shade=0.3, contour=False)
    c.fill(c.ellipse(cx - rx * 0.2, cy - ry * 0.25, rx * 0.55, ry * 0.4), "leaf5" if ramp == "leaf" else "dry4")


def title() -> Canvas:
    """The vale at morning: a river through meadows, the left side still drained grey by the Hush."""
    c = Canvas(W, H)
    _bands(c, [(0, "water3"), (34, "water4"), (64, "sky")])
    c.fill(c.circle(252, 44, 16), "ember4")
    c.fill(c.circle(252, 44, 13), "sun")
    _clouds(c, [(60, 28), (190, 18), (290, 60)])
    _hills(c, 96, 10, 0.02, 0.4, "teal", 1)
    _hills(c, 112, 8, 0.03, 2.0, "leaf", 2)
    _treeline(c, 118, "leaf", 7)
    c.fill(c.rect(0, 126, W, H), "leaf3")
    _river(c)
    _flowers(c, 130, 178, 90, 3)
    _wither_left(c)
    return c


def _river(c: Canvas) -> None:
    x, y = c.grid()
    centre = 150 + np.sin((y - 126) / 14.0) * 18 + (y - 126) * 0.6
    width = 4 + (y - 126) * 0.35
    river = (y >= 126) & (np.abs(x - centre) < width)
    c.fill(river, "water2")
    c.fill(river & (np.abs(x - centre - width * 0.3) < 1.0), "water3")
    edge = (y >= 126) & (np.abs(x - centre) >= width) & (np.abs(x - centre) < width + 1.5)
    c.fill(edge, "sand2")


SKY_WITHER = {"water4": "fog", "sky": "stone4", "sun": "paper", "ember4": "fog"}
HIGH_SKY = {"water3": "stone3"}
HORIZON = 80


def _drain(c: Canvas, area: np.ndarray) -> None:
    """Withered twins inside area: a pale grey sky above the horizon, dry land below."""
    _, y = c.grid()
    before = c.px.copy()
    for name, dry in SKY_WITHER.items():
        c.px[area & (before == INDEX[name])] = INDEX[dry]
    for name, dry in HIGH_SKY.items():
        c.px[area & (y < HORIZON) & (before == INDEX[name])] = INDEX[dry]
    for name, dry in WITHER.items():
        if name not in SKY_WITHER:
            c.px[area & (y >= HORIZON) & (before == INDEX[name])] = INDEX[dry]


def _wither_left(c: Canvas) -> None:
    """Drain everything left of a ragged line to its withered twin."""
    x, y = c.grid()
    line = 112 + np.sin(y / 9.0) * 6 + np.sin(y / 3.1) * 2
    _drain(c, x < line)


def battle(stage: str) -> Canvas:
    """A battle stage: sky, a distant tree line, meadow and two grass pads."""
    c = Canvas(W, H)
    _bands(c, [(0, "water4"), (26, "sky")])
    _clouds(c, [(70, 14), (250, 24)])
    _treeline(c, 44, "teal" if stage == "grove" else "leaf", 11)
    if stage == "grove":
        _treeline(c, 54, "leaf", 4)
    c.fill(c.rect(0, 62, W, H), "leaf3")
    c.fill(c.rect(0, 62, W, 66), "leaf2")
    rnd = random.Random(21)
    for _ in range(14):
        x, y = rnd.randrange(W), rnd.randrange(72, H)
        c.fill(c.ellipse(x, y, 10 + y * 0.1, 2 + y * 0.012), "leaf4" if rnd.random() < 0.5 else "leaf2")
    for _ in range(40):
        x, y = rnd.randrange(W), rnd.randrange(70, H)
        for dx, dy in ((0, 0), (1, -1), (2, 0)):
            c.dot(x + dx, y + dy, "leaf2")
    _flowers(c, 70, 178, 60 if stage == "grove" else 30, 9)
    _pad(c, *FOE_PAD, "leaf")
    _pad(c, *ALLY_PAD, "leaf")
    return c


def intro(kind: str) -> Canvas:
    """Story-card art: the vale fully withered (the Hush) or a single green shoot."""
    c = title()
    _drain(c, c.solid())
    if kind == "shoot":
        c.part(c.leaf(160, 150, 152, 138, 4), "leaf", 3)
        c.part(c.leaf(160, 150, 169, 136, 4), "leaf", 4)
    return c
