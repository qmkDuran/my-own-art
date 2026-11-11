"""Enemies of the Glasswood (Act 1). Each kind has a strong silhouette and glowing eyes on the emissive layer, so in
darkness you see eyes and rims first, in lantern light the whole body. Class sizes: small 48 px canvas, medium 64 px,
mini-boss 128 px. Frames: idle / move / attack rows; deaths are particle bursts in the game."""
from __future__ import annotations

import math
import random

from pix import Spr, clock_dial

POSES = {"idle": 4, "move": 4, "attack": 3}


def pick(table: dict, pose: str, i: int) -> float:
    """Per-pose animation curve: a table entry is a constant or one value per frame."""
    v = table[pose]
    return v[i] if isinstance(v, tuple) else v


# ------------------------------------------------------------------ Gloam: a drop of living dark
def gloam(pose: str, i: int) -> Spr:
    """A hunched drop of living dark: two horns of smoke, a split maw lined with violet light, raking claws."""
    s = Spr(48, 48)
    squash = pick({"idle": (0, 1, 0, -1), "move": (1, 0, -1, 0), "attack": (-2, -3, 2)}, pose, i)
    lean = pick({"idle": 0, "move": (2, 3, 2, 1), "attack": (0, 1, 5)}, pose, i)
    sway = pick({"idle": (-1, 0, 1, 0), "move": (-2, -3, -2, -1), "attack": (0, -2, -3)}, pose, i)
    cx, base = 24 + lean, 45
    rx, ry = 12 + max(0, squash), 10 - squash // 2
    top = base - ry * 2 - 6 + squash
    s.poly([(cx - rx, base - 2), (cx - rx + 2, base - ry - 4), (cx - 6 + sway, top + 4), (cx + 6 + sway, top + 4),
            (cx + rx - 2, base - ry - 4), (cx + rx, base - 2)], "ink")
    s.ellipse(cx, base - ry + 1, rx, ry - 1, "ink")
    for side in (-1, 1):                                            # horns of smoke, curling back
        hx = cx + side * 5 + sway
        s.poly([(hx - 2, top + 6), (hx + 2, top + 6), (hx + side * 6 + sway, top - 6), (hx + side * 4 + sway, top + 1)], "night")
        s.px(hx + side * 6 + sway, top - 7, "dusk3")
    s.ellipse(cx + 3, base - ry + 3, rx - 6, ry - 5, "void")
    for k, dx in enumerate((-10, -5, 5, 10)):                      # claws raking the ground
        wob = (i + k) % 2
        tip = cx + dx + (1 if dx > 0 else -1) * (3 + wob)
        s.line([(cx + dx, base - 3), (tip, base)], "ink", width=2)
        s.px(tip, base, "dusk3")
    open_ = 4 if pose == "attack" and i >= 1 else 1
    my = base - ry
    s.poly([(cx - 7, my), (cx + 7, my), (cx + 5, my + open_ + 1), (cx - 5, my + open_ + 1)], "void")
    for tx in range(cx - 6, cx + 7, 3):                             # teeth of violet light
        s.px(tx, my, "violet_lt", glow=True)
        if open_ > 1:
            s.px(tx + 1, my + open_, "violet", glow=True)
    ey = my - 6 + max(0, -squash) // 2
    eye = "rose" if pose == "attack" else "violet_lt"
    for side in (-1, 1):
        s.poly([(cx + side * 2, ey + 1), (cx + side * 6, ey - 1), (cx + side * 6, ey + 1)], eye, glow=True)
        s.px(cx + side * 5, ey, "bone", glow=True)
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
    s.poly([(44 + sway, sh), (84 + sway, sh), (90 + sway, sh + 10), (74 + sway, wa), (54 + sway, wa), (38 + sway, sh + 10)], "ink")
    panes = [("glass_dk", [(46, 2), (62, 2), (60, 18), (44, 12)]), ("violet", [(66, 2), (82, 2), (84, 12), (68, 18)]),
             ("glass", [(52, 20), (60, 20), (59, 37), (56, 37)]), ("dusk3", [(68, 20), (76, 20), (72, 37), (69, 37)]),
             ("rust", [(41, 11), (44, 11), (48, 20), (46, 21)])]
    for c, pts in panes:
        s.poly([(x + sway, y + sh) for x, y in pts], c)
    s.poly([(64 + sway, sh + 10), (70 + sway, sh + 20), (64 + sway, sh + 32), (58 + sway, sh + 20)], "void")
    s.ellipse(64 + sway, sh + 21, 2, 3, "ember", glow=True)
    s.line([(44 + sway, sh + 3), (58 + sway, sh + 3)], "glass_lt")
    s.line([(68 + sway, sh + 3), (84 + sway, sh + 3)], "violet_lt")


def _shard_down(s: Spr, x: float, y: float, length: float) -> None:
    """A shard hanging from the Glazier's shoulders like a mantle."""
    s.poly([(x - 3, y), (x + 3, y), (x + 1, y + length)], "glass_dk")
    s.line([(x - 1, y + 1), (x, y + length - 2)], "glass")


