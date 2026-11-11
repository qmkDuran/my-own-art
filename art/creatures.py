"""Creatures of the trainer prototype, drawn side-on (facing right) in a 56 x 48 frame with the feet on one line.
Each animal is built from its real silhouette first (the honey badger's pale mantle, the cuttlefish's fin skirt and
W eye, the pangolin's scale rows, the maned wolf's stilt legs and ears, the aye-aye's ears and long finger, the
devil's big jaw and white chest stripe), then given its element's accent. Colours go through a role map so a shiny
form is the same drawing with another map. Poses: idle (breath), move (gait), act (crouch, then lunge)."""
from __future__ import annotations

import math

from PIL import Image, ImageChops, ImageDraw

from pix import Spr

W, H = 56, 48
FEET = 44
POSES = {"idle": 4, "move": 4, "act": 2}


class Pose:
    """Per-frame offsets: body bob, the leg phase of a gait, and how far an attack leans in."""

    def __init__(self, pose: str, i: int) -> None:
        self.pose, self.i = pose, i
        self.bob = 0
        self.phase = 0.0
        self.lean = 0
        self.open = False
        if pose == "idle":
            self.bob = (0, 0, 1, 1)[i]
        elif pose == "move":
            self.bob = (0, 1, 0, 1)[i]
            self.phase = i / 4.0
        elif pose == "act":
            self.bob = (2, 0)[i]
            self.lean = (-2, 4)[i]
            self.open = i == 1

    def stride(self, offset: float, reach: float) -> float:
        """A leg's forward swing in the gait (0 when standing)."""
        if self.pose != "move":
            return 0.0
        return math.sin((self.phase + offset) * math.tau) * reach

    def lift(self, offset: float) -> int:
        if self.pose != "move":
            return 0
        return 1 if math.cos((self.phase + offset) * math.tau) > 0.3 else 0


def _leg(s: Spr, top: tuple[float, float], dx: float, lift: int, col: str, paw: str, width: int = 3) -> None:
    x, y = top
    fx = x + dx
    s.line([(x, y), (fx, FEET - 1 - lift)], col, width)
    s.rect(fx - 1, FEET - 1 - lift, fx + width - 1, FEET - lift, paw)


def _finish(s: Spr, cool: str, warm: str, body: set[str]) -> Spr:
    s.outline()
    s.recolor_edge(0, -1, cool, only=body)
    s.recolor_edge(1, 0, warm, only=body)
    return s


# ---------------------------------------------------------------- honey badger (Ember): low, black, a pale mantle
BADGER = {"fur": "ink", "fur_lt": "night", "mantle": "bone", "mantle_lt": "sun", "claw": "amber", "eye": "flame",
          "ember": "flame", "rim": "dusk3"}
BADGER_SHINY = {**BADGER, "fur": "ember_dk", "fur_lt": "rust", "mantle": "gold", "mantle_lt": "sun", "eye": "glint",
                "ember": "sun"}


def honey_badger(p: Pose, c: dict) -> Spr:
    s = Spr(W, H)
    ox, top = 5 + p.lean, 26 + p.bob
    for k, (lx, off) in enumerate(((10, 0.0), (15, 0.5), (29, 0.5), (34, 0.0))):
        _leg(s, (ox + lx, top + 9), p.stride(off, 3), p.lift(off), c["fur"] if k % 2 else c["fur_lt"], c["claw"], 4)
    s.poly([(ox + 5, top + 3), (ox, top - 3), (ox + 2, top + 5)], c["fur"])                          # short tail
    s.ellipse(ox + 20, top + 5, 16, 7, c["fur"])                                                   # black body
    s.poly([(ox + 5, top + 2), (ox + 10, top - 2), (ox + 30, top - 2), (ox + 40, top + 1), (ox + 40, top + 4),
            (ox + 30, top + 3), (ox + 10, top + 4)], c["mantle"])                                  # the pale mantle
    s.line([(ox + 10, top - 2), (ox + 31, top - 2)], c["mantle_lt"])
    hy = top + 4 + (2 if p.pose == "act" and p.i == 0 else 0)
    s.ellipse(ox + 41, hy + 1, 6, 5, c["fur"])                                                     # head, low and forward
    s.poly([(ox + 37, hy - 4), (ox + 44, hy - 3), (ox + 46, hy), (ox + 37, hy)], c["mantle"])    # the cap runs onto it
    s.poly([(ox + 45, hy), (ox + 51, hy + 2), (ox + 50, hy + 4), (ox + 45, hy + 5)], c["fur_lt"])  # snout
    s.px(ox + 51, hy + 2, "ink")
    s.px(ox + 43, hy + 1, c["eye"], glow=True)
    if p.open:
        s.line([(ox + 46, hy + 5), (ox + 51, hy + 6)], "rose")
        s.px(ox + 50, hy + 5, "bone")
    for k in range(4):                                                                             # embers in the mantle
        s.px(ox + 12 + k * 6 + (p.i % 2), top - 1 + (k % 2), c["ember"], glow=True)
    return _finish(s, c["rim"], c["mantle_lt"], {c["fur"], c["fur_lt"]})


