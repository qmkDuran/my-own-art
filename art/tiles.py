"""World tiles (16x16): grass variants, autotiled terrain (path, water, interior floor edges), tall grass,
flowers. Terrain sheets are 80x48: a 3x3 blob (edges and outer corners) plus the full tile and the inner-corner
tile, which the game's TerrainPainter cuts into 8x8 quadrants."""
from __future__ import annotations

import random

from pix import Canvas, _grow, _shift, _shrink

T = 16


def _wrap_dot(c: Canvas, x: int, y: int, name: str) -> None:
    c.dot(x % c.w, y % c.h, name)


def _tuft(c: Canvas, x: int, y: int, dark: str, light: str) -> None:
    """A small grass tuft: two dark blades and a lit tip, wrapping at tile edges so tiles join."""
    for dx, dy, col in ((0, 0, dark), (1, -1, dark), (2, 0, dark), (1, -2, light), (-1, -1, dark)):
        _wrap_dot(c, x + dx, y + dy, col)


def grass(variant: int) -> Canvas:
    """Meadow grass: flat base, a few tufts; variant 3 carries tiny flowers."""
    c = Canvas(T, T)
    c.fill(c.rect(0, 0, T, T), "leaf3")
    rnd = random.Random(variant * 17 + 3)
    for _ in range((0, 2, 3, 2)[variant]):
        _tuft(c, rnd.randrange(T), rnd.randrange(T), "leaf2", "leaf4")
    if variant == 3:
        for x, y, col in ((3, 4, "cream"), (11, 10, "rose3"), (7, 13, "sun")):
            c.dot(x, y, col)
            c.dot(x, y + 1, "leaf2")
    return c


