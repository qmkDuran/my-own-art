"""Front-facing 64 px people: the Lamplighter and the NPCs, all from one parametric figure so they share proportions,
lighting (cool rim on the left, warm lantern rim on the right) and outline, but differ in silhouette: hats, hoods,
coats, held props and accent colours. A spec is a dict (see SPECS); frames are drawn per pose."""
from __future__ import annotations

from pix import Spr, clock_dial

FEET = 61
CX = 32

# poses: name -> number of frames
POSES = {"idle": 8, "walk": 8, "strike": 4, "cast": 3, "hurt": 1}
BLINK = 6                                   # the idle frame where eyes close
ARM_SWING = (-2, -1, 0, 1, 2, 1, 0, -1)     # walk: the left hand's swing (the right one swings opposite)


class Fig:
    """Geometry for one frame: scale (child/adult), bob and sway, mapped around the feet line."""

    def __init__(self, spec: dict, pose: str, i: int) -> None:
        self.spec, self.pose, self.i = spec, pose, i
        self.k = spec.get("scale", 1.0)
        self.wk = spec.get("width", 1.0)
        self.bob = 0
        self.sway = 0
        self.step = 0      # -1 left foot forward, +1 right
        if pose == "idle":                  # slow breath: rise and settle, the coat swaying a pixel either way
            self.bob = (0, 0, 1, 1, 1, 1, 0, 0)[i]
            self.sway = (0, 0, 1, 1, 0, 0, -1, -1)[i]
        elif pose == "walk":                # two steps: down on each contact, the hem swinging with the stride
            self.bob = (1, 0, 0, 0, 1, 0, 0, 0)[i]
            self.sway = (-1, -1, 0, 1, 1, 1, 0, -1)[i]
            self.step = (-1, -1, -1, 0, 1, 1, 1, 0)[i]
        elif pose == "hurt":
            self.bob = 1

    def y(self, y: float) -> float:
        return FEET - (FEET - y) * self.k + self.bob * (1 if y < 50 else 0)

    def x(self, dx: float) -> float:
        return CX + dx * self.wk


def _legs(s: Spr, f: Fig) -> None:
    sp = f.spec
    for side in (-1, 1):
        lift = 1 if f.step == side else 0
        x0 = f.x(side * 4) - 2
        top = f.y(sp.get("hem", 56)) - 2
        s.rect(x0, top, x0 + 3, FEET - 3 - lift, sp.get("legs", "ink"))
        s.rect(x0 - (1 if side < 0 else 0), FEET - 3 - lift, x0 + 3 + (1 if side > 0 else 0), FEET - lift, sp.get("boots", "earth_dk"))
        s.px(x0 + (3 if side > 0 else 0), FEET - 3 - lift, sp.get("boot_hi", "earth"))


def _coat(s: Spr, f: Fig) -> None:
    sp = f.spec
    dk, base, lt = sp["coat"]
    sh, wa, hem = f.y(23), f.y(36), f.y(sp.get("hem", 56))
    hw = sp.get("hem_w", 13)
    sw = 10 * f.wk
    body = [(CX - sw, sh), (CX + sw, sh), (f.x(8) , wa), (f.x(hw) + f.sway, hem), (f.x(-hw) + f.sway, hem), (f.x(-8), wa)]
    s.poly(body, base)
    # folds: a darker left panel and centre seam, a lighter right panel (lit by the lantern side)
    s.poly([(CX - sw, sh), (CX - sw + 3, sh), (f.x(-4), wa), (f.x(-hw + 4) + f.sway, hem), (f.x(-hw) + f.sway, hem), (f.x(-8), wa)], dk)
    s.poly([(CX + sw - 2, sh + 1), (CX + sw, sh), (f.x(8), wa), (f.x(hw) + f.sway, hem), (f.x(hw - 3) + f.sway, hem), (f.x(6), wa)], lt)
    if sp.get("split", True):     # coat tails part below the belt
        s.poly([(f.x(0), wa + 4), (f.x(2) + f.sway, hem), (f.x(-2) + f.sway, hem)], sp.get("legs", "ink"))
    s.line([(CX, sh + 2), (CX, wa)], dk)
    for by in sp.get("buttons", []):
        s.px(CX + 1, f.y(by), sp.get("trim", "amber"))
    s.poly([(CX - 5, sh), (CX + 5, sh), (CX, sh + 7)], sp.get("collar", dk))          # lapels open to a V
    s.poly([(CX - 3, sh), (CX + 3, sh), (CX, sh + 4)], sp.get("shirt", "bone" if not sp.get("scarf") else dk))
    s.line([(f.x(-hw) + f.sway, hem - 1), (f.x(hw) + f.sway, hem - 1)], sp.get("hem_trim", dk))
    if sp.get("tatters"):
        for k in range(-hw, hw + 1, 3):
            s.px(f.x(k) + f.sway, hem + 1, base)
            s.px(f.x(k + 1) + f.sway, hem + 2, base)
    if sp.get("belt"):
        s.rect(f.x(-8), wa - 1, f.x(8), wa + 1, sp["belt"])
        s.rect(CX - 1, wa - 1, CX + 1, wa + 1, sp.get("trim", "amber"))
    if sp.get("apron"):
        s.poly([(f.x(-6), wa), (f.x(6), wa), (f.x(7), hem - 2), (f.x(-7), hem - 2)], sp["apron"])
        s.line([(f.x(-6), wa + 3), (f.x(6), wa + 3)], "earth_dk")


