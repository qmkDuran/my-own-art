"""Item icons (24 px), skill icons (24 px), passive glyphs (16 px) and small effect sprites. Item icons sit centred on
their cell with a 2 px margin so they read at 2x on screen; the variant palettes keep bases recognisable."""
from __future__ import annotations

import math

from palette import rgba
from pix import Spr, arc_points

# ------------------------------------------------------------------ item icons: base -> draw(s, variant)
VARIANT = [("earth_dk", "earth", "earth_lt"), ("stone_dk", "stone", "stone_lt"), ("rust", "ember", "flame"),
           ("glass_dk", "glass", "glass_lt"), ("dusk1", "dusk2", "dusk3"), ("violet", "violet_lt", "pale")]


def _staff(s: Spr, c: tuple[str, str, str], hook: int) -> None:
    s.line([(5, 22), (15, 4)], c[0], width=2)
    s.line([(6, 22), (16, 4)], c[1])
    if hook == 0:
        s.line([(15, 4), (18, 2), (21, 4)], "stone_lt")
        s.rect(18, 6, 22, 12, "ink")
        s.rect(19, 7, 21, 11, "gold", glow=True)
    elif hook == 1:
        s.ellipse(16, 4, 3, 3, "ink")
        s.ellipse(16, 4, 1.5, 1.5, "amber", glow=True)
    elif hook == 2:
        s.poly([(13, 2), (19, 2), (20, 8), (12, 8)], "ink")
        s.rect(14, 3, 18, 7, "flame", glow=True)
    else:
        s.line([(15, 4), (12, 1), (9, 3)], "stone_lt")
        s.rect(6, 4, 10, 10, "ink")
        s.rect(7, 5, 9, 9, "glint", glow=True)


def _relic(s: Spr, c: tuple[str, str, str], kind: int) -> None:
    if kind == 0:                                     # hand lantern
        s.line([(12, 2), (12, 5)], "stone_lt")
        s.rect(7, 5, 17, 21, "ink")
        s.rect(8, 7, 16, 19, c[1])
        s.rect(10, 9, 14, 17, "gold", glow=True)
    elif kind == 1:                                   # oil flask
        s.rect(10, 2, 14, 7, "earth")
        s.ellipse(12, 15, 7, 7, "glass_dk")
        s.ellipse(12, 16, 5, 5, c[1])
        s.px(10, 13, "bone")
    elif kind == 2:                                   # wick charm
        s.line([(12, 2), (12, 8)], "earth_lt")
        s.poly([(6, 8), (18, 8), (12, 22)], c[1])
        s.poly([(9, 10), (15, 10), (12, 17)], "amber", glow=True)
    else:                                             # reflector disk
        s.ellipse(12, 12, 9, 9, c[0])
        s.ellipse(12, 12, 7, 7, "pale")
        s.ellipse(10, 10, 3, 3, "bone")


def _head(s: Spr, c: tuple[str, str, str], kind: int) -> None:
    if kind == 0:
        s.ellipse(12, 15, 11, 3, c[1])
        s.rect(7, 6, 17, 14, c[1])
        s.rect(7, 11, 17, 12, "ember")
    elif kind == 1:
        s.poly([(4, 21), (5, 8), (12, 2), (19, 8), (20, 21), (16, 21), (16, 10), (8, 10), (8, 21)], c[1])
        s.rect(8, 10, 16, 21, "ink")
    else:
        s.ellipse(12, 12, 8, 9, c[1])
        s.ellipse(9, 11, 2, 2, "glass_lt")
        s.ellipse(15, 11, 2, 2, "glass_lt")
        s.rect(9, 16, 15, 19, c[0])


def _body(s: Spr, c: tuple[str, str, str], kind: int) -> None:
    hem = (22, 18, 20)[kind]
    s.poly([(6, 3), (18, 3), (21, hem), (3, hem)], c[1])
    s.poly([(6, 3), (9, 3), (8, hem), (3, hem)], c[0])
    s.poly([(9, 3), (15, 3), (12, 9)], "ink")
    s.line([(12, 9), (12, hem)], c[0])
    if kind == 2:
        s.poly([(4, 3), (20, 3), (22, 9), (2, 9)], c[2])


def _hands(s: Spr, c: tuple[str, str, str], kind: int) -> None:
    s.rect(6, 12, 17, 22, c[1])
    s.rect(6, 4, 9, 13, c[1])
    s.rect(10, 3, 13, 12, c[1])
    s.rect(14, 5, 17, 12, c[1])
    s.rect(17, 12, 20, 16, c[1])
    s.rect(6, 18, 17, 19, c[0] if kind == 0 else "stone_lt")


