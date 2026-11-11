"""Enemies of the Glasswood (Act 1). Each kind has a strong silhouette and glowing eyes on the emissive layer, so in
darkness you see eyes and rims first, in lantern light the whole body. Class sizes: small 48 px canvas, medium 64 px,
mini-boss 128 px. Frames: idle / move / attack rows; deaths are particle bursts in the game."""
from __future__ import annotations

import math

from pix import Spr

POSES = {"idle": 4, "move": 4, "attack": 3}


def pick(table: dict, pose: str, i: int) -> float:
    """Per-pose animation curve: a table entry is a constant or one value per frame."""
    v = table[pose]
    return v[i] if isinstance(v, tuple) else v


# ------------------------------------------------------------------ Gloam: a drop of living dark
def gloam(pose: str, i: int) -> Spr:
    s = Spr(48, 48)
    squash = pick({"idle": (0, 1, 0, -1), "move": (1, 0, -1, 0), "attack": (-2, -4, 3)}, pose, i)
    lean = pick({"idle": 0, "move": (2, 3, 2, 1), "attack": (0, 1, 5)}, pose, i)
    sway = pick({"idle": (-1, 0, 1, 0), "move": (-2, -3, -2, -1), "attack": (0, -2, -4)}, pose, i)
    cx, base = 24 + lean, 44
    rx, ry = 11 + max(0, squash), 9 - squash // 2
    s.ellipse(cx, base - ry, rx, ry, "ink")
    s.poly([(cx - rx + 2, base - ry - 2), (cx + rx - 2, base - ry - 2), (cx + 3 + sway, base - 26 + squash),
            (cx + sway, base - 34 + squash * 2), (cx - 4 + sway, base - 27 + squash)], "ink")
    s.poly([(cx - 4 + sway, base - 27 + squash), (cx + sway, base - 34 + squash * 2), (cx - 2 + sway * 2, base - 38 + squash * 2)], "night")
    s.ellipse(cx + 3, base - ry + 2, rx - 5, ry - 4, "void")
    for k, dx in enumerate((-9, -4, 3, 8)):                       # little tendrils it drags itself with
        wob = (i + k) % 2
        s.line([(cx + dx, base - 2), (cx + dx + (1 if dx > 0 else -1) * (2 + wob), base)], "ink", width=2)
    ey = base - ry - 2 + max(0, -squash) // 2
    eye = "violet_lt" if pose != "attack" else "rose"
    s.rect(cx - 5, ey, cx - 3, ey + 1, eye, glow=True)
    s.rect(cx + 3, ey, cx + 5, ey + 1, eye, glow=True)
    s.px(cx - 4, ey, "bone", glow=True)
    s.px(cx + 4, ey, "bone", glow=True)
    if pose == "attack" and i >= 1:
        s.rect(cx - 3, ey + 4, cx + 3, ey + 6, "void")
        s.line([(cx - 2, ey + 5), (cx + 2, ey + 5)], "violet", glow=True)
    s.outline()
    s.recolor_edge(0, -1, "dusk3", only={"ink", "night"})
    s.recolor_edge(-1, 0, "violet", only={"ink"})
    return s


# ------------------------------------------------------------------ Splinter Hound: glass grows from its back
def _leg(s: Spr, hip: tuple[float, float], ang: float, length: float, c: str) -> None:
    knee = (hip[0] + math.sin(ang) * length * 0.55, hip[1] + math.cos(ang) * length * 0.55)
    foot = (knee[0] + math.sin(ang * 0.3) * length * 0.45, knee[1] + length * 0.45)
    s.line([hip, knee, foot], c, width=2)
    s.rect(foot[0] - 1, foot[1], foot[0] + 1, foot[1], "stone_dk")


