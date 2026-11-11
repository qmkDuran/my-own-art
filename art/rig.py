"""A small 3D rig for the Lamplighter, drawn as pixel art from any of eight facings.

The body is a handful of joints in the character's own space (x to his right, y up, f forward). A pose (Pose) says
where the feet and hands go, how the hips sit, how the upper body leans and twists, and how the loose things (cape,
scarf, the lantern on its hook) lag behind. Legs and arms are solved with two-bone IK; volumes (coat, capelet, hat)
are convex hulls of a few rings of points; everything is projected into the 3/4 top-down view (toward the camera is
lower on screen) and painted far-to-near. One rig, eight true directions: no mirroring, so the staff is always in
his left hand."""
from __future__ import annotations

import math
from dataclasses import dataclass, field

from pix import Spr

FRAME = 96
FEET = 85
SOLE = FEET + 3              # where the boots meet the ground on screen (the sprite's anchor)
CX = 48
DEPTH_TILT = 0.32            # how far toward the camera moves a point down the screen (the 3/4 view)
YAWS = {"s": 0, "se": 45, "e": 90, "ne": 135, "n": 180, "nw": 225, "w": 270, "sw": 315}
DIRS = list(YAWS)
ROLL_SHIFT = (30.0, 26.0)     # a body lying down is moved back toward the frame centre by this much

THIGH, SHIN = 12.0, 12.0
UPPER_ARM, FOREARM = 9.0, 9.0
HIP_W, SHOULDER_W = 4.0, 9.0
HIP_Y, SHOULDER_Y, NECK_Y, HEAD_Y, BRIM_Y = 26.0, 41.0, 44.0, 48.0, 52.0
STAFF_DOWN, STAFF_UP = 14.0, 32.0

Vec = tuple[float, float, float]


@dataclass
class Pose:
    """One frame of the Lamplighter, in his own space. Lags are offsets of the loose things (x, y, f)."""
    root: Vec = (0.0, 0.0, 0.0)
    hip_drop: float = 0.0
    lean: float = 0.0                    # forward pitch of the upper body (radians)
    twist: float = 0.0                   # yaw of the upper body against the hips (radians)
    foot_l: Vec = (-4.0, 0.0, 0.0)
    foot_r: Vec = (4.0, 0.0, 0.0)
    hand_l: Vec = (-13.5, 27.0, 5.0)     # the staff hand
    hand_r: Vec = (11.0, 25.0, 1.0)      # the free hand (it joins the staff for two-handed thrusts)
    staff_tilt: Vec = (-0.18, 1.0, 0.15)   # the staff's direction (x, y, f), normalised when drawn
    lantern_lag: Vec = (0.0, 0.0, 0.0)
    cape_lag: Vec = (0.0, 0.0, -2.0)
    scarf_lag: Vec = (0.0, 0.0, -3.0)
    breath: float = 0.0
    pane: float = 1.0                    # the lantern's brightness, 0 (out) to 1
    eyes: bool = True
    roll: float = 0.0                    # whole-body fall in the picture plane (death), radians
    smear: float = 0.0                   # dash: ghost copies trailing this far behind
    lantern_on_staff: bool = True
    lantern_at: Vec | None = None        # where the lantern lies when it is not on the staff (in his space)
    extra: dict = field(default_factory=dict)


def _add(a: Vec, b: Vec) -> Vec:
    return (a[0] + b[0], a[1] + b[1], a[2] + b[2])


def _sub(a: Vec, b: Vec) -> Vec:
    return (a[0] - b[0], a[1] - b[1], a[2] - b[2])


def _mul(a: Vec, k: float) -> Vec:
    return (a[0] * k, a[1] * k, a[2] * k)


def _len(a: Vec) -> float:
    return math.sqrt(a[0] ** 2 + a[1] ** 2 + a[2] ** 2)


def _norm(a: Vec) -> Vec:
    n = _len(a) or 1.0
    return (a[0] / n, a[1] / n, a[2] / n)


def _dot(a: Vec, b: Vec) -> float:
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]