# ---------------------------------------------------------------- cuttlefish (Glass): a floating mantle and fin skirt
CUTTLE = {"body_dk": "glass_dk", "body": "glass", "body_lt": "glass_lt", "fin": "glint", "spot": "glint", "eye": "bone",
          "pupil": "ink", "arm": "glass_lt", "rim": "glint"}
CUTTLE_SHINY = {**CUTTLE, "body_dk": "violet", "body": "violet_lt", "body_lt": "pale", "fin": "rose", "spot": "gold",
                "arm": "pale", "rim": "bone"}


def cuttlefish(p: Pose, c: dict) -> Spr:
    s = Spr(W, H)
    ox, cy = 6 + p.lean, 26 + p.bob
    wave = p.i * 1.6
    for k in range(13):                                                                            # rippling fin skirt
        x = ox + 6 + k * 2.2
        up = 1.5 * math.sin(k * 0.9 + wave)
        s.ellipse(x, cy - 7 + up, 1.6, 1.6, c["fin"])
        s.ellipse(x, cy + 7 - up, 1.6, 1.6, c["fin"])
    s.ellipse(ox + 20, cy, 15, 7, c["body"])                                                       # the mantle
    s.ellipse(ox + 20, cy - 2, 13, 4, c["body_lt"])
    s.line([(ox + 8, cy + 4), (ox + 32, cy + 5)], c["body_dk"])
    for k in range(6):                                                                             # flickering spots
        sx = ox + 10 + (k * 7 + p.i * 3) % 22
        s.px(sx, cy - 2 + (k % 3), c["spot"], glow=(k + p.i) % 2 == 0)
    s.ellipse(ox + 36, cy + 1, 5, 5, c["body"])                                                    # head
    s.ellipse(ox + 36, cy - 1, 3, 2.5, c["eye"])                                                   # the W eye
    s.line([(ox + 34, cy - 2), (ox + 35, cy), (ox + 36, cy - 1), (ox + 37, cy), (ox + 38, cy - 2)], c["pupil"])
    reach = 4 if p.open else 0
    for k in range(5):                                                                             # arms, bunched forward
        y0 = cy - 2 + k * 1.5
        tip = ox + 49 + reach - abs(k - 2) * 2
        curl = 1.5 * math.sin(p.i * 1.3 + k)
        s.line([(ox + 39, y0), (tip, y0 - 2 + k + curl)], c["arm"] if k % 2 == 0 else c["body"], 2)
    s.line([(ox + 40, cy + 3), (ox + 52 + reach * 2, cy + 7)], c["body_lt"])                     # a tentacle
    return _finish(s, c["rim"], c["fin"], {c["body"], c["body_dk"]})


# ---------------------------------------------------------------- pangolin (Bloom): arched back of scale rows
PANGOLIN = {"scale_dk": "earth_dk", "scale": "earth_lt", "edge": "leaf_lt", "leaf": "leaf", "skin": "skin_dk",
            "skin_lt": "skin", "claw": "bone", "rim": "leaf_lt"}
PANGOLIN_SHINY = {**PANGOLIN, "scale_dk": "amber", "scale": "gold", "edge": "sun", "leaf": "rose", "rim": "sun"}


