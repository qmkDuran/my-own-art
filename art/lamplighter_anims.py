"""The Lamplighter's animation set, as poses for the rig: idle, run, the Wickbolt cast-forward (two variants that
alternate, so a stream of bolts sways instead of repeating), the staff-raise cast for big spells and its channel
loop, Lantern Toss, the Wickstep dash, hit, death (the lantern gutters) and the rise (it relights).

ANIMS is the data the game reads (frames, relative frame weights, fps, loop, events on frames): anticipation is
short, the strike frame is held (weight 2), and events fire on a frame, not on a timer."""
from __future__ import annotations

import math

from rig import Pose

ANIMS: dict[str, dict] = {
    "idle": {"frames": 8, "fps": 6.0, "loop": True},
    "walk": {"frames": 8, "fps": 13.0, "loop": True, "events": {"step": [0, 4]}},
    "bolt1": {"frames": 4, "weights": [0.6, 1.0, 1.6, 1.0], "events": {"hit": 1}},
    "bolt2": {"frames": 4, "weights": [0.6, 1.0, 1.6, 1.0], "events": {"hit": 1}},
    "cast": {"frames": 6, "weights": [0.8, 0.8, 2.0, 1.0, 1.0, 1.0], "events": {"hit": 2}},
    "channel": {"frames": 4, "fps": 8.0, "loop": True},
    "toss": {"frames": 5, "weights": [0.8, 0.8, 1.6, 1.0, 1.2], "events": {"hit": 2}},
    "dash": {"frames": 4, "weights": [0.6, 1.0, 1.0, 1.2]},
    "hurt": {"frames": 3, "weights": [1.0, 1.4, 1.0]},
    "death": {"frames": 8, "fps": 9.0},
    "rise": {"frames": 8, "fps": 9.0},
}

TAU = 2.0 * math.pi
STAFF_HAND: tuple[float, float, float] = (-10.0, 27.0, 5.0)
STAFF_TILT: tuple[float, float, float] = (-0.06, 1.0, 0.12)


def idle(i: int) -> Pose:
    u = TAU * i / 8
    br = math.sin(u)
    return Pose(hip_drop=0.5 - 0.5 * br, lean=0.02 * br, hand_l=(-13.5, 27.0 + 0.5 * br, 5.0), staff_tilt=(-0.18, 1.0, 0.15),
                hand_r=(11.0, 25.0 + 0.5 * br, 1.0), lantern_lag=(0.8 * math.sin(u + 1.0), 0.0, 0.5 * math.cos(u)),
                cape_lag=(0.6 * math.sin(u), 0.0, -2.0), scarf_lag=(0.8 * math.sin(u + 0.5), 0.0, -3.0),
                pane=(1.0, 0.92, 1.0, 0.86, 1.0, 0.95, 0.82, 1.0)[i], eyes=i != 6)


def walk(i: int) -> Pose:
    """A purposeful run: feet planted on contact, hips low there, arms counter-swinging, everything loose trails."""
    u = TAU * i / 8
    stride, lift = 9.0, 5.0
    fl = (-4.0, lift * max(0.0, -math.sin(u)), stride * math.cos(u))
    fr = (4.0, lift * max(0.0, math.sin(u)), -stride * math.cos(u))
    return Pose(foot_l=fl, foot_r=fr, hip_drop=2.0 * abs(math.cos(u)) - 0.5, lean=0.2, twist=0.12 * math.cos(u),
                hand_r=(10.5, 25.0 + abs(math.cos(u)), 1.5 + 6.0 * math.cos(u)),
                hand_l=(-13.5, 27.0, 5.0 - 2.5 * math.cos(u)), staff_tilt=(-0.18, 1.0, 0.15 + 0.12 * math.cos(u)),
                lantern_lag=(0.0, 0.6 * abs(math.sin(u)), -2.0 - 1.2 * math.sin(2 * u)),
                cape_lag=(0.5 * math.sin(u), 0.0, -4.5 - 0.8 * math.cos(2 * u)), scarf_lag=(0.6 * math.sin(u), 1.5, -7.0))


