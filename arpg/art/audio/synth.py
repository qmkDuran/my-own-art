"""Procedural audio for the ARPG prototype (all original, CC0). Reuses the heaven synth's instruments and helpers.
Writes game/audio/*.ogg (loops) and *.wav (one-shots). Run from heaven/arpg/:  python3 art/audio/synth.py"""
import os, sys
import numpy as np
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'art', 'audio'))
import synth as hs                                                         # noqa: E402  heaven's synth module
from synth import SR, midi, t_axis, lp, hp, bp, pad_note, choir_note, bell, reverb, place, wrap, periodic_noise  # noqa: E402

hs.OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'game', 'audio') + '/'
os.makedirs(hs.OUT, exist_ok=True)
rng = np.random.default_rng(12)


def noise(d): return rng.standard_normal((int(d * SR), 2))
def env_exp(d, k): return np.exp(-t_axis(d) * k)[:, None]


# ------------------------------------------------------------------ loops
def night_music():
    """A low, watchful D minor drone with slow pads and a distant choir: grief, but hope (Dan 12:1)."""
    chords = [[38, 45, 50, 53], [34, 41, 46, 50], [36, 43, 48, 52], [33, 40, 45, 49]]   # Dm  Bb  C  A
    cd = 8.0; period = cd * len(chords); total = period + 6
    buf = np.zeros((int(total * SR), 2))
    for i, ch in enumerate(chords):
        for n in ch: place(buf, pad_note(midi(n), cd + 1.0, a=2.5, r=3.0, bright=0.9) * 0.9, i * cd)
        place(buf, choir_note(midi(ch[-1] + 12), cd, a=3.0, r=3.0) * 0.35, i * cd + 1.0)
    t = t_axis(total)
    drone = np.sin(2 * np.pi * midi(26) * t) * 0.12 * (0.8 + 0.2 * np.sin(2 * np.pi * t / period * 4))
    buf += np.stack([drone, drone], 1)
    return wrap(reverb(buf, 3.5, 0.45), period)


def night_wind():
    period = 12.0
    n = periodic_noise(period)
    w = np.stack([bp(n[:, c], 120, 900) for c in range(2)], 1)
    t = t_axis(period)
    return w * (0.5 + 0.5 * np.sin(2 * np.pi * t[:, None] / period * 2 + np.array([0, 1.3]))) * 0.6


# ------------------------------------------------------------------ one-shots
def swing():
    d = 0.28; s = np.stack([bp(noise(d)[:, c], 600, 4200) for c in range(2)], 1)
    t = t_axis(d); return s * (np.sin(np.pi * t / d) ** 3)[:, None]


def hit():
    d = 0.3; t = t_axis(d)
    thump = np.sin(2 * np.pi * (140 - 200 * t) * t)[:, None] * env_exp(d, 22)
    crack = np.stack([hp(noise(d)[:, c], 2500) for c in range(2)], 1) * env_exp(d, 60)
    ring = bell(1320, d, 0.4, decays=(0.15, 0.08, 0.05, 0.03))[:len(t)]
    return thump * 1.0 + crack * 0.5 + ring * 0.3


def dissolve():
    """A shadow coming apart: a falling, breathy hiss."""
    d = 0.9; t = t_axis(d)
    s = np.stack([bp(noise(d)[:, c], 200, 1600) for c in range(2)], 1)
    tone = np.sin(2 * np.pi * (220 - 160 * t / d) * t)[:, None] * 0.25
    return (s * 0.8 + tone) * (env_exp(d, 3.5) * np.clip(t / 0.05, 0, 1)[:, None])


def rebuke():
    """'The Lord rebuke you!' (Jude 9): a strong open fifth with a burst of air."""
    d = 1.6; buf = np.zeros((int(d * SR), 2))
    for n in (38, 45, 50, 57): place(buf, pad_note(midi(n), 1.2, a=0.02, r=0.9, bright=2.2), 0)
    burst = np.stack([bp(noise(d)[:, c], 300, 3000) for c in range(2)], 1) * env_exp(d, 6) * 0.6
    return reverb(buf + burst, 1.8, 0.35)