def hound(pose: str, i: int) -> Spr:
    s = Spr(64, 48)
    run = pick({"idle": (0.1, -0.1, 0.1, -0.1), "move": (0.7, 0.2, -0.6, 0.0), "attack": (-0.9, 0.9, 0.9)}, pose, i)
    bob = pick({"idle": (0, 0, 1, 1), "move": (0, -1, 0, 1), "attack": (1, -3, -2)}, pose, i)
    stretch = pick({"idle": 0, "move": 0, "attack": (-2, 4, 5)}, pose, i)
    by = 27 + bob
    _leg(s, (19, by + 2), -run, 15, "stone_dk")
    _leg(s, (40, by + 2), run, 15, "stone_dk")
    s.poly([(10, by - 2), (4, by - 6 - abs(run) * 3), (3, by - 4), (9, by + 1)], "stone")          # tail
    s.ellipse(29 + stretch // 2, by, 15 + stretch, 7, "stone")
    s.ellipse(37 + stretch, by + 1, 8, 7, "stone_lt")                                               # deep chest
    s.ellipse(25, by - 2, 10, 3, "stone_lt")
    hx, hy = 47 + stretch, by - 6
    s.poly([(hx - 5, hy - 3), (hx + 3, hy - 4), (hx + 10, hy), (hx + 10, hy + 2), (hx + 2, hy + 4), (hx - 4, hy + 4)], "stone")
    s.poly([(hx - 3, hy - 3), (hx - 1, hy - 9), (hx + 2, hy - 4)], "stone_dk")                    # ear
    s.line([(hx + 3, hy + 3), (hx + 9, hy + 2)], "void")
    if pose == "attack" and i > 0:
        s.poly([(hx + 3, hy + 3), (hx + 10, hy + 3), (hx + 7, hy + 7)], "void")                    # open jaw
        s.px(hx + 8, hy + 3, "bone")
    s.rect(hx + 3, hy - 2, hx + 4, hy - 1, "glint", glow=True)
    _leg(s, (23, by + 3), run, 15, "stone")
    _leg(s, (43 + stretch, by + 3), -run, 15, "stone")
    for k, (sx, h) in enumerate(((14, 8), (20, 12), (27, 14), (33, 11), (39, 7))):                 # glass ridge
        top = (sx - 3 - k % 2, by - 6 - h)
        s.poly([(sx - 3, by - 5), (sx + 2, by - 5), top], "glass" if k % 2 else "glass_dk")
        s.line([(sx, by - 6), top], "glass_lt")
        s.px(top[0], top[1] + 1, "glint", glow=k in (1, 2))
    s.outline()
    s.recolor_edge(0, -1, "mist", only={"stone", "stone_lt"})
    return s


# ------------------------------------------------------------------ Mirror Moth: wings of silvered glass
def moth(pose: str, i: int) -> Spr:
    s = Spr(64, 56)
    k = pick({"idle": (1.0, 0.7, 0.4, 0.7), "move": (1.0, 0.55, 0.25, 0.55), "attack": (1.0, 1.15, 1.2)}, pose, i)
    cx, cy = 32, 28
    for side in (-1, 1):
        up = [(cx + side * 3, cy - 4), (cx + side * 27, cy - 4 - 18 * k), (cx + side * 30, cy - 2 - 9 * k),
              (cx + side * 20, cy + 3), (cx + side * 3, cy + 2)]
        low = [(cx + side * 3, cy + 1), (cx + side * 19, cy + 3), (cx + side * 21, cy + 6 + 9 * k), (cx + side * 10, cy + 8 + 10 * k),
               (cx + side * 3, cy + 7)]
        s.poly(up, "glass_dk")
        s.poly(low, "glass_dp")
        mid = (cx + side * 15, cy - 4 - 7 * k)
        s.poly([(cx + side * 5, cy - 3), (cx + side * 24, cy - 4 - 15 * k), mid], "glass")          # silvered pane
        s.line([(cx + side * 4, cy - 2), (cx + side * 26, cy - 3 - 16 * k)], "ink")                  # lead lines
        s.line([(cx + side * 5, cy), (cx + side * 27, cy - 2 - 8 * k)], "ink")
        s.line([(cx + side * 22, cy - 3 - 13 * k), (cx + side * 24, cy - 3 - 15 * k)], "glint", glow=True)
        ex, ey = cx + side * 17, cy - 1 - 5 * k                                                         # eye-spot
        s.ellipse(ex, ey, 2, 2 * max(k, 0.5), "amber", glow=True)
        s.px(ex, ey, "void")
        s.px(cx + side * 12, cy + 4 + 6 * k, "glass_lt")
    s.ellipse(cx, cy + 3, 3, 9, "pale")
    for yy in range(cy - 2, cy + 12, 3):
        s.line([(cx - 2, yy), (cx + 2, yy)], "mist")
    s.ellipse(cx, cy - 7, 3, 3, "bone")
    s.line([(cx - 1, cy - 9), (cx - 5, cy - 16), (cx - 8, cy - 17)], "pale")
    s.line([(cx + 1, cy - 9), (cx + 5, cy - 16), (cx + 8, cy - 17)], "pale")
    s.px(cx - 2, cy - 7, "glint", glow=True)
    s.px(cx + 2, cy - 7, "glint", glow=True)
    if pose == "attack":
        s.ellipse(cx, cy + 3, 2, 3 + i, "sun", glow=True)
    s.outline()
    s.recolor_edge(0, -1, "glass_lt", only={"glass_dk"})
    return s


# ------------------------------------------------------------------ The Glazier (mini-boss): a window that walked
def _pane_body(s: Spr, top: float, sway: float) -> None:
    """Stained-glass torso: panes of muted colour held in black lead, a dark hollow where a light should be."""
    sh, wa = top, top + 40
    s.poly([(40 + sway, sh), (88 + sway, sh), (76 + sway, wa), (52 + sway, wa)], "ink")
    panes = [("glass_dk", [(42, 0), (62, 0), (60, 18), (48, 18)]), ("violet", [(66, 0), (86, 0), (80, 18), (68, 18)]),
             ("glass", [(49, 20), (59, 20), (58, 38), (53, 38)]), ("dusk3", [(69, 20), (79, 20), (75, 38), (70, 38)]),
             ("rust", [(44, 2), (46, 2), (47, 14), (45, 14)])]
    for c, pts in panes:
        s.poly([(x + sway, y + sh) for x, y in pts], c)
    s.poly([(64 + sway, sh + 10), (70 + sway, sh + 20), (64 + sway, sh + 32), (58 + sway, sh + 20)], "void")
    s.ellipse(64 + sway, sh + 21, 2, 3, "ember", glow=True)
    s.line([(44 + sway, sh + 3), (58 + sway, sh + 3)], "glass_lt")
    s.line([(68 + sway, sh + 3), (84 + sway, sh + 3)], "violet_lt")


def glazier(pose: str, i: int) -> Spr:
    s = Spr(128, 128)
    sway = pick({"idle": (0, 1, 0, -1), "move": (-2, 0, 2, 0), "attack": (0, -1, 2)}, pose, i)
    bob = pick({"idle": (0, 0, 1, 1), "move": (0, 2, 0, 2), "attack": (2, -2, 4)}, pose, i)
    step = pick({"idle": 0, "move": (-1, 0, 1, 0), "attack": 0}, pose, i)
    top = 46 + bob
    for side in (-1, 1):                                                       # legs: long glass rods
        lift = 3 if step == side else 0
        s.line([(64 + side * 7 + sway, top + 40), (64 + side * 10, 120 - lift)], "glass_dk", width=4)
        s.line([(64 + side * 7 + sway, top + 40), (64 + side * 10, 120 - lift)], "glass", width=2)
        s.poly([(64 + side * 10 - 4, 121 - lift), (64 + side * 10 + 4, 121 - lift), (64 + side * 10, 114 - lift)], "glass_lt")
    if pose == "attack":
        arms = (((30, 20), (98, 20)), ((26, 10), (102, 10)), ((22, 112), (106, 112)))[i]
    else:
        arms = ((26 - sway, 100), (102 - sway, 100))
    for side, hand in zip((-1, 1), arms):
        sh = (64 + side * 22 + sway, top + 4)
        elbow = ((sh[0] + hand[0]) / 2 + side * 6, (sh[1] + hand[1]) / 2)
        s.line([sh, elbow, hand], "ink", width=5)
        s.line([sh, elbow, hand], "glass_dk", width=3)
        tip = (hand[0] + side * 2, hand[1] + (14 if hand[1] > top else -14))
        s.poly([(hand[0] - 4, hand[1]), (hand[0] + 4, hand[1]), tip], "glass_lt")
        s.line([hand, tip], "glint", glow=True)
    _pane_body(s, top, sway)
    s.poly([(40 + sway, top), (88 + sway, top), (92 + sway, top + 5), (36 + sway, top + 5)], "ink")    # shoulders
    hx, hy = 64 + sway, top - 14
    s.ellipse(hx, hy, 9, 12, "glass_dk")
    s.ellipse(hx + 2, hy - 2, 6, 9, "glass")
    s.line([(hx - 2, hy - 10), (hx + 1, hy - 3), (hx - 1, hy + 2), (hx + 2, hy + 8)], "glint", glow=True)    # the crack
    for k, (dx, h) in enumerate(((-8, 10), (-3, 16), (3, 18), (8, 11))):                                    # crown of shards
        s.poly([(hx + dx - 2, hy - 9), (hx + dx + 2, hy - 9), (hx + dx + (1 if dx > 0 else -1), hy - 9 - h)],
               "glass_lt" if k % 2 else "glass")
    if pose == "attack" and i == 2:
        s.ellipse(hx, hy, 3, 3, "sun", glow=True)
    s.outline()
    s.recolor_edge(0, -1, "glint", only={"glass_dk", "glass"})
    return s


KINDS = {"gloam": (gloam, 48, 48), "hound": (hound, 64, 48), "moth": (moth, 64, 56), "glazier": (glazier, 128, 128)}
