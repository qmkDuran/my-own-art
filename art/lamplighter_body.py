"""Paints the Lamplighter from the rig (rig.py) for one pose and facing: legs, long coat, capelet, scarf, the brimmed
hat with its ember band and the eyes that glow under it, the hook staff in his left hand with the lantern swinging
from its crook (his one weapon: every spell comes out of that lantern). Same palette, outline and rim light as every other sprite."""
from __future__ import annotations

import math

from pix import Spr
from rig import (BRIM_Y, FOREARM, HEAD_Y, HIP_W, HIP_Y, NECK_Y, SHIN, SHOULDER_W, SHOULDER_Y, STAFF_DOWN, STAFF_UP,
                 THIGH, UPPER_ARM, Painter, Pose, Vec, View, hull, ik, limb, ring)

COAT = ("dusk1", "dusk2", "dusk3")
CAPELET = ("night", "dusk1", "dusk3")
LEG, BOOT, BOOT_HI = "ink", "earth_dk", "earth"
CUFF, GLOVE = "rust", "earth_dk"
SCARF = ("ember", "rust")
HAT = ("ink", "night", "dusk3")
BAND = "ember"
FRONT = 0.25                    # facing the camera at least this much: the front details show
BEHIND = -1000.0
NEAR_HEAD = 6.0
GRIP = 9.0                      # two-handed swings: the right hand holds this far down the staff                 # a staff or lantern this far toward the camera is in front of his hat and face                # depth for things always under the coat (the legs' tops)


def _pts(v: View, vs: list[Vec], upper: bool = True) -> list[tuple[float, float]]:
    return [v.screen(v.upper(p) if upper else p) for p in vs]