def _feet(s: Spr, c: tuple[str, str, str], kind: int) -> None:
    s.rect(8, 3, 15, 18, c[1])
    s.poly([(8, 15), (15, 15), (21, 18), (21, 21), (8, 21)], c[1])
    s.rect(8, 20, 21, 21, c[0])
    s.rect(8, 5 + kind * 3, 15, 6 + kind * 3, c[2])


def _belt(s: Spr, c: tuple[str, str, str], kind: int) -> None:
    s.rect(1, 9, 22, 14, c[1])
    s.rect(9, 8, 14, 15, "amber" if kind == 0 else "stone_lt")
    s.rect(11, 10, 12, 13, c[0])
    if kind == 0:
        s.rect(15, 14, 21, 20, "earth")


def _neck(s: Spr, c: tuple[str, str, str], kind: int) -> None:
    for x, y in arc_points(12, 6, 8, 0.2, math.pi - 0.2, 9):
        s.px(x, y, "stone_lt")
    if kind == 0:
        s.ellipse(12, 16, 5, 6, c[1])
        s.ellipse(12, 16, 3, 4, "gold", glow=True)
    else:
        s.ellipse(12, 16, 5, 5, "amber", glow=True)
        for a in range(8):
            s.line([(12, 16), (12 + math.cos(a * 0.785) * 8, 16 + math.sin(a * 0.785) * 8)], "amber")
        s.ellipse(12, 16, 3, 3, "sun", glow=True)


def _ring(s: Spr, c: tuple[str, str, str], kind: int) -> None:
    s.d.ellipse([5, 7, 19, 21], outline=rgba(c[1]), width=3)
    s.d.arc([6, 8, 18, 20], 200, 290, fill=rgba(c[2]))
    s.ellipse(12, 6, 3 + kind, 3, "glint" if kind == 0 else "amber", glow=True)


ITEM_DRAW = {"staff": (_staff, 4), "relic": (_relic, 4), "head": (_head, 3), "body": (_body, 3), "hands": (_hands, 2),
             "feet": (_feet, 2), "belt": (_belt, 2), "neck": (_neck, 2), "ring": (_ring, 2)}


def item_icon(base: str, kind: int, variant: int) -> Spr:
    s = Spr(24, 24)
    fn, _ = ITEM_DRAW[base]
    fn(s, VARIANT[variant], kind)
    s.outline()
    return s


# ------------------------------------------------------------------ skill icons (24 px, framed in the game)
def _skill(name: str) -> Spr:
    s = Spr(24, 24)
    if name == "sunlash":
        pts = [(3, 20), (8, 10), (14, 6), (20, 7), (22, 11)]
        s.line(pts, "amber", width=2, glow=True)
        s.line(pts, "sun", glow=True)
        s.ellipse(22, 11, 2, 2, "sun", glow=True)
    elif name == "flare":
        for a in range(12):
            r = 10 if a % 2 else 7
            s.line([(12, 12), (12 + math.cos(a * 0.524) * r, 12 + math.sin(a * 0.524) * r)], "flame", glow=True)
        s.ellipse(12, 12, 5, 5, "gold", glow=True)
        s.ellipse(12, 12, 2, 2, "sun", glow=True)
    elif name == "lantern_toss":
        for x, y in arc_points(12, 22, 13, math.pi * 1.1, math.pi * 1.6, 6):
            s.px(x, y, "amber", glow=True)
        s.rect(13, 6, 21, 17, "ink")
        s.rect(14, 8, 20, 15, "gold", glow=True)
        s.rect(16, 10, 18, 13, "sun", glow=True)
        s.line([(17, 3), (17, 6)], "stone_lt")
    elif name == "moth_swarm":
        for mx, my in ((7, 8), (16, 6), (12, 15), (19, 17), (5, 18)):
            s.poly([(mx, my), (mx - 3, my - 2), (mx - 3, my + 2)], "flame", glow=True)
            s.poly([(mx, my), (mx + 3, my - 2), (mx + 3, my + 2)], "flame", glow=True)
            s.px(mx, my, "sun", glow=True)
    elif name == "dash":
        for k in range(3):
            s.line([(3 + k * 3, 8 + k * 4), (12 + k * 3, 8 + k * 4)], ("dusk3", "mist", "pale")[k])
        s.poly([(14, 6), (22, 12), (14, 18)], "gold", glow=True)
    elif name == "eclipse":
        s.ellipse(12, 12, 9, 9, "amber", glow=True)
        s.ellipse(14, 11, 8, 8, "void")
    elif name == "noon":
        s.ellipse(12, 12, 10, 10, "gold", glow=True)
        s.ellipse(12, 12, 7, 7, "sun", glow=True)
    elif name == "tonic":
        s.rect(10, 2, 14, 6, "earth")
        s.poly([(8, 7), (16, 7), (19, 21), (5, 21)], "glass_dk")
        s.poly([(8, 12), (16, 12), (18, 20), (6, 20)], "rose", glow=True)
        s.px(9, 14, "bone")
    s.outline()
    return s