def _arm(s: Spr, f: Fig, side: int, hand: tuple[float, float]) -> None:
    sp = f.spec
    dk, base, lt = sp["coat"]
    shoulder = (CX + side * 10 * f.wk, f.y(24))
    s.line([shoulder, hand], dk if side < 0 else base, width=4)
    s.line([(shoulder[0] + side, shoulder[1] - 1), (hand[0] + side, hand[1] - 3)], base if side < 0 else lt)
    s.rect(hand[0] - 2, hand[1] - 3, hand[0] + 2, hand[1] - 2, sp.get("cuff", dk))
    s.rect(hand[0] - 1, hand[1] - 1, hand[0] + 1, hand[1] + 1, sp.get("glove", sp.get("skin", "skin")))


def _hands(f: Fig) -> tuple[tuple[float, float], tuple[float, float]]:
    """(left-of-screen hand, right-of-screen hand) for the pose."""
    sw = 10 * f.wk
    left = (CX - sw - 2, f.y(39))
    right = (CX + sw + 2, f.y(38))
    if f.pose == "walk":                    # arms counter-swing (forward = a little up and in)
        a = ARM_SWING[f.i]
        left = (left[0] + a * 0.5, left[1] - abs(a) * 0.5 + a)
        right = (right[0] - a * 0.5, right[1] - abs(a) * 0.5 - a)
    elif f.pose == "idle":
        left = (left[0], left[1] + (0, 0, 0, 1, 1, 0, 0, 0)[f.i])
    elif f.pose == "strike" and f.spec.get("held_r") == "pole":
        right = ((CX + sw + 3, f.y(36)), (CX + sw + 5, f.y(33)), (CX + sw + 4, f.y(36)), (CX + sw + 2, f.y(38)))[f.i]
        left = ((CX - sw - 3, f.y(30)), (CX - sw - 9, f.y(27)), (CX - sw - 6, f.y(33)), (CX - sw - 3, f.y(37)))[f.i]
    elif f.pose == "strike":
        left = ((CX - sw - 4, f.y(14)), (CX - sw - 10, f.y(24)), (CX - sw - 8, f.y(34)), (CX - sw - 3, f.y(37)))[f.i]
    elif f.pose == "cast" and f.spec.get("held_r") == "pole":
        right = ((CX + sw + 3, f.y(36)), (CX + sw + 3, f.y(33)), (CX + sw + 3, f.y(33)))[f.i]
        left = ((CX - sw - 3, f.y(33)), (CX - sw - 6, f.y(27)), (CX - sw - 7, f.y(25)))[f.i]
    elif f.pose == "cast":
        right = ((CX + sw + 4, f.y(26)), (CX + sw + 3, f.y(12)), (CX + sw + 3, f.y(10)))[f.i]
        left = ((CX - sw - 3, f.y(33)), (CX - sw - 5, f.y(28)), (CX - sw - 5, f.y(27)))[f.i]
    elif f.pose == "hurt":
        left, right = (CX - sw - 4, f.y(30)), (CX + sw + 4, f.y(30))
    return left, right