def glazier(pose: str, i: int) -> Spr:
    s = Spr(128, 128)
    sway = pick({"idle": (0, 1, 0, -1), "move": (-2, 0, 2, 0), "attack": (0, -1, 2)}, pose, i)
    bob = pick({"idle": (0, 0, 1, 1), "move": (0, 2, 0, 2), "attack": (2, -2, 4)}, pose, i)
    step = pick({"idle": 0, "move": (-1, 0, 1, 0), "attack": 0}, pose, i)
    top = 46 + bob
    for side in (-1, 1):                                                       # legs: jointed glass, lead at the knee
        lift = 3 if step == side else 0
        hip, knee, foot = (64 + side * 8 + sway, top + 40), (64 + side * 12, top + 58 - lift), (64 + side * 10, 120 - lift)
        s.line([hip, knee, foot], "ink", width=7)
        s.line([hip, knee, foot], "glass_dk", width=5)
        s.line([(hip[0] + 1, hip[1]), (knee[0] + 1, knee[1]), (foot[0] + 1, foot[1])], "glass", width=1)
        s.ellipse(knee[0], knee[1], 3, 3, "ink")
        s.poly([(foot[0] - 6, 122 - lift), (foot[0] + 6, 122 - lift), (foot[0] + 3, 115 - lift), (foot[0] - 3, 115 - lift)], "glass_lt")
    if pose == "attack":
        arms = (((30, 20), (98, 20)), ((26, 10), (102, 10)), ((22, 112), (106, 112)))[i]
    else:
        arms = ((26 - sway, 100), (102 - sway, 100))
    for side, hand in zip((-1, 1), arms):
        sh = (64 + side * 22 + sway, top + 4)
        elbow = ((sh[0] + hand[0]) / 2 + side * 6, (sh[1] + hand[1]) / 2)
        s.line([sh, elbow, hand], "ink", width=7)
        s.line([sh, elbow, hand], "glass_dk", width=5)
        tip = (hand[0] + side * 2, hand[1] + (14 if hand[1] > top else -14))
        s.poly([(hand[0] - 4, hand[1]), (hand[0] + 4, hand[1]), tip], "glass_lt")
        s.line([hand, tip], "glint", glow=True)
    for k in range(8):                                                          # skirt of hanging leaded shards
        _shard_down(s, 48 + k * 5 + sway, top + 36, 16 + (k * 5) % 11)
    _pane_body(s, top, sway)
    s.rect(60 + sway, top - 6, 68 + sway, top + 1, "ink")                       # neck
    for k in range(7):                                                                                 # mantle of shards
        sx = 36 + k * 9 + sway
        _shard_down(s, sx, top + 2, 10 + (k * 7) % 9)
    s.poly([(38 + sway, top), (90 + sway, top), (94 + sway, top + 6), (34 + sway, top + 6)], "ink")    # shoulders
    s.line([(40 + sway, top + 1), (88 + sway, top + 1)], "glass_lt")
    hx, hy = 64 + sway, top - 14
    s.ellipse(hx, hy, 9, 12, "glass_dk")
    s.ellipse(hx + 2, hy - 2, 6, 9, "glass")
    s.line([(hx - 2, hy - 10), (hx + 1, hy - 3), (hx - 1, hy + 2), (hx + 2, hy + 8)], "glint", glow=True)    # the crack
    for side in (-1, 1):                                                                                  # hollow eyes
        s.poly([(hx + side * 2, hy - 2), (hx + side * 6, hy - 3), (hx + side * 5, hy + 1)], "void")
        s.px(hx + side * 4, hy - 1, "glint", glow=True)
    for k, (dx, h) in enumerate(((-8, 10), (-3, 16), (3, 18), (8, 11))):                                    # crown of shards
        s.poly([(hx + dx - 2, hy - 9), (hx + dx + 2, hy - 9), (hx + dx + (1 if dx > 0 else -1), hy - 9 - h)],
               "glass_lt" if k % 2 else "glass")
    if pose == "attack" and i == 2:
        s.ellipse(hx, hy, 3, 3, "sun", glow=True)
    s.outline()
    s.recolor_edge(0, -1, "glint", only={"glass_dk", "glass"})
    return s