def pangolin(p: Pose, c: dict) -> Spr:
    s = Spr(W, H)
    ox, top = 5 + p.lean, 21 + p.bob
    for lx, off in ((15, 0.0), (31, 0.5)):
        _leg(s, (ox + lx, top + 15), p.stride(off, 2), p.lift(off), c["skin"], c["claw"], 3)
    s.poly([(ox + 12, top + 10), (ox + 3, top + 16), (ox - 3, top + 22), (ox + 1, top + 23), (ox + 8, top + 20),
            (ox + 15, top + 17)], c["scale_dk"])                                                                          # the long tail
    s.ellipse(ox + 22, top + 12, 15, 11, c["scale_dk"])                                           # arched body
    s.rect(ox + 9, top + 13, ox + 36, top + 17, c["scale_dk"])
    _scales(s, c, (ox + 22, top + 12), (15, 11))
    for k in range(3):                                                                             # scales down the tail
        s.px(ox + 2 + k * 4, top + 20 - k * 2, c["scale"])
        s.px(ox + 3 + k * 4, top + 21 - k * 2, c["edge"])
    hy = top + 14
    s.poly([(ox + 34, hy - 4), (ox + 41, hy - 2), (ox + 49, hy + 2), (ox + 41, hy + 4), (ox + 34, hy + 4)], c["skin"])
    s.line([(ox + 41, hy + 3), (ox + 48, hy + 2)], c["skin_lt"])
    s.px(ox + 40, hy - 1, "ink")
    for k, (lx, off) in enumerate(((36, 0.25), (24, 0.75))):                                      # forelegs and claws
        _leg(s, (ox + lx, top + 16), p.stride(off, 2), p.lift(off), c["skin"], c["claw"], 2)
    s.line([(ox + 21, top), (ox + 23, top - 4)], c["leaf"])                                       # a sprout on its back
    s.ellipse(ox + 25, top - 5, 2, 1, c["leaf"], glow=True)
    return _finish(s, c["rim"], c["edge"], {c["scale_dk"], c["skin"]})


def _scales(s: Spr, c: dict, centre: tuple[float, float], radii: tuple[float, float]) -> None:
    """Overlapping plates in rows (upper rows over lower), clipped to the arched body so the silhouette stays round."""
    cx, cy = centre
    plates = Spr(W, H)
    for row in range(5, -1, -1):
        y = cy - radii[1] + row * 4
        for k in range(7):
            x = cx - radii[0] + 2 + k * 5 + (row % 2) * 2.5
            plates.poly([(x - 3, y), (x + 3, y), (x + 3, y + 3), (x, y + 5), (x - 3, y + 3)], c["scale"])
            plates.line([(x - 3, y + 3), (x, y + 5), (x + 3, y + 3)], c["scale_dk"])
            plates.px(x - 1, y + 1, c["skin_lt"])
    mask = Image.new("L", (W, H), 0)
    ImageDraw.Draw(mask).ellipse([cx - radii[0] + 1, cy - radii[1] + 1, cx + radii[0] - 1, cy + radii[1] - 1], fill=255)
    clip = ImageChops.multiply(mask, plates.img.getchannel("A"))
    s.img.paste(plates.img, (0, 0), clip)


# ---------------------------------------------------------------- maned wolf (Gale): fox head, stilt legs, black mane
WOLF = {"coat_dk": "rust", "coat": "flame", "coat_lt": "amber", "stock": "ink", "mane": "night", "white": "bone",
        "ear_in": "skin_lt", "eye": "gold", "wind": "pale", "rim": "gold"}
WOLF_SHINY = {**WOLF, "coat_dk": "mist", "coat": "pale", "coat_lt": "bone", "mane": "violet", "stock": "dusk1",
              "eye": "glint", "wind": "glint", "rim": "sun"}