def _lantern(s: Spr, x: float, y: float, big: bool = True) -> None:
    """The iron lantern hanging from a hand at (x, y): ring, cap, frame, a sun-bright pane (emissive)."""
    w = 4 if big else 3
    s.line([(x, y), (x, y + 2)], "stone_dk")
    s.rect(x - w + 1, y + 2, x + w - 1, y + 3, "ink")
    s.rect(x - w, y + 4, x + w, y + 12, "ink")
    s.rect(x - w + 1, y + 5, x + w - 1, y + 11, "amber", glow=True)
    s.rect(x - w + 2, y + 6, x + w - 2, y + 10, "gold", glow=True)
    s.rect(x - 1, y + 7, x + 1, y + 9, "sun", glow=True)
    s.line([(x, y + 4), (x, y + 12)], "ink")
    s.rect(x - w + 1, y + 13, x + w - 1, y + 13, "stone_dk")


def _held(s: Spr, f: Fig, item: str, hand: tuple[float, float]) -> None:
    x, y = hand
    if item == "lantern":
        _lantern(s, x, y + 1)
    elif item == "small_lantern":
        _lantern(s, x, y + 1, big=False)
    elif item == "pole":                     # the lantern staff: a hooked staff, the lantern hanging from its crook
        tilt = {"strike": (2, 7, 4, 1), "cast": (0, 1, 1)}.get(f.pose, (0,) * 8)[f.i]
        top = (x + 1 + tilt, max(3.0, y - 30))
        s.line([(x, y + 12), top], "earth_dk", width=2)
        s.line([(x + 1, y + 12), (top[0] + 1, top[1])], "earth")
        s.line([top, (top[0] + 2, top[1] - 3), (top[0] + 6, top[1] - 3), (top[0] + 7, top[1])], "stone_lt")
        s.rect(x - 1, y - 2, x + 1, y + 2, "stone_dk")
        _lantern(s, top[0] + 7, top[1])
    elif item == "whip":
        s.line([(x, y), (x - 3, y - 4)], "earth_dk", width=2)
        s.line([(x - 3, y - 4), (x - 9, y - 9), (x - 14, y - 6)], "earth_lt")
    elif item == "pipe":
        s.line([(x, y), (x + 3, y - 2)], "earth_dk")
        s.px(x + 4, y - 3, "ember", glow=True)
    elif item == "hammer":
        s.line([(x, y + 6), (x, y - 10)], "earth")
        s.rect(x - 4, y - 14, x + 4, y - 9, "stone_lt")
        s.rect(x - 4, y - 10, x + 4, y - 9, "stone")
    elif item == "pike":
        s.line([(x, y + 14), (x, y - 30)], "earth_lt")
        s.poly([(x - 2, y - 30), (x + 2, y - 30), (x, y - 37)], "stone_lt")
        s.rect(x - 3, y - 29, x + 3, y - 28, "rust")
    elif item == "jar":
        s.rect(x - 3, y - 2, x + 3, y + 6, "glass_dk")
        s.rect(x - 2, y - 1, x + 2, y + 5, "violet", glow=True)
        s.px(x - 1, y, "violet_lt", glow=True)
        s.rect(x - 3, y - 3, x + 3, y - 2, "earth")
    elif item == "map":
        s.rect(x - 5, y - 3, x + 3, y + 3, "bone")
        s.line([(x - 4, y - 1), (x + 1, y + 1)], "rust")
        s.px(x - 2, y + 2, "earth_lt")
    elif item == "teapot":
        s.ellipse(x, y + 3, 4, 3, "glass_lt")
        s.line([(x + 4, y + 2), (x + 7, y)], "glass_lt")
        s.rect(x - 1, y - 1, x + 1, y, "glass")
        s.px(x - 1, y + 2, "glint")
    elif item == "watch":
        s.line([(x - 6, y - 8), (x, y)], "gold")
        s.ellipse(x, y + 2, 3, 3, "gold")
        s.ellipse(x, y + 2, 2, 2, "pale")
        s.px(x, y + 2, "rose", glow=True)
    elif item == "loaf":                    # a round loaf on her palm, scored, a little too dark on top
        s.ellipse(x, y + 1, 5, 3.5, "earth_lt")
        s.ellipse(x, y, 4, 2.5, "rust")
        s.line([(x - 2, y - 1), (x - 1, y + 1)], "earth_dk")
        s.line([(x + 1, y - 1), (x + 2, y + 1)], "earth_dk")
        s.px(x - 2, y - 2, "amber")
    elif item == "oar":
        s.line([(x - 2, y + 14), (x + 2, y - 30)], "earth_lt", width=2)
        s.poly([(x - 4, y + 12), (x + 1, y + 12), (x, y + 22), (x - 5, y + 22)], "earth")
    elif item == "shadow_hand":
        s.line([(x, y), (x + 2, y + 8), (x - 1, y + 13)], "void", width=2)
        s.px(x + 1, y + 6, "violet_lt", glow=True)