def _texture_path(c: Canvas) -> None:
    c.fill(c.rect(0, 0, c.w, c.h), "sand2")
    rnd = random.Random(5)
    for _ in range(c.w * c.h // 40):
        x, y = rnd.randrange(c.w), rnd.randrange(c.h)
        c.dot(x, y, "sand1")
        if rnd.random() < 0.4:
            c.dot(x + 1, y, "sand3")


def _texture_water(c: Canvas) -> None:
    c.fill(c.rect(0, 0, c.w, c.h), "water2")
    for y0 in range(0, c.h, 8):
        for x0 in range(0, c.w, 16):
            off = 8 if (y0 // 8) % 2 else 0
            for k in range(4):
                c.dot((x0 + off + 3 + k) % c.w, y0 + 3 + (1 if k in (0, 3) else 0), "water3")
            c.dot((x0 + off + 5) % c.w, y0 + 3, "water4")


def _texture_floor(c: Canvas) -> None:
    """Warm wooden planks, two per tile, seams staggered."""
    c.fill(c.rect(0, 0, c.w, c.h), "bark3")
    for y in range(0, c.h, 8):
        c.fill(c.rect(0, y + 7, c.w, y + 8), "bark2")
        c.fill(c.rect(0, y, c.w, y + 1), "sand1")
        seam = 5 if (y // 8) % 2 else 13
        for x in range(seam, c.w, 16):
            c.fill(c.rect(x, y, x + 1, y + 7), "bark2")


TEXTURES = {"path": _texture_path, "water": _texture_water, "floor": _texture_floor}
RIMS = {"path": ("leaf2", "sand1"), "water": ("leaf2", "sand2"), "floor": ("bark1", "bark2")}
PAD = 8
INSET = 2


def _tiled_texture(kind: str, w: int, h: int) -> Canvas:
    """The terrain's 16x16 texture repeated, so every piece lines up with its neighbours."""
    tile = Canvas(T, T)
    TEXTURES[kind](tile)
    out = Canvas(w, h)
    for y in range(0, h, T):
        for x in range(0, w, T):
            out.paste(tile, x, y)
    return out


def _paint_piece(kind: str, region_fn, size: int) -> Canvas:
    """One piece painted on a padded canvas (so rims only follow real edges), then cropped."""
    big = _tiled_texture(kind, size + 2 * PAD + T, size + 2 * PAD + T)
    work = Canvas(big.w, big.h)
    region = region_fn(work)
    work.px[region] = big.px[region]
    work.ramp[region] = big.ramp[region]
    outer, edge = RIMS[kind]
    work.fill(region & ~_shrink(region), edge)
    work.fill(_grow(region) & ~region, outer)
    if kind == "water":
        top = region & ~_shift(region, 0, 3) & ~(region & ~_shrink(region))
        work.fill(top, "deep1")
    out = Canvas(size, size)
    out.px = work.px[PAD:PAD + size, PAD:PAD + size].copy()
    out.ramp = work.ramp[PAD:PAD + size, PAD:PAD + size].copy()
    return out


def terrain(kind: str) -> Canvas:
    """The 80x48 autotile sheet of one terrain: blob (0..47), full (48..63), inner corners (64..79)."""
    def blob(c: Canvas):
        return _rounded(c, PAD + INSET, PAD + INSET, PAD + 48 - INSET, PAD + 48 - INSET, 6)

    def full(c: Canvas):
        return c.rect(0, 0, c.w, c.h)

    def inner(c: Canvas):
        m = c.rect(0, 0, c.w, c.h)
        for cx in (PAD, PAD + T):
            for cy in (PAD, PAD + T):
                m &= ~c.circle(cx, cy, INSET + 0.6)
        return m
    sheet = Canvas(80, 48)
    sheet.paste(_paint_piece(kind, blob, 48), 0, 0)
    sheet.paste(_paint_piece(kind, full, T), 48, 0)
    sheet.paste(_paint_piece(kind, inner, T), 64, 0)
    return sheet


def _rounded(c: Canvas, x0: int, y0: int, x1: int, y1: int, r: int):
    m = c.rect(x0 + r, y0, x1 - r, y1) | c.rect(x0, y0 + r, x1, y1 - r)
    for cx, cy in ((x0 + r, y0 + r), (x1 - r, y0 + r), (x0 + r, y1 - r), (x1 - r, y1 - r)):
        m |= c.circle(cx, cy, r)
    return m


TUFT = [
    "  l    l",
    " lm  l m",
    " mm lmmm",
    "lmbmmmbm",
    "mbmmbmmb",
    "bmdbmbdb",
    "bddbdbdd",
    "dddddddd",
]
TUFT_COLOURS = {"d": "leaf1", "b": "leaf2", "m": "leaf3", "l": "leaf4"}
TUFT_SPOTS = [(4, -6), (12, -6), (0, 1), (8, 1), (4, 8), (12, 8)]


def tall_grass(front_only: bool) -> Canvas:
    """Tall grass: hand-placed tufts that tile into dense patches; the front cut (lower tufts) is drawn over a
    walker's legs."""
    c = Canvas(T, T)
    if not front_only:
        c.fill(c.rect(0, 0, T, T), "leaf2")
    for ox, oy in TUFT_SPOTS:
        if front_only and oy < 8:
            continue
        for y, row in enumerate(TUFT):
            for x, ch in enumerate(row):
                if ch != " " and 0 <= oy + y < T:
                    c.dot((ox + x) % T, oy + y, TUFT_COLOURS[ch])
    return c


def flower_bed() -> Canvas:
    """A small cluster of flowers on grass (decor; withers to dry stalks)."""
    c = grass(0)
    for x, y, col in ((3, 5, "rose2"), (9, 3, "sun"), (12, 9, "rose3"), (5, 11, "plum3"), (10, 13, "cream")):
        c.dot(x, y + 1, "leaf1")
        c.dot(x, y + 2, "leaf1")
        for dx, dy in ((0, -1), (-1, 0), (1, 0), (0, 1)):
            c.dot(x + dx, y + dy, col)
        c.dot(x, y, "ember4")
    return c