def maned_wolf(p: Pose, c: dict) -> Spr:
    s = Spr(W, H)
    ox, top = 4 + p.lean, 16 + p.bob
    for k, (lx, off) in enumerate(((14, 0.5), (32, 0.0), (17, 0.0), (35, 0.5))):
        col = c["coat_dk"] if k < 2 else c["coat"]
        s.line([(ox + lx, top + 8), (ox + lx, top + 15)], col, 3)
        _leg(s, (ox + lx, top + 14), p.stride(off, 4), p.lift(off), c["stock"], c["stock"], 2)
    s.poly([(ox + 9, top + 4), (ox + 3, top + 12), (ox + 2, top + 20), (ox + 6, top + 16), (ox + 11, top + 8)],
           c["coat"])                                                                              # bushy tail
    s.ellipse(ox + 3, top + 19, 2, 2, c["white"])
    s.ellipse(ox + 24, top + 6, 15, 6, c["coat"])                                                  # body
    s.line([(ox + 12, top + 10), (ox + 34, top + 11)], c["coat_lt"])
    s.poly([(ox + 33, top + 4), (ox + 37, top - 7), (ox + 42, top - 6), (ox + 40, top + 7)], c["coat"])   # neck
    s.poly([(ox + 30, top + 1), (ox + 35, top - 8), (ox + 38, top - 7), (ox + 35, top + 2)], c["mane"])  # the mane
    hy = top - 9 + (2 if p.pose == "act" and p.i == 0 else 0)
    s.ellipse(ox + 41, hy, 4.5, 4, c["coat"])                                                      # head
    s.poly([(ox + 43, hy - 2), (ox + 51, hy + 1), (ox + 50, hy + 3), (ox + 43, hy + 3)], c["coat"])  # long snout
    s.poly([(ox + 48, hy + 1), (ox + 52, hy + 2), (ox + 50, hy + 4), (ox + 47, hy + 3)], c["mane"])  # black muzzle
    s.px(ox + 52, hy + 2, "ink")
    s.poly([(ox + 36, hy - 2), (ox + 36, hy - 11), (ox + 40, hy - 3)], c["coat_dk"])            # far ear
    s.poly([(ox + 39, hy - 2), (ox + 41, hy - 13), (ox + 45, hy - 2)], c["coat"])               # near ear, tall
    s.line([(ox + 41, hy - 4), (ox + 41, hy - 10)], c["ear_in"])
    s.line([(ox + 41, hy + 4), (ox + 39, hy + 7)], c["white"])                                    # pale throat
    s.px(ox + 44, hy - 1, c["eye"], glow=True)
    if p.open:
        s.line([(ox + 46, hy + 4), (ox + 51, hy + 5)], "rose")
    for k in range(2):                                                                             # wind at its heels
        wx = ox + 4 + k * 20 + p.i * 2 % 6
        s.line([(wx, FEET - 3 - k * 4), (wx + 5, FEET - 3 - k * 4)], c["wind"], glow=True)
    return _finish(s, c["rim"], c["coat_lt"], {c["coat"], c["coat_dk"]})


# ---------------------------------------------------------------- aye-aye (Echo): huge ears and eyes, a long finger
AYE = {"fur_dk": "ink", "fur": "night", "fur_lt": "dusk2", "guard": "mist", "ear": "dusk1", "ear_in": "violet_lt",
       "eye": "amber", "pupil": "ink", "finger": "pale", "nose": "rose", "rim": "violet_lt"}
AYE_SHINY = {**AYE, "fur_dk": "stone", "fur": "pale", "fur_lt": "bone", "guard": "sun", "ear": "stone_lt", "eye": "glint",
             "rim": "sun"}