def _head(s: Spr, f: Fig) -> None:
    sp = f.spec
    hy = f.y(16) if f.k == 1.0 else f.y(17)
    skin = sp.get("skin", "skin")
    s.rect(CX - 1, hy + 4, CX + 1, hy + 7, sp.get("neck", skin))
    s.ellipse(CX, hy, 4.5, 5, skin)
    s.rect(CX - 4, hy + 1, CX - 3, hy + 4, sp.get("skin_dk", "skin_dk"))
    eyes = sp.get("eyes", "ink")
    glow = sp.get("eyes_glow", False)
    if f.pose == "idle" and f.i == BLINK and not glow:
        eyes = sp.get("skin_dk", "skin_dk")
    s.px(CX - 2, hy, eyes, glow=glow)
    s.px(CX + 2, hy, eyes, glow=glow)
    if sp.get("beard"):                       # stubble, and the jaw caught by the lantern on his right
        s.rect(CX - 3, hy + 3, CX + 1, hy + 4, sp["beard"])
        s.px(CX + 2, hy + 2, "skin")
        s.px(CX + 3, hy + 1, "skin")
        s.px(CX + 3, hy + 2, "skin_lt")
        s.px(CX + 2, hy + 3, "skin")
        s.px(CX + 1, hy + 4, "skin_dk")
    if sp.get("mouth"):
        s.px(CX, hy + 3, sp["mouth"])
    style = sp["head"]
    hat = sp.get("hat", ("night", "dusk1", "dusk3"))
    if style == "brim":
        s.ellipse(CX, hy - 4, 15, 3, hat[1])
        s.line([(CX - 14, hy - 3), (CX + 14, hy - 3)], hat[0])
        s.poly([(CX - 7, hy - 5), (CX + 7, hy - 5), (CX + 5, hy - 14), (CX - 5, hy - 14)], hat[1])
        s.poly([(CX - 7, hy - 5), (CX - 3, hy - 5), (CX - 2, hy - 14), (CX - 5, hy - 14)], hat[0])
        s.line([(CX + 4, hy - 13), (CX + 5, hy - 6)], hat[2])
        s.rect(CX - 7, hy - 7, CX + 7, hy - 6, sp.get("band", "amber"))
        s.rect(CX - 4, hy - 2, CX + 4, hy + 1, "ink")             # the brim's shadow over the eyes
        s.px(CX - 2, hy, "gold", glow=True)
        s.px(CX + 2, hy, "gold", glow=True)
    elif style == "hood":
        s.poly([(CX - 7, hy + 5), (CX - 7, hy - 3), (CX - 3, hy - 8), (CX + 3, hy - 8), (CX + 7, hy - 3), (CX + 7, hy + 5),
                (CX + 4, hy + 5), (CX + 4, hy - 3), (CX - 4, hy - 3), (CX - 4, hy + 5)], hat[1])
        s.poly([(CX - 7, hy + 5), (CX - 7, hy - 3), (CX - 3, hy - 8), (CX - 4, hy - 3), (CX - 4, hy + 5)], hat[0])
        s.px(CX + 5, hy - 5, hat[2])
        if sp.get("hood_point"):
            s.poly([(CX - 2, hy - 8), (CX + 3, hy - 8), (CX + 6, hy - 13)], hat[1])
    elif style == "bun":
        s.ellipse(CX, hy - 3, 5, 3, hat[1])
        s.ellipse(CX + 1, hy - 8, 3, 3, hat[1])
        s.px(CX + 2, hy - 9, hat[2])
        s.rect(CX - 5, hy - 3, CX - 4, hy + 3, hat[0])
        if sp.get("spectacles"):              # small round brass spectacles on the nose
            for ex in (CX - 2, CX + 2):
                for dx, dy in ((-1, 0), (1, 0), (0, 1)):
                    s.px(ex + dx, hy + dy, "amber")
                s.px(ex, hy, "glass_lt")
            s.px(CX, hy, "amber")
    elif style == "cap":
        s.ellipse(CX, hy - 4, 6, 3, hat[1])
        s.rect(CX - 1, hy - 3, CX + 8, hy - 2, hat[0])
        s.px(CX - 3, hy - 6, hat[2])
        s.rect(CX - 5, hy - 2, CX - 4, hy + 2, sp.get("hair", "earth_lt"))
        s.rect(CX + 4, hy - 2, CX + 5, hy + 2, sp.get("hair", "earth_lt"))
    elif style == "helm":
        s.ellipse(CX, hy - 3, 6, 4, hat[1])
        s.rect(CX - 6, hy - 3, CX + 6, hy - 2, hat[0])
        s.rect(CX - 1, hy - 7, CX + 1, hy - 1, hat[2])
        s.px(CX - 2, hy + 3, "stone_lt")                                     # a scar
        s.rect(CX + 3, hy + 1, CX + 5, hy + 4, sp.get("hair", "pale"))
    elif style == "wild":
        for dx, dy in ((-5, -3), (-3, -6), (0, -7), (3, -6), (5, -3), (-6, 1), (6, 1)):
            s.ellipse(CX + dx, hy + dy, 2.5, 2.5, hat[1])
        s.px(CX - 1, hy - 7, hat[2])
    elif style == "clock":                  # a clock face where the head should be, stopped at four
        clock_dial(s, CX, hy - 1, 7)
        s.px(CX, hy - 1, "rose", glow=True)
    elif style == "shadow":
        s.ellipse(CX, hy - 1, 6, 7, "void")
        s.poly([(CX - 6, hy - 3), (CX - 9, hy - 10), (CX - 3, hy - 6)], "void")
        s.poly([(CX + 6, hy - 3), (CX + 10, hy - 9), (CX + 3, hy - 6)], "void")
        s.px(CX - 2, hy, "violet_lt", glow=True)
        s.px(CX + 2, hy, "violet_lt", glow=True)
        s.px(CX + 2, hy - 1, "pale", glow=True)