# ------------------------------------------------------------------ Husk: a farmhand of straw and embers
def husk(pose: str, i: int) -> Spr:
    """Straw stuffed into a dead man's coat, stitched with seams that glow; it walks the Ember Road's fields."""
    s = Spr(64, 64)
    bob = pick({"idle": (0, 0, 1, 1), "move": (0, 1, 0, 1), "attack": (1, -2, 2)}, pose, i)
    step = pick({"idle": 0, "move": (-1, 0, 1, 0), "attack": 0}, pose, i)
    lean = pick({"idle": 0, "move": (1, 2, 1, 0), "attack": (-2, 3, 6)}, pose, i)
    cx, top = 32 + lean, 14 + bob
    for side in (-1, 1):
        lift = 2 if step == side else 0
        s.line([(cx + side * 5, top + 32), (cx + side * 7, 60 - lift)], "earth_dk", width=3)
        s.line([(cx + side * 7, 60 - lift), (cx + side * 9, 60 - lift)], "earth_lt")
    s.poly([(cx - 10, top + 10), (cx + 10, top + 10), (cx + 12, top + 34), (cx - 12, top + 34)], "earth")
    s.poly([(cx - 10, top + 10), (cx - 5, top + 10), (cx - 7, top + 34), (cx - 12, top + 34)], "earth_dk")
    s.line([(cx - 1, top + 12), (cx + 1, top + 32)], "ember", glow=True)                     # the glowing seam
    s.line([(cx - 8, top + 22), (cx + 8, top + 21)], "ember_dk")
    arm_y = top + 13 if pose != "attack" else (top + 6, top - 6, top + 26)[i]
    for side in (-1, 1):
        s.line([(cx + side * 10, top + 12), (cx + side * 16, arm_y + 14)], "earth", width=3)
        for k in range(3):
            s.line([(cx + side * 16, arm_y + 14), (cx + side * (17 + k), arm_y + 19)], "amber")  # straw fingers
    s.ellipse(cx, top + 4, 7, 7, "earth_lt")                                                 # a sack for a head
    s.ellipse(cx - 2, top + 2, 4, 4, "skin")
    s.line([(cx - 6, top + 8), (cx + 6, top + 9)], "earth_dk")
    s.poly([(cx - 9, top), (cx + 9, top), (cx + 4, top - 7), (cx - 4, top - 7)], "ink")       # a ruined hat
    s.line([(cx - 11, top), (cx + 11, top)], "ink", width=2)
    s.poly([(cx - 5, top + 2), (cx - 2, top + 3), (cx - 3, top + 5)], "flame", glow=True)     # slanted ember eyes
    s.poly([(cx + 5, top + 2), (cx + 2, top + 3), (cx + 3, top + 5)], "flame", glow=True)
    s.line([(cx - 4, top + 7), (cx + 4, top + 7)], "ink")                                   # a stitched mouth
    for x in range(cx - 3, cx + 4, 2):
        s.line([(x, top + 6), (x, top + 8)], "ink")
    s.outline()
    s.recolor_edge(0, -1, "amber", only={"earth_lt", "earth"})
    return s


# ------------------------------------------------------------------ Silk Crawler: a grub that spits silk
def crawler(pose: str, i: int) -> Spr:
    s = Spr(48, 40)
    bob = pick({"idle": (0, 1, 0, 1), "move": (0, -1, 0, -1), "attack": (0, -2, 1)}, pose, i)
    rear = pick({"idle": 0, "move": 0, "attack": (2, 6, 1)}, pose, i)
    by = 28 + bob
    for k in range(3):                                                         # legs
        for side in (-1, 1):
            x = 18 + k * 7
            kick = ((i + k) % 2) * 2
            s.line([(x, by), (x + side * 3 + kick, by + 8)], "stone_dk")
    for k in range(4):                                                         # segmented pale body
        x = 12 + k * 7
        s.ellipse(x, by - 2 - (rear if k == 3 else 0) * 0.5, 6, 5, "pale" if k % 2 else "bone")
        s.line([(x - 4, by - 5), (x + 4, by - 5)], "mist")
    hx, hy = 38, by - 4 - rear
    s.ellipse(hx, hy, 6, 5, "mist")
    s.rect(hx + 1, hy - 2, hx + 2, hy - 1, "violet_lt", glow=True)
    s.rect(hx + 4, hy - 2, hx + 5, hy - 1, "violet_lt", glow=True)
    s.line([(hx + 4, hy + 3), (hx + 7, hy + 5)], "stone_dk")
    if pose == "attack" and i == 1:
        s.ellipse(hx + 7, hy + 2, 2, 2, "bone", glow=True)
    s.outline()
    s.recolor_edge(0, -1, "bone", only={"pale", "mist"})
    return s


# ------------------------------------------------------------------ the Moth Matron (Act 1 boss)
WING_BANDS = (("dusk3", 1.0), ("violet", 0.8), ("dusk3", 0.62), ("dusk2", 0.44), ("dusk1", 0.28))
WING_POINTS = 28


def _wing_shape(root: tuple, side: int, length: float, width: float, ang: float, scallops: int) -> list:
    """An organic wing: a rounded teardrop from the root (polar curve), its outer edge scalloped."""
    pts = []
    for j in range(WING_POINTS + 1):
        t = j / WING_POINTS                                   # 0..1 around the wing
        a = ang + (t - 0.5) * math.pi * 0.95
        r = length * math.sin(math.pi * t) ** 0.7
        r *= 1.0 - 0.06 * (0.5 + 0.5 * math.cos(t * scallops * 2 * math.pi)) * (t > 0.15 and t < 0.85)
        r *= 1.0 + (width - 1.0) * math.sin(math.pi * t)
        pts.append((root[0] + side * math.cos(a) * r, root[1] - math.sin(a) * r))
    return pts


def _shrink(pts: list, root: tuple, t: float) -> list:
    return [(root[0] + (x - root[0]) * t, root[1] + (y - root[1]) * t) for x, y in pts]