def front_arc(v: View, pts: list[Vec], k: int) -> list[tuple[float, float]]:
    """The k ring points nearest the camera, in ring order (a clean arc for edges and bands)."""
    n = len(pts)
    near = max(range(n), key=lambda i: v.depth(v.upper(pts[i])))
    return [v.screen(v.upper(pts[(near + j) % n])) for j in range(-(k // 2), k // 2 + 1)]


def _legs(pa: Painter, v: View, p: Pose) -> None:
    hip_y = HIP_Y - p.hip_drop
    for side, foot in ((-1, p.foot_l), (1, p.foot_r)):
        hip = (side * HIP_W, hip_y, 0.0)
        ankle = (foot[0], foot[1] + 2.0, foot[2])
        knee, end = ik(hip, ankle, THIGH, SHIN, (side * 0.2, 0.0, 1.0))
        toe = (end[0], foot[1] + 0.5, end[2] + 3.0)

        def draw(s: Spr, hip: Vec = hip, knee: Vec = knee, end: Vec = end, toe: Vec = toe) -> None:
            limb(s, [v.screen(hip), v.screen(knee), v.screen(end)], LEG, 4)
            limb(s, [v.screen(end), v.screen(toe)], BOOT, 4)
            x, y = v.screen(end)
            s.px(x, y - 1, BOOT_HI)
        pa.add(BEHIND + v.depth(knee), draw)


def _coat(pa: Painter, v: View, p: Pose) -> None:
    stride = (p.foot_l[2] + p.foot_r[2]) * 0.3
    waist = ring(HIP_Y + 3 - p.hip_drop, 7.5, 4.5)
    hem = ring(12.0 - p.hip_drop * 0.6, 11.0, 6.5, df=stride + p.cape_lag[2] * 0.25, dx=p.cape_lag[0] * 0.3)
    chest = ring(SHOULDER_Y - 2, 9.5, 5.0)

    def skirt(s: Spr) -> None:
        pts = _pts(v, waist) + _pts(v, hem, upper=False)
        s.poly(hull(pts), COAT[1])
        lo = min(pts, key=lambda q: q[0])[0]
        s.poly(hull([q for q in pts if q[0] < lo + 6] + [((lo + 6), max(q[1] for q in pts))]), COAT[0])
        if v.toward_camera() > FRONT:                      # the coat parts below the belt
            a = v.screen(v.upper((0.0, HIP_Y - 1 - p.hip_drop, 4.5)))
            b = v.screen((1.6, 12.5 - p.hip_drop * 0.6, 6.5 + stride))
            c = v.screen((-1.6, 12.5 - p.hip_drop * 0.6, 6.5 + stride))
            s.poly([a, b, c], LEG)

    def torso(s: Spr) -> None:
        s.poly(hull(_pts(v, waist) + _pts(v, chest)), COAT[1])
        if v.toward_camera() > FRONT:
            neck = v.screen(v.upper((0.0, SHOULDER_Y - 1, 5.0)))
            vee = v.screen(v.upper((0.0, SHOULDER_Y - 9, 5.4)))
            s.poly([(neck[0] - 4, neck[1]), (neck[0] + 4, neck[1]), vee], COAT[0])
            for by in (31.0, 35.0):
                x, y = v.screen(v.upper((0.0, by, 5.2)))
                s.px(x + 1, y, "amber")
        belt = [v.screen(v.upper((math.cos(a) * 7.8, HIP_Y + 3 - p.hip_drop, math.sin(a) * 4.8)))
                for a in [k * math.pi / 8 for k in range(9)]]
        s.line(belt, "earth_dk", width=2)
        if v.toward_camera() > -0.3:
            x, y = v.screen(v.upper((0.0, HIP_Y + 3 - p.hip_drop, 4.9)))
            s.rect(x - 1, y - 1, x + 1, y, "amber")
    pa.add(-0.3, skirt)
    pa.add(0.0, torso)


def _capelet(pa: Painter, v: View, p: Pose) -> None:
    top = ring(SHOULDER_Y + 2.5, 9.5, 5.5)
    low = ring(SHOULDER_Y - 8.5, 12.5, 7.5, df=p.cape_lag[2] * 0.4, dx=p.cape_lag[0] * 0.5)
    low = [(x, y + p.cape_lag[1] * 0.4, f) for x, y, f in low]

    def draw(s: Spr) -> None:
        pts = _pts(v, top) + _pts(v, low)
        s.poly(hull(pts), CAPELET[0])
        s.line(front_arc(v, low, 5), CAPELET[1])
    pa.add(0.4, draw)


def _arms(pa: Painter, v: View, p: Pose) -> None:
    for side, hand, tone in ((-1, p.hand_l, COAT[0]), (1, p.hand_r, COAT[1])):
        sh = v.upper((side * SHOULDER_W, SHOULDER_Y - 1, 0.0))
        elbow, end = ik(sh, hand, UPPER_ARM, FOREARM, (side * 0.7, -0.4, -0.8))

        def draw(s: Spr, sh: Vec = sh, elbow: Vec = elbow, end: Vec = end, tone: str = tone) -> None:
            limb(s, [v.screen(sh), v.screen(elbow), v.screen(end)], tone, 4)
            wx, wy = v.screen(end)
            s.ellipse(wx, wy, 1.6, 1.6, CUFF)
            s.ellipse(wx, wy + 1, 1.2, 1.2, GLOVE)
        near = v.depth(end) > v.depth(v.upper((0.0, SHOULDER_Y, 0.0)))
        pa.add(1.0 + v.depth(end) * 0.01 if near else -0.6, draw)


def _head(pa: Painter, v: View, p: Pose) -> None:
    head = v.upper((0.0, HEAD_Y, 0.6))
    crown_lo, crown_hi = ring(BRIM_Y + 0.5, 6.0, 5.5), ring(BRIM_Y + 8.5, 5.0, 4.5, df=-0.6)
    brim = ring(BRIM_Y, 11.5, 10.5, n=16, df=0.6)

    def draw(s: Spr) -> None:
        x, y = v.screen(head)
        s.ellipse(x, y, 4.5, 4.5, "ink")                      # hair and the back of the head
        if v.toward_camera() > -0.2:                         # the face in the brim's shadow: beard, glowing eyes
            fx, fy = v.screen(v.upper((0.0, HEAD_Y - 0.5, 3.0)))
            s.ellipse(fx, fy, 3.0, 3.6, "skin_dk")
            bx, by = v.screen(v.upper((0.0, HEAD_Y - 3.0, 3.6)))
            s.ellipse(bx, by, 3.0, 2.0, "ink")
        brim_pts = _pts(v, brim)
        s.poly(hull(brim_pts), HAT[2])
        s.poly(hull([(q[0], q[1] - 1) for q in brim_pts]), HAT[1])
        s.poly(hull(_pts(v, crown_lo) + _pts(v, ring(BRIM_Y + 3.2, 5.9, 5.4))), BAND)
        s.poly(hull(_pts(v, ring(BRIM_Y + 3.2, 5.6, 5.1)) + _pts(v, crown_hi)), HAT[0])
        if v.toward_camera() > -0.2:
            for ex in (-1.9, 1.9):
                e = v.upper((ex, HEAD_Y + 1.0, 4.4))
                if v.depth(e) > v.depth(head) - 1.0:
                    px, py = v.screen(e)
                    s.px(px, py, "gold" if p.eyes else "ink", glow=p.eyes)
    pa.add(2.0, draw)


def _scarf(pa: Painter, v: View, p: Pose) -> None:
    knot = v.upper((-2.0, NECK_Y - 2.0, -2.5))
    tail = (knot[0] + p.scarf_lag[0], knot[1] - 11.0 + p.scarf_lag[1], knot[2] + p.scarf_lag[2])

    def wrap(s: Spr) -> None:
        pts = [v.screen(v.upper((math.cos(a) * 5.5, NECK_Y - 1.0, math.sin(a) * 4.2))) for a in
               [k * math.pi / 6 for k in range(12)]]
        s.poly(hull(pts), SCARF[0])
        s.line(sorted(pts, key=lambda q: q[1])[-5:], SCARF[1])

    def tail_draw(s: Spr) -> None:
        a, b = v.screen(knot), v.screen(tail)
        s.poly([(a[0] - 1.5, a[1]), (a[0] + 1.5, a[1]), (b[0] + 1, b[1]), (b[0] - 2, b[1] - 1)], SCARF[0])
        s.line([a, b], SCARF[1])
    pa.add(1.5, wrap)
    pa.add(v.depth(tail) * 0.05 + (0.45 if v.depth(tail) > 0 else -0.8), tail_draw)


def staff_points(v: View, p: Pose) -> tuple[Vec, Vec, Vec]:
    d = p.staff_tilt
    n = math.sqrt(d[0] ** 2 + d[1] ** 2 + d[2] ** 2) or 1.0
    d = (d[0] / n, d[1] / n, d[2] / n)
    h = p.hand_l
    bottom = (h[0] - d[0] * STAFF_DOWN, h[1] - d[1] * STAFF_DOWN, h[2] - d[2] * STAFF_DOWN)
    top = (h[0] + d[0] * STAFF_UP, h[1] + d[1] * STAFF_UP, h[2] + d[2] * STAFF_UP)
    tip = (top[0] - 2.5, top[1] - 1.0, top[2] + 4.0)
    return bottom, top, tip


def _staff(pa: Painter, v: View, p: Pose) -> None:
    bottom, top, tip = staff_points(v, p)
    crook = [top, (top[0] - 1.5, top[1] + 2.0, top[2] + 2.0), (tip[0], tip[1] + 2.0, tip[2]), tip]

    def draw(s: Spr) -> None:
        s.line([v.screen(bottom), v.screen(top)], "earth_dk", width=2)
        s.line([v.screen(q) for q in crook], "stone_dk", width=2)
        b, t = v.screen(bottom), v.screen(top)
        s.line([(b[0] + 1, b[1]), (t[0] + 1, t[1])], "earth")
    near = v.depth(p.hand_l) > NEAR_HEAD
    pa.add(v.depth(p.hand_l) * 0.01 + (2.05 if near else (1.1 if v.depth(p.hand_l) > 0 else -0.7)), draw)


def lantern_point(v: View, p: Pose) -> tuple[float, float]:
    """The lantern's centre on screen (the game hangs its light here)."""
    if not p.lantern_on_staff:
        ls = p.extra.get("lantern_screen")
        if ls is not None:                                    # it rolls away from the side he falls to
            from rig import CX
            return (2 * CX - ls[0], ls[1]) if v.fx < -0.3 else ls
    _, _, tip = staff_points(v, p)
    return v.screen((tip[0] + p.lantern_lag[0], tip[1] - 7.0 + p.lantern_lag[1], tip[2] + p.lantern_lag[2]))


def _pane(level: float) -> tuple[str, str, str, bool]:
    if level > 0.7:
        return "amber", "gold", "sun", True
    if level > 0.45:
        return "flame", "amber", "gold", True
    if level > 0.2:
        return "ember_dk", "ember", "flame", True
    return "ink", "ember_dk", "ember_dk", False


def _lantern(pa: Painter, v: View, p: Pose) -> None:
    if not p.lantern_on_staff and p.extra.get("lantern_screen") is None:
        return
    x, y = lantern_point(v, p)
    _, _, tip = staff_points(v, p)
    hook = v.screen(tip)

    def draw(s: Spr) -> None:
        if p.lantern_on_staff:
            s.line([hook, (x, y - 5)], "stone_dk")
        outer, mid, core, glow = _pane(p.pane)
        if p.extra.get("flare"):                              # the release: the lantern flares as the bolt leaves
            for dx, dy in ((-5, 0), (5, 0), (0, -6), (0, 6), (-4, -4), (4, 4), (4, -4), (-4, 4)):
                s.line([(x, y), (x + dx, y + dy)], "gold", glow=True)
            s.ellipse(x, y, 3.5, 4.5, "sun", glow=True)
        s.rect(x - 2, y - 6, x + 2, y - 5, "ink")
        s.rect(x - 3, y - 4, x + 3, y + 4, "ink")
        s.rect(x - 2, y - 3, x + 2, y + 3, outer, glow=glow)
        s.rect(x - 1, y - 2, x + 1, y + 2, mid, glow=glow)
        s.px(x, y, core, glow=glow)
        s.line([(x, y - 4), (x, y + 4)], "ink")
        s.rect(x - 2, y + 5, x + 2, y + 5, "stone_dk")
    depth = v.depth(tip) if p.lantern_on_staff else 3.0
    pa.add(depth * 0.01 + (2.1 if depth > NEAR_HEAD else (1.2 if depth > 0 else -0.75)), draw)


def _smear(s: Spr, v: View, dist: float) -> None:
    """Wickstep: two flat after-images trail behind him along his way (cool, then darker)."""
    from PIL import Image
    from palette import rgba
    from rig import DEPTH_TILT
    mask = s.img.split()[3]
    out = Image.new("RGBA", s.img.size, (0, 0, 0, 0))
    for k, c in ((1.0, "night"), (0.55, "dusk1")):
        dx, dy = round(-v.fx * dist * k), round(-v.fz * DEPTH_TILT * dist * k)
        ghost = Image.new("RGBA", s.img.size, rgba(c))
        shifted = Image.new("L", s.img.size, 0)
        shifted.paste(mask, (dx, dy))
        out.paste(ghost, (0, 0), shifted)
    out.alpha_composite(s.img)
    s.img.paste(out)


def paint(p: Pose, yaw: float, lantern: bool = True) -> tuple[Spr, dict]:
    """One frame. Returns the sprite and its anchors (the lantern's centre) in frame pixels."""
    s = Spr(96, 96)
    v = View(yaw, p)
    pa = Painter()
    if p.extra.get("two_hand"):                               # the other hand grips the staff lower down
        bottom, top, _ = staff_points(v, p)
        d = (top[0] - bottom[0], top[1] - bottom[1], top[2] - bottom[2])
        n = math.sqrt(d[0] ** 2 + d[1] ** 2 + d[2] ** 2) or 1.0
        p.hand_r = (p.hand_l[0] - d[0] / n * GRIP, p.hand_l[1] - d[1] / n * GRIP, p.hand_l[2] - d[2] / n * GRIP)
    _legs(pa, v, p)
    _coat(pa, v, p)
    _capelet(pa, v, p)
    _arms(pa, v, p)
    _scarf(pa, v, p)
    _head(pa, v, p)
    _staff(pa, v, p)
    if lantern:
        _lantern(pa, v, p)
    pa.paint(s)
    if p.smear > 0.0:
        _smear(s, v, p.smear)
    s.outline()
    s.recolor_edge(-1, 0, "dusk3", only={COAT[0], COAT[1], "ink", "night"})
    s.recolor_edge(1, 0, "ember", only={COAT[1], COAT[2], "night"})
    return s, {"lantern": lantern_point(v, p)}