def _capelet(s: Spr, f: Fig) -> None:
    """A short shoulder cape: widens the shoulders into a strong triangle silhouette."""
    sp = f.spec
    if not sp.get("capelet"):
        return
    dk, base, lt = sp["capelet"]
    y0, y1 = f.y(21), f.y(31)
    s.poly([(CX - 7, y0), (CX + 7, y0), (CX + 14 + f.sway * 0.5, y1), (CX - 14 + f.sway * 0.5, y1)], base)
    s.poly([(CX - 7, y0), (CX - 3, y0), (CX - 9, y1), (CX - 14 + f.sway * 0.5, y1)], dk)
    s.line([(CX + 8, y0 + 2), (CX + 13, y1 - 1)], lt)
    s.line([(CX - 14 + f.sway * 0.5, y1), (CX + 14 + f.sway * 0.5, y1)], sp.get("hem_trim", dk))


def _satchel(s: Spr, f: Fig) -> None:
    if not f.spec.get("satchel"):
        return
    x, y = f.x(-9), f.y(38)
    s.rect(x - 3, y, x + 3, y + 6, "earth")
    s.rect(x - 3, y, x + 3, y + 1, "earth_lt")
    s.rect(x - 1, y + 2, x + 1, y + 3, "amber")
    s.rect(x + 4, y + 1, x + 6, y + 6, "glass_dk")                 # an oil flask clipped to it
    s.px(x + 5, y + 2, "amber", glow=True)


def _scarf(s: Spr, f: Fig) -> None:
    sp = f.spec
    if not sp.get("scarf"):
        return
    a, b = sp["scarf"]
    y = f.y(21)
    s.rect(CX - 6, y, CX + 6, y + 3, a)
    s.line([(CX - 5, y + 3), (CX + 5, y + 3)], b)
    tail = f.sway + (1 if f.pose == "walk" and f.i in (1, 2, 5, 6) else 0)
    s.poly([(CX - 6, y + 2), (CX - 3, y + 2), (CX - 5 + tail, y + 15), (CX - 8 + tail, y + 14)], a)
    s.line([(CX - 6, y + 3), (CX - 7 + tail, y + 14)], b)