def aye_aye(p: Pose, c: dict) -> Spr:
    s = Spr(W, H)
    ox, top = 6 + p.lean, 22 + p.bob
    for k in range(6):                                                                             # the bushy tail, up
        s.ellipse(ox + 9 - k * 1.5, top + 4 - k * 3.5, 3.5 + k * 0.3, 3.5, c["fur"])
        s.px(ox + 7 - k * 1.5, top + 3 - k * 3.5, c["guard"])
    for lx, off in ((12, 0.0), (20, 0.5)):
        _leg(s, (ox + lx, top + 12), p.stride(off, 3), p.lift(off), c["fur_dk"], c["fur_dk"], 3)
    s.ellipse(ox + 18, top + 8, 11, 8, c["fur"])                                                   # hunched body
    for k in range(7):
        s.px(ox + 10 + k * 3, top + 2 + (k * 5) % 4, c["guard"])
    fx = 4 if p.open else 0                                                                        # the long finger
    s.line([(ox + 28, top + 10), (ox + 33, FEET - 3 - fx // 2)], c["fur_dk"], 2)
    s.line([(ox + 33, FEET - 3 - fx // 2), (ox + 40 + fx, FEET - 6 - fx)], c["finger"])
    s.rect(ox + 31, FEET - 1, ox + 34, FEET, c["fur_dk"])
    hy = top - 1
    s.ellipse(ox + 33, hy, 7, 6, c["fur_lt"])                                                      # face
    for ex, ey in ((26, -9), (36, -10)):                                                           # huge ears
        s.ellipse(ox + ex, hy + ey, 5, 6.5, c["ear"])
        s.ellipse(ox + ex, hy + ey + 1, 3, 4.5, c["ear_in"])
    s.ellipse(ox + 33, hy, 7, 6, c["fur_lt"])
    for ex in (31, 37):
        s.ellipse(ox + ex, hy - 1, 2.5, 2.5, c["eye"], glow=True)
        s.px(ox + ex, hy - 1, c["pupil"])
    s.px(ox + 39, hy + 2, c["nose"])
    s.line([(ox + 33, hy + 4), (ox + 36, hy + 4)], c["fur_dk"])
    return _finish(s, c["rim"], c["guard"], {c["fur"], c["fur_dk"]})


# ---------------------------------------------------------------- Tasmanian devil (Rot): black, big jaw, chest stripe
DEVIL = {"fur": "ink", "fur_lt": "night", "stripe": "bone", "ear": "rose", "mouth": "blood", "teeth": "bone",
         "eye": "bile", "drool": "bile", "rim": "dusk3"}
DEVIL_SHINY = {**DEVIL, "fur": "violet", "fur_lt": "violet_lt", "stripe": "bile", "eye": "gold", "rim": "pale"}


def tas_devil(p: Pose, c: dict) -> Spr:
    s = Spr(W, H)
    ox, top = 7 + p.lean, 26 + p.bob
    for k, (lx, off) in enumerate(((9, 0.0), (13, 0.5), (27, 0.5), (31, 0.0))):
        _leg(s, (ox + lx, top + 8), p.stride(off, 3), p.lift(off), c["fur"] if k % 2 else c["fur_lt"], c["fur"], 4)
    s.poly([(ox + 5, top + 3), (ox - 2, top + 6), (ox + 1, top + 9), (ox + 6, top + 8)], c["fur"])  # thick tail
    s.ellipse(ox + 19, top + 4, 14, 8, c["fur"])                                                   # stocky body
    s.ellipse(ox + 8, top + 1, 3, 2, c["stripe"])                                                  # rump patch
    s.poly([(ox + 26, top - 3), (ox + 29, top - 3), (ox + 27, top + 11), (ox + 24, top + 11)], c["stripe"])  # chest band
    hy = top - 1 + (2 if p.pose == "act" and p.i == 0 else 0)
    s.ellipse(ox + 35, hy + 1, 8, 7, c["fur"])                                                     # the big head
    for ex in (30, 36):                                                                            # pink round ears
        s.ellipse(ox + ex, hy - 5, 2.5, 3, c["fur"])
        s.ellipse(ox + ex, hy - 5, 1.5, 2, c["ear"])
    s.poly([(ox + 39, hy - 1), (ox + 46, hy + 1), (ox + 46, hy + 3), (ox + 39, hy + 3)], c["fur_lt"])  # muzzle
    gape = 4 if p.open else 1
    s.poly([(ox + 38, hy + 3), (ox + 46, hy + 3), (ox + 45, hy + 3 + gape), (ox + 38, hy + 5)], c["mouth"])
    for tx in (40, 43):
        s.px(ox + tx, hy + 3, c["teeth"])
        if p.open:
            s.px(ox + tx + 1, hy + 3 + gape - 1, c["teeth"])
    s.px(ox + 46, hy, "ink")
    s.px(ox + 37, hy - 1, c["eye"], glow=True)
    s.px(ox + 44, hy + 6 + p.i % 2, c["drool"], glow=True)
    return _finish(s, c["rim"], c["fur_lt"], {c["fur"], c["fur_lt"]})


# species id -> (draw, normal colours, shiny colours, floats above the ground)
SPECIES = {
    "honey_badger": (honey_badger, BADGER, BADGER_SHINY, False),
    "cuttlefish": (cuttlefish, CUTTLE, CUTTLE_SHINY, True),
    "pangolin": (pangolin, PANGOLIN, PANGOLIN_SHINY, False),
    "maned_wolf": (maned_wolf, WOLF, WOLF_SHINY, False),
    "aye_aye": (aye_aye, AYE, AYE_SHINY, False),
    "tas_devil": (tas_devil, DEVIL, DEVIL_SHINY, False),
}


def frames(species: str, shiny: bool) -> list[list[Spr]]:
    draw, normal, rare, _ = SPECIES[species]
    cols = rare if shiny else normal
    return [[draw(Pose(pose, i), cols) for i in range(n)] for pose, n in POSES.items()]