BOLT: dict[str, dict] = {
    # he points the staff and the lantern spits the bolt: a one-handed thrust, then a two-handed one from the other side
    "bolt1": {"hand": [(-12, 30, 3), (-9, 32, 9), (-9, 32, 10), (-12, 28, 6)],
              "tilt": [(-0.15, 1, -0.1), (-0.1, 0.8, 0.8), (-0.1, 0.75, 0.8), (-0.15, 1, 0.35)],
              "twist": [0.15, -0.2, -0.22, -0.05], "lean": [0.0, 0.15, 0.18, 0.06], "step": (-1, [0, 3, 3, 1]),
              "lag": [-1.0, -2.0, 2.0, 0.5], "two_hand": False},
    "bolt2": {"hand": [(-8, 31, 4), (-4, 33, 9), (-4, 33, 10), (-9, 28, 6)],
              "tilt": [(0.1, 1, -0.1), (0.15, 0.8, 0.8), (0.15, 0.75, 0.8), (-0.05, 1, 0.35)],
              "twist": [-0.15, 0.25, 0.27, 0.05], "lean": [0.0, 0.15, 0.18, 0.06], "step": (1, [0, 3, 3, 1]),
              "lag": [-1.0, -2.0, 2.0, 0.5], "two_hand": True},
}


def bolt(name: str, i: int) -> Pose:
    """The cast-forward: short anticipation, the thrust (the lantern flares and the bolt leaves), a held beat."""
    k = BOLT[name]
    side, step = k["step"]
    foot = (4.0 * side, 0.0, float(step[i]))
    p = Pose(hand_l=tuple(float(c) for c in k["hand"][i]), staff_tilt=tuple(float(c) for c in k["tilt"][i]),
             twist=k["twist"][i], lean=k["lean"][i], hip_drop=[0.5, 1.2, 1.4, 0.8][i],
             lantern_lag=(0.0, 0.0, k["lag"][i]), cape_lag=(0.0, 0.0, [-2, -4, -4, -3][i]), scarf_lag=(0.0, 0.5, [-3, -6, -6, -4][i]))
    if side < 0:
        p.foot_l = foot
    else:
        p.foot_r = foot
    p.extra["two_hand"] = k["two_hand"] and i < 3
    p.extra["flare"] = i in (1, 2)
    return p


def cast(i: int) -> Pose:
    hl = [(-9, 30, 5), (-8, 37, 6), (-6, 40, 9), (-6, 39, 10), (-8, 34, 7), (-10, 28, 5)][i]
    tilt = [(-0.05, 1, 0.15), (-0.05, 1, 0.25), (0, 1, 0.55), (0, 1, 0.5), (-0.05, 1, 0.3), (-0.05, 1, 0.12)][i]
    hr = [(10, 28, 4), (9, 33, 9), (7, 36, 13), (7, 34, 12), (9, 30, 6), (11, 25, 1)][i]
    return Pose(hand_l=tuple(float(c) for c in hl), staff_tilt=tuple(float(c) for c in tilt),
                hand_r=tuple(float(c) for c in hr), lean=[0.0, -0.08, 0.15, 0.12, 0.05, 0.0][i],
                hip_drop=[0.5, 0.0, 1.5, 1.2, 0.8, 0.5][i], foot_l=(-4.0, 0.0, [0, 0, 3, 3, 1, 0][i]),
                lantern_lag=(0.0, 0.0, [-1.0, -2.5, 3.0, 2.0, -1.0, 0.0][i]),
                cape_lag=(0.0, 0.0, [-2, -1, -5, -4, -3, -2][i]), scarf_lag=(0.0, 0.5, [-3, -2, -7, -6, -4, -3][i]))


def channel(i: int) -> Pose:
    u = TAU * i / 4
    return Pose(hand_l=(-6.0, 39.0, 8.0), staff_tilt=(0.0, 1.0, 0.35), hand_r=(8.0, 36.0 + math.sin(u), 12.0),
                lean=0.08, hip_drop=1.0, foot_l=(-4.5, 0.0, 2.5), lantern_lag=(0.7 * math.sin(u), 0.0, 0.5 * math.cos(u)),
                cape_lag=(math.sin(u), 0.5, -3.5 - math.sin(u)), scarf_lag=(1.5 * math.sin(u), 1.0, -5.0),
                pane=(1.0, 0.85, 1.0, 0.9)[i])