def _back(s: Spr, f: Fig) -> None:
    """Things behind the body: capes, packs, a coiled whip seen at the hip."""
    sp = f.spec
    if sp.get("cape"):
        c = sp["cape"]
        s.poly([(CX - 11, f.y(23)), (CX + 11, f.y(23)), (CX + 14 + f.sway, f.y(50)), (CX - 14 + f.sway, f.y(50))], c)
    if sp.get("pack"):
        s.rect(CX + 7, f.y(25), CX + 13, f.y(36), sp["pack"])


def draw(spec: dict, pose: str, i: int) -> Spr:
    s = Spr(64, 64)
    f = Fig(spec, pose, i)
    _back(s, f)
    _legs(s, f)
    _coat(s, f)
    if spec.get("coil"):
        s.ellipse(f.x(-7), f.y(40), 3, 3, "earth_lt")
        s.ellipse(f.x(-7), f.y(40), 1, 1, spec["coat"][0])
    _satchel(s, f)
    left, right = _hands(f)
    _arm(s, f, -1, left)
    _arm(s, f, 1, right)
    _capelet(s, f)
    _scarf(s, f)
    _head(s, f)
    if spec.get("held_l"):
        _held(s, f, spec["held_l"], left)
    if spec.get("held_r"):
        _held(s, f, spec["held_r"], right)
    s.outline()
    s.recolor_edge(-1, 0, spec.get("rim_cool", "dusk3"), only={spec["coat"][0], spec["coat"][1], "ink", "night"})
    s.recolor_edge(1, 0, spec.get("rim_warm", "rust"), only={spec["coat"][1], spec["coat"][2]})
    if pose == "hurt":
        s.glow.paste((0, 0, 0, 0), (0, 0, 64, 64))
    return s


LAMPLIGHTER = {
    "name": "The Lamplighter", "head": "brim", "hat": ("ink", "night", "dusk3"), "band": "ember",
    "coat": ("dusk1", "dusk2", "dusk3"), "trim": "amber", "buttons": [27, 31], "belt": "earth_dk",
    "scarf": ("ember", "rust"), "cuff": "rust", "hem_trim": "ember_dk", "held_r": "pole", "skin": "skin_dk",
    "capelet": ("night", "dusk1", "dusk3"), "satchel": True,
    "beard": "ink",
    "glove": "earth_dk", "rim_warm": "ember",
}

TOWNSFOLK = {
    "porter": {"name": "", "role": "", "head": "cap", "hat": ("earth_dk", "earth", "earth_lt"), "hair": "stone_lt",
               "coat": ("ember_dk", "rust", "ember"), "hem": 46, "hem_w": 10, "pack": "earth_lt", "skin": "skin", "belt": "ink"},
    "lampwife": {"name": "", "role": "", "head": "hood", "hat": ("glass_dp", "glass_dk", "glass"), "coat": ("glass_dp", "glass_dk", "glass"),
                 "hem": 57, "hem_w": 12, "held_r": "small_lantern", "skin": "skin_lt", "apron": "bone", "split": False},
    "watchman": {"name": "", "role": "", "head": "helm", "hat": ("stone_dk", "stone", "stone_lt"), "coat": ("night", "dusk1", "dusk2"),
                 "held_r": "pike", "hem": 47, "hem_w": 10, "skin": "skin_dk", "belt": "ink", "trim": "amber", "buttons": [27, 31]},
}

REPEATER = {"name": "", "role": "", "head": "cap", "hat": ("stone_dk", "stone", "stone_lt"), "hair": "stone",
            "coat": ("stone_dk", "stone", "stone_lt"), "hem": 48, "hem_w": 10, "skin": "pale", "eyes": "glint", "eyes_glow": True,
            "belt": "ink", "rim_cool": "glass_lt", "rim_warm": "glint", "scarf": ("stone", "stone_dk")}
CLOCKFACE = {"name": "", "role": "", "head": "clock", "coat": ("ink", "night", "dusk2"), "hem": 58, "hem_w": 9, "skin": "pale",
             "held_r": "watch", "width": 0.85, "rim_cool": "violet", "rim_warm": "gold", "tatters": True, "cape": "void"}