SKILLS = ["sunlash", "flare", "lantern_toss", "moth_swarm", "dash", "eclipse", "noon", "tonic"]


# ------------------------------------------------------------------ passive glyphs (16 px)
def _glyph(name: str) -> Spr:
    s = Spr(16, 16)
    if name == "life":
        s.ellipse(5, 6, 3, 3, "blood")
        s.ellipse(10, 6, 3, 3, "blood")
        s.poly([(2, 7), (13, 7), (8, 13)], "blood")
        s.px(5, 5, "rose")
    elif name == "oil":
        s.ellipse(8, 10, 4, 4, "amber")
        s.poly([(4, 9), (12, 9), (8, 2)], "amber")
        s.px(7, 9, "gold")
    elif name == "light":
        s.ellipse(8, 8, 3, 3, "gold", glow=True)
        for a in range(8):
            s.px(8 + math.cos(a * 0.785) * 6, 8 + math.sin(a * 0.785) * 6, "amber", glow=True)
    elif name == "damage":
        s.line([(3, 13), (12, 3)], "stone_lt", width=2)
        s.line([(3, 13), (6, 10)], "earth")
        s.line([(4, 9), (7, 12)], "amber")
    elif name == "fire":
        s.poly([(4, 13), (12, 13), (11, 7), (8, 2), (7, 7), (5, 6)], "flame")
        s.poly([(6, 13), (10, 13), (8, 8)], "gold")
    elif name == "speed":
        s.poly([(3, 3), (9, 8), (3, 13)], "glass_lt")
        s.poly([(8, 3), (14, 8), (8, 13)], "glint")
    elif name == "armour":
        s.poly([(3, 3), (13, 3), (13, 8), (8, 14), (3, 8)], "stone")
        s.poly([(5, 5), (8, 5), (8, 11), (5, 8)], "stone_lt")
    elif name == "crit":
        s.poly([(8, 1), (10, 6), (15, 8), (10, 10), (8, 15), (6, 10), (1, 8), (6, 6)], "rose")
        s.px(8, 8, "bone")
    elif name == "moth":
        s.poly([(8, 8), (2, 3), (3, 12)], "flame")
        s.poly([(8, 8), (14, 3), (13, 12)], "flame")
        s.line([(8, 5), (8, 12)], "bone")
    elif name == "dark":
        s.ellipse(8, 8, 6, 6, "violet")
        s.ellipse(10, 7, 5, 5, "void")
    s.outline()
    return s


GLYPHS = ["life", "oil", "light", "damage", "fire", "speed", "armour", "crit", "moth", "dark"]


# ------------------------------------------------------------------ effect sprites
def fx_moth(frame: int) -> Spr:
    s = Spr(10, 10)
    w = (4, 2)[frame]
    s.poly([(5, 5), (5 - w, 5 - w), (5 - w, 5 + 1)], "flame", glow=True)
    s.poly([(5, 5), (5 + w, 5 - w), (5 + w, 5 + 1)], "flame", glow=True)
    s.px(5, 5, "sun", glow=True)
    s.px(5, 6, "gold", glow=True)
    return s


def fx_shard() -> Spr:
    s = Spr(14, 6)
    s.poly([(0, 3), (4, 0), (13, 3), (4, 5)], "glass_lt", glow=True)
    s.line([(3, 2), (12, 3)], "glint", glow=True)
    return s


def fx_lantern() -> Spr:
    s = Spr(14, 18)
    s.line([(7, 0), (7, 2)], "stone_lt")
    s.rect(2, 3, 12, 16, "ink")
    s.rect(3, 5, 11, 14, "amber", glow=True)
    s.rect(5, 6, 9, 13, "gold", glow=True)
    s.rect(6, 8, 8, 11, "sun", glow=True)
    return s


def fx_spark() -> Spr:
    s = Spr(3, 3)
    s.px(1, 0, "gold", glow=True)
    s.px(0, 1, "gold", glow=True)
    s.px(2, 1, "gold", glow=True)
    s.px(1, 2, "gold", glow=True)
    s.px(1, 1, "sun", glow=True)
    return s