def _matron_wing(s: Spr, cx: float, cy: float, side: int, k: float) -> None:
    """One side of the Matron: rounded forewing and hindwing, shaded from a dusty pale edge in to a dark root in soft
    bands, veins fanning out, a scalloped edge, and false eyes that glow."""
    fore_root, hind_root = (cx + side * 6, cy - 4), (cx + side * 6, cy + 8)
    fore = _wing_shape(fore_root, side, 78, 1.1, 0.35 + 0.35 * (k - 0.8), 5)
    hind = _wing_shape(hind_root, side, 54, 1.0, -0.55 - 0.15 * (k - 0.8), 4)
    for wing, root in ((hind, hind_root), (fore, fore_root)):
        s.poly(wing, "mist")
        for c, t in WING_BANDS:
            s.poly(_shrink(wing, root, t * 0.95), c)
        for j in range(4, WING_POINTS - 3, 5):                 # veins from the root to the edge
            tip = wing[j]
            s.line([root, (root[0] * 0.15 + tip[0] * 0.85, root[1] * 0.15 + tip[1] * 0.85)], "dusk1")
    for j, (ox, oy, r) in enumerate(((46, -30, 7), (64, -10, 5), (32, 22, 6), (46, 32, 4))):   # false eyes
        ex, ey = cx + side * ox, cy + oy * (0.6 + 0.4 * k)
        s.ellipse(ex, ey, r + 1, r + 1, "pale")
        s.ellipse(ex, ey, r, r, "ink")
        s.ellipse(ex, ey, r - 1.5, r - 1.5, "amber" if j % 2 == 0 else "rose", glow=True)
        s.ellipse(ex - 1, ey - 1, max(1.0, r - 4), max(1.0, r - 4), "gold" if j % 2 == 0 else "blood", glow=True)
        s.px(ex, ey, "void")


def _matron_body(s: Spr, cx: float, cy: float, rnd: random.Random) -> None:
    """A fuzzy moth body: thorax and a segmented abdomen in dusty mauve, lit from above, dark underneath; only a
    soft glow of stolen light shows through the belly."""
    s.ellipse(cx, cy - 2, 12, 12, "dusk3")                    # thorax
    s.ellipse(cx - 2, cy - 5, 8, 7, "mist")
    for seg in range(6):                                      # abdomen segments, narrowing
        y = cy + 10 + seg * 6
        w = 10 - seg * 1.2
        s.ellipse(cx, y, w, 4, "dusk2")
        s.ellipse(cx - 1, y - 1, w - 2, 3, "dusk3")
        s.line([(cx - w + 2, y - 1), (cx - 1, y - 2)], "mist")
    s.ellipse(cx, cy + 22, 5, 9, "ember_dk")
    s.ellipse(cx, cy + 22, 3, 6, "amber", glow=True)            # the soft belly glow
    for _ in range(26):                                       # fuzz along the body's edge
        a = rnd.uniform(0, math.tau)
        rr = rnd.uniform(9, 13)
        s.px(cx + math.cos(a) * rr, cy + 6 + math.sin(a) * rr * 2.0, rnd.choice(["mist", "dusk3", "pale"]))
    s.ellipse(cx, cy - 16, 8, 7, "dusk3")                     # head
    s.ellipse(cx - 2, cy - 18, 5, 4, "mist")


def matron(pose: str, i: int) -> Spr:
    """The Moth Matron: a great moth of tattered silk, a ring of false eyes on her wings, her belly full of stolen
    light. The sun's fear of being eaten, given wings."""
    s = Spr(176, 160)
    k = pick({"idle": (1.0, 0.82, 0.64, 0.82), "move": (1.0, 0.7, 0.45, 0.7), "attack": (1.0, 1.12, 1.18)}, pose, i)
    cx, cy = 88, 78 + pick({"idle": (0, 1, 2, 1), "move": (0, 2, 4, 2), "attack": (2, -2, -4)}, pose, i)
    for side in (-1, 1):
        _matron_wing(s, cx, cy, side, k)
    _matron_body(s, cx, cy, random.Random(7))
    for side in (-1, 1):
        s.line([(cx + side * 3, cy - 20), (cx + side * 14, cy - 40), (cx + side * 26, cy - 44)], "mist", width=2)
        for j in range(4):
            fx = cx + side * (12 + j * 4)
            s.line([(fx, cy - 38 - j), (fx + side * 3, cy - 44 - j)], "mist")
        s.ellipse(cx + side * 4, cy - 16, 3, 3, "violet_lt", glow=True)
    if pose == "attack":
        s.ellipse(cx, cy + 22, 5 + i * 2, 9 + i * 2, "gold", glow=True)
    s.outline()
    s.recolor_edge(0, -1, "pale", only={"mist", "dusk3"})
    return s