NPCS = {
    "ottilie": {"name": "Mother Ottilie Brask", "role": "Keeper of the Great Lantern", "head": "bun", "spectacles": True,
                "hat": ("stone", "stone_lt", "bone"), "coat": ("earth_dk", "earth", "earth_lt"), "apron": "ember_dk",
                "hem": 57, "hem_w": 12, "held_r": "pipe", "held_l": "small_lantern", "skin": "skin", "glove": "ink",
                "width": 1.08, "split": False},
    "ysolde": {"name": "Captain Ysolde Marr", "role": "Commander of the Wall", "head": "helm",
               "hat": ("stone_dk", "stone", "stone_lt"), "coat": ("ember_dk", "rust", "ember"), "cape": "night",
               "belt": "ink", "trim": "stone_lt", "buttons": [26, 29, 32], "held_r": "pike", "hem": 47, "hem_w": 10,
               "legs": "stone_dk", "boots": "ink", "skin": "skin_lt", "glove": "stone_dk", "width": 1.12},
    "nim": {"name": "Nim Saltry", "role": "Wall-runner, 11", "head": "cap", "hat": ("glass_dk", "glass", "glass_lt"),
            "hair": "ember", "coat": ("moss_dk", "moss_lt", "glass_lt"), "scale": 0.74, "hem": 46, "hem_w": 9,
            "held_r": "map", "pack": "earth", "legs": "earth_dk", "skin": "skin_lt", "scarf": ("amber", "flame")},
    "fenn": {"name": "Auntie Fenn Caddock", "role": "Smith of the Ember Forge", "head": "wild",
             "hat": ("bone", "pale", "bone"), "coat": ("rust", "ember", "flame"), "apron": "earth_dk", "hem": 52,
             "hem_w": 12, "held_r": "hammer", "skin": "skin_dk", "glove": "ink", "width": 1.2, "split": False,
             "rim_warm": "flame"},
    "lio": {"name": "Lio Quill", "role": "Archivist of Rewritten Things", "head": "hood", "hood_point": True,
            "hat": ("violet", "violet_lt", "pale"), "coat": ("dusk1", "violet", "violet_lt"), "hem": 58, "hem_w": 11,
            "held_r": "jar", "skin": "skin_lt", "belt": "earth", "trim": "gold", "width": 0.9},
    "hask": {"name": "Hask", "role": "A man the Dusk half rewrote", "head": "shadow", "coat": ("void", "ink", "night"),
             "skin": "void", "hem": 57, "hem_w": 14, "held_l": "shadow_hand", "rim_cool": "violet", "rim_warm": "violet_lt",
             "scarf": ("night", "void"), "tatters": True},
    "mara": {"name": "Mara Brennick", "role": "The woodcutter's daughter", "head": "bun", "hat": ("earth_dk", "earth", "earth_lt"),
             "coat": ("glass_dp", "glass_dk", "glass"), "cape": "rust", "hem": 57, "hem_w": 11, "held_r": "teapot",
             "skin": "skin_lt", "apron": "bone", "split": False, "width": 0.95, "scarf": ("rust", "ember_dk")},
    "odile": {"name": "Odile Vane", "role": "Ferrywoman of the Upward River", "head": "brim", "hat": ("glass_dp", "glass_dk", "glass_lt"),
              "band": "glint", "coat": ("glass_dp", "glass_dk", "glass"), "cape": "night", "hem": 56, "hem_w": 12, "held_r": "oar",
              "skin": "skin", "belt": "earth_dk", "trim": "glint", "buttons": [27, 31], "scarf": ("glass_lt", "glass")},
    "teague": {"name": "Teague Morrow", "role": "The Eighth Lamplighter (missing)", "head": "hood",
               "hat": ("ink", "night", "mist"), "coat": ("ink", "night", "dusk2"), "cape": "dusk1", "held_r": "lantern",
               "held_l": "whip", "skin": "pale", "eyes": "glint", "eyes_glow": True, "scarf": ("stone", "stone_dk"),
               "belt": "ink", "trim": "stone_lt", "buttons": [27], "rim_warm": "glass", "tatters": True},
    "wren": {"name": "Wren Aldous", "role": "Baker of the Tuesday Market", "head": "cap", "hat": ("stone_lt", "pale", "bone"), "hair": "rust",
             "coat": ("dusk1", "dusk2", "dusk3"), "apron": "bone", "hem": 55, "hem_w": 12, "held_r": "loaf", "skin": "skin_lt",
             "glove": "skin", "width": 1.02, "split": False, "rim_warm": "amber"},
}