def toss(i: int) -> Pose:
    hl = [(-10, 30, -4), (-9, 36, -8), (-8, 42, 10), (-8, 38, 12), (-9, 30, 6)][i]
    tilt = [(-0.05, 1, -0.3), (0, 1, -0.5), (0, 1, 0.7), (0, 1, 0.6), (-0.05, 1, 0.2)][i]
    return Pose(hand_l=tuple(float(c) for c in hl), staff_tilt=tuple(float(c) for c in tilt), hand_r=(11.0, 27.0, 3.0),
                lean=[0.05, -0.1, 0.25, 0.2, 0.05][i], hip_drop=[0.5, 0.5, 1.5, 1.2, 0.5][i],
                foot_l=(-4.0, 0.0, [0, -2, 4, 4, 1][i]), lantern_on_staff=i < 2,
                lantern_lag=(0.0, 0.0, [-1.0, -3.0, 0.0, 0.0, 0.0][i]), cape_lag=(0.0, 0.0, [-2, -1, -5, -4, -2][i]))


def dash(i: int) -> Pose:
    return Pose(lean=[0.35, 0.55, 0.55, 0.3][i], hip_drop=[2.0, 3.0, 3.0, 1.0][i],
                foot_l=(-4.0, 0.0, [-6, -9, -9, -3][i]), foot_r=(4.0, [0, 2, 2, 0][i], [5, 7, 7, 3][i]),
                hand_r=(11.0, 28.0, -8.0), hand_l=(-10.0, 28.0, -2.0), staff_tilt=(-0.05, 1.0, -0.45),
                cape_lag=(0.0, 3.0, -9.0), scarf_lag=(0.0, 4.0, -10.0), lantern_lag=(0.0, 1.0, -5.0),
                smear=[0.0, 10.0, 16.0, 6.0][i])


def hurt(i: int) -> Pose:
    return Pose(lean=[-0.25, -0.3, -0.1][i], root=(0.0, 0.0, [-1.5, -2.0, -0.5][i]), hip_drop=[1.0, 1.5, 0.5][i],
                hand_r=(13.0, 31.0, -2.0), hand_l=(-12.0, 30.0, 2.0), twist=[0.15, 0.2, 0.05][i], eyes=i == 2,
                lantern_lag=(0.0, 1.0, 2.5), cape_lag=(0.0, 1.0, 1.0), scarf_lag=(0.0, 2.0, 1.0))


def death(i: int) -> Pose:
    """Knees go, he folds over the staff, then topples to the ground; the lantern rolls free and gutters."""
    k = min(i, 4)
    p = Pose(hip_drop=[2, 5, 9, 12, 13][k], lean=[0.1, 0.35, 0.6, 0.8, 0.85][k],
             hand_r=(10.0, [24, 20, 16, 13, 12][k], [3, 6, 8, 9, 9][k]),
             hand_l=(-10.0, [26, 22, 17, 13, 12][k], [5, 7, 9, 9, 9][k]),
             staff_tilt=(-0.06 - 0.16 * k, 1.0 - 0.15 * k, 0.12 + 0.05 * k) if i < 4 else (-0.3, 0.2, 1.0),
             foot_l=(-5.0, 0.0, 1.0), foot_r=(5.0, 0.0, -1.0), eyes=i < 5,
             pane=(1.0, 0.85, 0.7, 0.6, 0.45, 0.3, 0.18, 0.08)[i],
             roll=[0, 0, 0, 0, 0.35, 0.9, 1.3, 1.45][i], cape_lag=(0.0, 2.0, -3.0))
    if i >= 4:
        p.lantern_on_staff = False
        p.extra["lantern_screen"] = (48.0 - 20.0 - (i - 4), 87.0)
    return p


def rise(i: int) -> Pose:
    """The lamp relights first; he gets up into its light."""
    p = death(7 - i)
    p.pane = (0.08, 0.2, 0.4, 0.6, 0.8, 1.0, 1.0, 1.0)[i]
    p.eyes = i >= 3
    if i >= 6:
        p.lantern_on_staff = True
    return p


def pose(anim: str, i: int) -> Pose:
    if anim.startswith("bolt"):
        return bolt(anim, i)
    return {"idle": idle, "walk": walk, "cast": cast, "channel": channel, "toss": toss, "dash": dash, "hurt": hurt,
            "death": death, "rise": rise}[anim](i)