# ------------------------------------------------------------------ Undertow: water that walks, falling upward
def undertow(pose: str, i: int) -> Spr:
    """A man-shaped column of river water, streaming upward off its shoulders in drops that never come down."""
    s = Spr(64, 64)
    bob = pick({"idle": (0, 1, 0, -1), "move": (0, 1, 0, 1), "attack": (1, -2, 3)}, pose, i)
    lean = pick({"idle": 0, "move": (1, 2, 1, 0), "attack": (-2, 2, 6)}, pose, i)
    cx, top = 32 + lean, 16 + bob
    s.poly([(cx - 12, 60), (cx - 9, top + 18), (cx - 6, top + 6), (cx + 6, top + 6), (cx + 9, top + 18), (cx + 12, 60)], "glass_dk")
    s.poly([(cx - 12, 60), (cx - 9, top + 18), (cx - 6, top + 6), (cx - 3, top + 6), (cx - 5, 60)], "glass_dp")
    for k in range(5):                                      # streaks running up the body
        x = cx - 7 + k * 3.5
        off = (i * 3 + k * 5) % 12
        s.line([(x, 58 - off), (x + 0.5, top + 14 - off * 0.5)], "glass" if k % 2 else "glass_lt")
    s.ellipse(cx, top + 2, 6, 7, "glass")
    s.ellipse(cx + 1, top, 3, 4, "glass_lt")
    for k in range(4):                                      # drops leaving the head, upward
        y = top - 6 - ((i * 4 + k * 5) % 14)
        s.ellipse(cx - 6 + k * 4, y, 1, 2, "glint", glow=k % 2 == 0)
    arm = top + 20 if pose != "attack" else (top + 10, top - 2, top + 26)[i]
    for side in (-1, 1):
        s.line([(cx + side * 8, top + 12), (cx + side * 14, arm)], "glass_dk", width=3)
    s.rect(cx - 3, top + 1, cx - 2, top + 2, "sun", glow=True)
    s.rect(cx + 2, top + 1, cx + 3, top + 2, "sun", glow=True)
    s.outline()
    s.recolor_edge(0, -1, "glint", only={"glass_dk", "glass"})
    return s


# ------------------------------------------------------------------ Drowned Lantern: a lamp still burning underwater
def drowned_lantern(pose: str, i: int) -> Spr:
    s = Spr(48, 56)
    bob = pick({"idle": (0, -1, -2, -1), "move": (0, -2, -3, -2), "attack": (0, -3, 1)}, pose, i)
    cx, cy = 24, 26 + bob
    s.line([(cx, cy - 16), (cx, cy - 10)], "stone_lt")
    s.ellipse(cx, cy - 18, 3, 3, "stone_lt")
    s.poly([(cx - 9, cy - 10), (cx, cy - 15), (cx + 9, cy - 10)], "ink")
    s.rect(cx - 8, cy - 10, cx + 8, cy + 10, "ink")
    glass = "glint" if pose == "attack" and i > 0 else "glass_lt"
    s.rect(cx - 6, cy - 8, cx + 6, cy + 8, "glass", glow=True)
    s.rect(cx - 4, cy - 6, cx + 4, cy + 6, glass, glow=True)
    s.rect(cx - 1, cy - 3, cx + 1, cy + 3, "sun", glow=True)
    s.line([(cx, cy - 10), (cx, cy + 10)], "ink")
    s.rect(cx - 7, cy + 10, cx + 7, cy + 12, "stone_dk")
    for k in range(5):                                      # weed and water hanging off it, drifting up
        x = cx - 8 + k * 4
        s.line([(x, cy + 12), (x + (k % 2) * 2 - 1, cy + 20 + (k * 3 + i) % 6)], "moss_lt" if k % 2 else "glass_dk")
    s.outline()
    s.recolor_edge(0, -1, "glint", only={"ink"})
    return s