def trumpet():
    """The trumpet call (1 Thess 4:16): a bright brass-like rising call."""
    d = 1.8; t = t_axis(d); buf = np.zeros((len(t), 2))
    for i, (n, at, ln) in enumerate(((62, 0.0, 0.35), (69, 0.32, 0.35), (74, 0.64, 1.1))):
        tt = t_axis(ln); f = midi(n) * (1 + 0.006 * np.sin(2 * np.pi * 5.5 * tt))
        ph = 2 * np.pi * np.cumsum(f) / SR
        tone = sum(np.sin(k * ph) * (0.9 ** k) for k in range(1, 9))
        e = np.clip(tt / 0.04, 0, 1) * np.clip((ln - tt) / 0.12, 0, 1)
        place(buf, np.stack([tone * e, tone * e], 1) * 0.3, at)
    return reverb(buf, 2.4, 0.4)


def shield_block():
    return reverb(bell(880, 0.8, 0.8, ratios=(1, 2.2, 3.9, 5.6), decays=(0.4, 0.25, 0.15, 0.1)), 0.8, 0.2)


def dash():
    d = 0.35; s = np.stack([bp(noise(d)[:, c], 300, 2400) for c in range(2)], 1)
    t = t_axis(d); return s * (np.sin(np.pi * t / d) ** 2)[:, None]


def pickup():
    return bell(1568, 0.5, 0.6, decays=(0.3, 0.15, 0.1, 0.05)) + bell(2093, 0.5, 0.4, decays=(0.25, 0.12, 0.08, 0.04))


def rare_drop():
    buf = np.zeros((int(1.6 * SR), 2))
    for i, n in enumerate((76, 79, 83, 88)): place(buf, bell(midi(n), 1.2, 0.6), i * 0.08)
    return reverb(buf, 1.5, 0.3)


def level_up():
    buf = np.zeros((int(2.4 * SR), 2))
    for i, n in enumerate((62, 66, 69, 74, 78)): place(buf, bell(midi(n), 1.6, 0.7), i * 0.11)
    for n in (50, 57, 62): place(buf, pad_note(midi(n), 1.8, a=0.1, r=1.0) * 0.6, 0.0)
    return reverb(buf, 2.0, 0.35)


def bolt():
    """The caster's 'flaming arrow' (Eph 6:16): a dark crackling fizz."""
    d = 0.5; t = t_axis(d)
    s = np.stack([bp(noise(d)[:, c], 900, 5000) for c in range(2)], 1) * (rng.random((len(t), 1)) > 0.6)
    return s * env_exp(d, 5) + np.sin(2 * np.pi * (300 - 200 * t) * t)[:, None] * env_exp(d, 8) * 0.3


def demon_hurt():
    d = 0.25; t = t_axis(d)
    growl = np.sin(2 * np.pi * (90 + 30 * np.sin(2 * np.pi * 30 * t)) * t)
    s = np.stack([growl, growl], 1) + np.stack([lp(noise(d)[:, c], 700) for c in range(2)], 1) * 0.6
    return s * env_exp(d, 10)


def prayer_answered():
    buf = np.zeros((int(3.0 * SR), 2))
    for n in (62, 66, 69, 74): place(buf, choir_note(midi(n), 2.2, a=0.4, r=1.4) * 0.6, 0.0)
    for i, n in enumerate((81, 86, 90)): place(buf, bell(midi(n), 2.0, 0.5), 0.3 + i * 0.25)
    return reverb(buf, 3.0, 0.4)


def step():
    d = 0.12; s = np.stack([lp(noise(d)[:, c], 900) for c in range(2)], 1)
    return s * env_exp(d, 40)


if __name__ == '__main__':
    hs.save('night_music', night_music(), loop=True, peak_db=-6)
    hs.save('night_wind', night_wind(), loop=True, peak_db=-12)
    for name, fn, pk in (('swing', swing, -8), ('hit', hit, -5), ('dissolve', dissolve, -7), ('rebuke', rebuke, -4),
                         ('trumpet', trumpet, -4), ('shield', shield_block, -6), ('dash', dash, -9), ('pickup', pickup, -8),
                         ('rare_drop', rare_drop, -6), ('level_up', level_up, -5), ('bolt', bolt, -9),
                         ('demon_hurt', demon_hurt, -9), ('prayer', prayer_answered, -5), ('step', step, -14)):
        hs.save(name, fn(), peak_db=pk)