def ik(a: Vec, target: Vec, l1: float, l2: float, hint: Vec) -> tuple[Vec, Vec]:
    """Two-bone IK: (middle joint, end) reaching from a toward target, bending toward hint."""
    d = _sub(target, a)
    dist = min(_len(d), l1 + l2 - 0.01)
    u = _norm(d)
    end = _add(a, _mul(u, dist))
    along = (l1 * l1 - l2 * l2 + dist * dist) / (2 * dist)
    h = math.sqrt(max(l1 * l1 - along * along, 0.0))
    perp = _norm(_sub(hint, _mul(u, _dot(hint, u))))
    return _add(_add(a, _mul(u, along)), _mul(perp, h)), end


class View:
    """Projection of his space into the picture for one facing (yaw: 0 = toward the camera, 90 = screen right)."""

    def __init__(self, yaw_deg: float, pose: Pose) -> None:
        t = math.radians(yaw_deg)
        self.fx, self.fz = math.sin(t), math.cos(t)          # forward, in world (x right, z toward camera)
        self.rx, self.rz = -math.cos(t), math.sin(t)         # his right
        self.p = pose

    def upper(self, v: Vec) -> Vec:
        """Lean and twist apply to everything above the hips, about the hip centre."""
        hip_y = HIP_Y - self.p.hip_drop
        x, y, f = v[0], v[1] - hip_y, v[2]
        c, s = math.cos(self.p.twist), math.sin(self.p.twist)
        x, f = x * c + f * s, -x * s + f * c
        c, s = math.cos(self.p.lean), math.sin(self.p.lean)
        y, f = y * c - f * s, y * s + f * c
        return (x, y + hip_y, f)

    def world(self, v: Vec) -> tuple[float, float, float]:
        v = _add(v, self.p.root)
        return (v[0] * self.rx + v[2] * self.fx, v[1], v[0] * self.rz + v[2] * self.fz)

    def screen(self, v: Vec) -> tuple[float, float]:
        wx, wy, wz = self.world(v)
        x, y = wx, -wy + wz * DEPTH_TILT
        if self.p.roll:                                      # toppling: he falls to screen right, kept in frame
            r = self.p.roll * (0.35 + 0.65 * abs(self.fz))   # seen side-on, the forward fold already lays him down
            r *= -1.0 if self.fx < -0.3 else 1.0               # and he falls the way he faces
            c, s = math.cos(r), math.sin(r)
            x, y = x * c - y * s - ROLL_SHIFT[0] * s, x * s + y * c - ROLL_SHIFT[1] * abs(s)
        return (CX + x, FEET + y)

    def depth(self, v: Vec) -> float:
        return self.world(v)[2]

    def toward_camera(self) -> float:
        """How much he faces us: 1 facing the camera, -1 facing away."""
        return self.fz


def hull(pts: list[tuple[float, float]]) -> list[tuple[float, float]]:
    pts = sorted(set((round(x, 2), round(y, 2)) for x, y in pts))
    if len(pts) < 3:
        return pts

    def cross(o: tuple[float, float], a: tuple[float, float], b: tuple[float, float]) -> float:
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])
    lower: list[tuple[float, float]] = []
    for p in pts:
        while len(lower) >= 2 and cross(lower[-2], lower[-1], p) <= 0:
            lower.pop()
        lower.append(p)
    upper: list[tuple[float, float]] = []
    for p in reversed(pts):
        while len(upper) >= 2 and cross(upper[-2], upper[-1], p) <= 0:
            upper.pop()
        upper.append(p)
    return lower[:-1] + upper[:-1]


def ring(cy: float, rx: float, rf: float, n: int = 10, df: float = 0.0, dx: float = 0.0) -> list[Vec]:
    return [(dx + math.cos(2 * math.pi * k / n) * rx, cy, df + math.sin(2 * math.pi * k / n) * rf) for k in range(n)]


class Painter:
    """Collects parts with their depth and paints them far to near."""

    def __init__(self) -> None:
        self.parts: list[tuple[float, int, object]] = []

    def add(self, depth: float, fn: object) -> None:
        self.parts.append((depth, len(self.parts), fn))

    def paint(self, s: Spr) -> None:
        for _, _, fn in sorted(self.parts, key=lambda p: (p[0], p[1])):
            fn(s)


def limb(s: Spr, pts: list[tuple[float, float]], c: str, w: int) -> None:
    s.line(pts, c, width=w)
    for x, y in pts:
        s.ellipse(x, y, w / 2 - 0.5, w / 2 - 0.5, c)