# ------------------------------------------------------------------ Falls Heron: a heron of falling-up water
def heron(pose: str, i: int) -> Spr:
    """A tall wading bird of glassy water that stalks the Rising Falls and stabs from above; side view."""
    s = Spr(64, 72)
    bob = pick({"idle": (0, 0, 1, 1), "move": (0, 1, 0, 1), "attack": (2, -3, 1)}, pose, i)
    stride = pick({"idle": 0.0, "move": (0.5, 0.0, -0.5, 0.0), "attack": (0.0, 0.0, 0.0)}, pose, i)
    neck = pick({"idle": 0, "move": 2, "attack": (-6, 8, 14)}, pose, i)
    by = 40 + bob
    for k, sgn in enumerate((1, -1)):                                       # long legs
        hip = (30, by + 4)
        foot = (30 + sgn * stride * 10 + (k * 4 - 2), 70)
        s.line([hip, ((hip[0] + foot[0]) / 2 + 3, (hip[1] + foot[1]) / 2), foot], "stone_lt" if k else "stone", width=1)
        s.line([foot, (foot[0] + 4, foot[1])], "stone_lt")
    s.ellipse(28, by, 12, 7, "glass_dk")                                    # body
    s.ellipse(25, by - 2, 9, 4, "glass")
    s.poly([(16, by - 2), (6, by + 6), (18, by + 4)], "glass_dp")         # tail feathers
    hx, hy = 40 + neck, by - 22 + max(0, neck // 2)
    s.line([(36, by - 4), (38 + neck * 0.5, by - 14), (hx, hy)], "glass_lt", width=2)   # S neck
    s.ellipse(hx, hy, 4, 3, "glass_lt")
    s.poly([(hx + 3, hy - 1), (hx + 16, hy + 1), (hx + 3, hy + 2)], "amber")  # beak
    s.px(hx + 1, hy - 1, "sun", glow=True)
    for k in range(3):                                                     # drops rising off its back
        s.px(20 + k * 6, by - 10 - (i * 3 + k * 4) % 9, "glint", glow=k == 1)
    s.outline()
    s.recolor_edge(0, -1, "glint", only={"glass_dk", "glass"})
    return s


# ------------------------------------------------------------------ Bog Lurker: a lure on a stalk
def lurker(pose: str, i: int) -> Spr:
    """Something squat under the Saltmarsh mud with a lantern-lure on a stalk: what drowned travellers followed."""
    s = Spr(48, 52)
    sq = pick({"idle": (0, 1, 0, -1), "move": (1, 0, -1, 0), "attack": (-2, -3, 2)}, pose, i)
    sway = pick({"idle": (-1, 0, 1, 0), "move": (-2, -1, 0, -1), "attack": (2, 4, -2)}, pose, i)
    cx, base = 24, 49
    s.ellipse(cx, base - 8 + sq // 2, 15 + max(0, sq), 8 - sq // 2, "moss_dk")
    s.ellipse(cx - 3, base - 11, 9, 4, "moss")
    s.line([(cx + 4, base - 14), (cx + 8 + sway, base - 30), (cx + 2 + sway * 2, base - 40)], "moss_lt")   # stalk
    s.ellipse(cx + 2 + sway * 2, base - 42, 4, 4, "gold", glow=True)                                       # the lure
    s.ellipse(cx + 2 + sway * 2, base - 42, 2, 2, "sun", glow=True)
    open_ = 3 if pose == "attack" and i > 0 else 1
    s.poly([(cx - 12, base - 6), (cx + 12, base - 6), (cx + 10, base - 6 + open_), (cx - 10, base - 6 + open_)], "void")
    for x in range(cx - 10, cx + 11, 3):
        s.px(x, base - 6, "bone")
    s.px(cx - 6, base - 12, "amber", glow=True)
    s.px(cx + 2, base - 12, "amber", glow=True)
    s.outline()
    s.recolor_edge(0, -1, "moss_lt", only={"moss_dk", "moss"})
    return s


# ------------------------------------------------------------------ the Bellwright (Act 2 boss)
def bellwright(pose: str, i: int) -> Spr:
    """The Bellwright: a stooped giant in a drowned verdigris coat whose head is a bronze bell; the clapper hangs
    where a face should be, and two lights burn inside the bell's mouth. It holds the bell-rope in both hands. The
    sun's fear of the bell that rang it to sleep."""
    s = Spr(160, 176)
    bob = pick({"idle": (0, 1, 2, 1), "move": (0, 2, 0, 2), "attack": (2, -4, 6)}, pose, i)
    step = pick({"idle": 0, "move": (-1, 0, 1, 0), "attack": 0}, pose, i)
    cx, top = 80, 36 + bob
    for side in (-1, 1):                                                       # legs under the coat
        lift = 3 if step == side else 0
        s.rect(cx + side * 14 - 5, 150, cx + side * 14 + 5, 170 - lift, "ink")
        s.rect(cx + side * 14 - 7, 168 - lift, cx + side * 14 + 7, 172 - lift, "stone_dk")
    coat = [(cx - 24, top + 30), (cx + 24, top + 30), (cx + 40, 160), (cx - 40, 160)]
    s.poly(coat, "glass_dk")
    s.poly([(cx - 24, top + 30), (cx - 10, top + 30), (cx - 20, 160), (cx - 40, 160)], "glass_dp")
    s.poly([(cx + 14, top + 34), (cx + 24, top + 30), (cx + 40, 160), (cx + 28, 160)], "glass")
    for k in range(6):                                                        # barnacles and weed on the hem
        x = cx - 34 + k * 13
        s.ellipse(x, 154 - (k % 2) * 4, 3, 2, "pale")
        s.line([(x + 2, 158), (x + 1, 166)], "moss_lt")
    s.line([(cx, top + 34), (cx, 158)], "glass_dp")
    rope_y = (top + 70, top + 30, top + 96)[i] if pose == "attack" else top + 74 + bob
    s.line([(cx + 30, 0), (cx + 30, rope_y + 30)], "earth_lt", width=2)   # the bell-rope, from the dark above
    for side in (-1, 1):
        sh = (cx + side * 24, top + 36)
        hand = (cx + 30 + side * 4, rope_y)
        s.line([sh, ((sh[0] + hand[0]) / 2 + side * 8, (sh[1] + hand[1]) / 2), hand], "glass_dp", width=9)
        s.line([sh, ((sh[0] + hand[0]) / 2 + side * 8, (sh[1] + hand[1]) / 2), hand], "glass_dk", width=6)
        s.ellipse(hand[0], hand[1], 4, 4, "stone")
    bell = [(cx - 30, top + 34), (cx - 24, top + 26), (cx - 19, top + 6), (cx - 14, top - 4), (cx - 6, top - 9), (cx + 6, top - 9),
            (cx + 14, top - 4), (cx + 19, top + 6), (cx + 24, top + 26), (cx + 30, top + 34)]           # a flared bronze bell
    s.poly(bell, "rust")
    s.poly(bell[:5] + [(cx - 4, top - 9), (cx - 10, top + 34)], "ember_dk")
    s.poly([(cx + 8, top - 7), (cx + 14, top - 4), (cx + 19, top + 6), (cx + 23, top + 24), (cx + 16, top + 24), (cx + 12, top + 4)], "ember")
    s.line([(cx + 10, top - 4), (cx + 17, top + 22)], "amber")
    s.rect(cx - 31, top + 32, cx + 31, top + 36, "gold")
    s.line([(cx - 20, top + 16), (cx + 20, top + 16)], "ember_dk")
    s.line([(cx - 22, top + 19), (cx + 22, top + 19)], "amber")
    s.ellipse(cx, top + 35, 26, 4, "void")                                    # the mouth of the bell
    s.ellipse(cx - 7, top + 33, 2, 1, "amber", glow=True)
    s.ellipse(cx + 7, top + 33, 2, 1, "amber", glow=True)
    swing = (0, -3, 4)[i] if pose == "attack" else (0, 1, 0, -1)[i] if pose == "idle" else 0
    s.line([(cx, top + 34), (cx + swing, top + 48)], "stone_dk", width=2)    # the clapper
    s.ellipse(cx + swing, top + 50, 4, 4, "stone")
    s.rect(cx - 5, top - 15, cx + 5, top - 9, "ember_dk")
    s.ellipse(cx, top - 16, 6, 3, "rust")
    for k in range(4):                                                        # verdigris running down the bronze
        x = cx - 13 + k * 8
        s.line([(x, top + 2), (x - 1, top + 12 + (k % 2) * 6)], "glass")
    if pose == "attack" and i == 2:
        s.ellipse(cx, top + 34, 18, 3, "sun", glow=True)
    s.outline()
    s.recolor_edge(0, -1, "glint", only={"glass_dk", "glass"})
    s.recolor_edge(1, 0, "gold", only={"rust", "ember"})
    return s


# ------------------------------------------------------------------ Act 3: people of the loop
def _person_enemy(spec: dict, scale: float):
    """An enemy sheet (idle/move/attack rows) from the people builder: the loop's townsfolk are people, after all."""
    import people
    sp = dict(spec, scale=scale)

    def draw(pose: str, i: int) -> Spr:
        src = {"idle": ("idle", (0, 2, 4, 6)), "move": ("walk", (0, 2, 4, 6)), "attack": ("strike", (0, 1, 2))}[pose]
        return people.draw(sp, src[0], src[1][i])
    return draw


def mayor(pose: str, i: int) -> Spr:
    """The Mayor of Tuesday: a tall official in a frock coat and sash, a clock face for a head, a pocket watch the
    size of a plate in one hand, the chain wound round his wrist. The sun's fear of the day that never ended."""
    s = Spr(128, 160)
    bob = pick({"idle": (0, 1, 1, 0), "move": (0, 2, 0, 2), "attack": (1, -3, 3)}, pose, i)
    step = pick({"idle": 0, "move": (-1, 0, 1, 0), "attack": 0}, pose, i)
    cx, top = 64, 40 + bob
    _mayor_legs(s, cx, step)
    _mayor_coat(s, cx, top)
    arm = (cx + 30, top + 66) if pose != "attack" else ((cx + 34, top + 50), (cx + 36, top + 20), (cx + 30, top + 80))[i]
    _mayor_arms(s, cx, top, arm)
    _mayor_head(s, cx, top)
    s.outline()
    s.recolor_edge(-1, 0, "violet", only={"night", "ink", "dusk1"})
    s.recolor_edge(1, 0, "gold", only={"night", "dusk2", "dusk1"})
    return s


def _mayor_legs(s: Spr, cx: int, step: float) -> None:
    """Pinstriped trousers tapering into polished boots; the stepping boot lifts."""
    for side in (-1, 1):
        lift = 3 if step == side else 0
        x = cx + side * 10
        s.poly([(x - 5, 128), (x + 5, 128), (x + 4, 152 - lift), (x - 4, 152 - lift)], "ink")
        s.line([(x + side, 130), (x + side, 150 - lift)], "dusk1")
        s.poly([(x - 6, 151 - lift), (x + 5, 151 - lift), (x + 7 * side if side > 0 else x + 5, 156 - lift),
                (x - 7 if side < 0 else x - 6, 156 - lift)], "void")
        s.line([(x - 3, 152 - lift), (x + 2, 152 - lift)], "stone_dk")


def _mayor_coat(s: Spr, cx: int, top: int) -> None:
    """Frock coat: fitted at the waist, tails flaring and split, a rust waistcoat, lapels, sash and medal."""
    hem = 138
    s.poly([(cx - 22, top + 30), (cx + 22, top + 30), (cx + 17, top + 64), (cx + 32, hem), (cx - 32, hem), (cx - 17, top + 64)], "night")
    s.poly([(cx - 22, top + 30), (cx - 10, top + 30), (cx - 12, top + 64), (cx - 18, hem), (cx - 32, hem), (cx - 17, top + 64)], "ink")
    s.poly([(cx + 14, top + 32), (cx + 22, top + 30), (cx + 17, top + 64), (cx + 32, hem), (cx + 24, hem), (cx + 13, top + 64)], "dusk2")
    s.poly([(cx - 3, top + 66), (cx + 3, top + 66), (cx + 6, hem), (cx - 6, hem)], "void")            # the split between the tails
    for fx in (-22, -9, 10, 21):
        s.line([(cx + fx * 0.6, top + 70), (cx + fx, hem - 2)], "dusk1")                          # folds
    s.poly([(cx - 9, top + 30), (cx + 9, top + 30), (cx + 7, top + 66), (cx - 7, top + 66)], "ember_dk")  # waistcoat
    s.line([(cx + 3, top + 32), (cx + 3, top + 64)], "rust")
    for k in range(4):
        s.px(cx, top + 38 + k * 8, "gold")
    s.poly([(cx - 10, top + 30), (cx - 4, top + 30), (cx - 8, top + 52)], "dusk1")                  # lapels
    s.poly([(cx + 4, top + 30), (cx + 10, top + 30), (cx + 8, top + 52)], "dusk3")
    s.poly([(cx - 20, top + 34), (cx - 14, top + 34), (cx + 18, top + 80), (cx + 12, top + 82)], "blood")    # the mayoral sash
    s.line([(cx - 14, top + 34), (cx + 18, top + 80)], "rose")
    s.line([(cx - 20, top + 35), (cx + 12, top + 82)], "ember_dk")
    s.ellipse(cx + 4, top + 58, 4, 4, "amber")
    s.ellipse(cx + 3, top + 57, 2.5, 2.5, "gold")
    s.poly([(cx + 2, top + 62), (cx + 6, top + 62), (cx + 7, top + 68), (cx + 4, top + 66), (cx + 1, top + 68)], "blood")  # ribbon


def _mayor_arms(s: Spr, cx: int, top: int, arm: tuple[int, int]) -> None:
    """Sleeves with white cuffs and dark gloves; the right hand holds out the great pocket watch on its chain."""
    s.line([(cx + 20, top + 34), arm], "dusk1", width=8)
    s.line([(cx + 22, top + 36), (arm[0] + 2, arm[1])], "dusk2", width=3)
    s.line([(cx - 20, top + 34), (cx - 26, top + 74)], "ink", width=8)
    s.rect(cx - 30, top + 72, cx - 22, top + 75, "pale")
    s.ellipse(cx - 26, top + 79, 4, 4, "stone_dk")
    s.rect(arm[0] - 4, arm[1] - 2, arm[0] + 4, arm[1] + 1, "pale")
    s.line([(arm[0] - 6, arm[1]), (cx + 20, top + 40)], "gold")                 # chain
    clock_dial(s, arm[0], arm[1] + 8, 9)                                         # the great pocket watch
    s.px(arm[0], arm[1] + 8, "rose", glow=True)


def _mayor_head(s: Spr, cx: int, top: int) -> None:
    """High starched collar, a clock face for a head, and a tall hat with a blood-red band."""
    s.poly([(cx - 12, top + 22), (cx + 12, top + 22), (cx + 20, top + 32), (cx - 20, top + 32)], "bone")  # high collar
    s.poly([(cx - 20, top + 32), (cx - 12, top + 22), (cx - 9, top + 22), (cx - 14, top + 32)], "pale")
    s.poly([(cx - 6, top + 22), (cx + 6, top + 22), (cx, top + 32)], "night")
    s.poly([(cx - 3, top + 24), (cx + 3, top + 24), (cx, top + 30)], "blood")   # cravat
    clock_dial(s, cx, top + 10, 14)                                             # clock-face head
    s.ellipse(cx, top + 10, 2, 2, "rose", glow=True)
    s.poly([(cx - 11, top - 22), (cx + 11, top - 22), (cx + 12, top - 4), (cx - 12, top - 4)], "void")  # top hat
    s.line([(cx - 9, top - 20), (cx - 10, top - 6)], "stone_dk")
    s.line([(cx + 8, top - 20), (cx + 9, top - 6)], "night")
    s.ellipse(cx, top - 4, 19, 2.5, "void")
    s.rect(cx - 12, top - 10, cx + 12, top - 7, "blood")
    s.line([(cx - 11, top - 10), (cx + 11, top - 10)], "rose")


KINDS = {"gloam": (gloam, 48, 48), "hound": (hound, 64, 48), "moth": (moth, 64, 56), "glazier": (glazier, 128, 128), "husk": (husk, 64, 64),
         "crawler": (crawler, 48, 40), "matron": (matron, 176, 160),
         "undertow": (undertow, 64, 64), "drowned": (drowned_lantern, 48, 56),
         "bellwright": (bellwright, 160, 176), "heron": (heron, 64, 72), "lurker": (lurker, 48, 52),
         "mayor": (mayor, 128, 160)}


def _late_kinds() -> None:
    """Kinds built from people (imported lazily: people imports pix too)."""
    import people
    KINDS["repeater"] = (_person_enemy(people.REPEATER, 1.0), 64, 64)
    KINDS["clockface"] = (_person_enemy(people.CLOCKFACE, 1.0), 64, 64)


_late_kinds()
