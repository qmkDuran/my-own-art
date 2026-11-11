"""Exploration music for LANTERNFALL, made from numbers: dark and uneasy rather than tuneful. A low drone with a
tritone ghost in it, a minor-second cluster that swells and fades, far bells that echo off nothing, reversed swells
that rise into silence, creaks that bend out of tune, a scrape of metal far off, and a heartbeat that does not keep
time. Everything sits in a long, cheap reverb so it sounds distant. Boss music stays in synth.py.
Run: python3 -I art/audio/dread.py   (writes game/audio/explore.ogg and cave.ogg)"""
from __future__ import annotations

import numpy as np
from scipy.signal import fftconvolve

import synth as s

ROOT = 36.71                              # D1
CLUSTER = (146.83, 155.56)                # D3 and E-flat 3: a minor second that grinds
FAR_NOTES = (587.33, 622.25, 830.61, 880.0, 1046.5)   # D, E-flat, G-sharp, A, C: a scale with the tritone in it
REVERB_S = 3.2
WET = 0.55
PEAK = 0.4                                # quieter than the boss: the drone never stops, so it reads loud


def place(out: np.ndarray, x: np.ndarray, at: float) -> None:
    i = int(s.SR * at)
    n = max(0, min(len(x), len(out) - i))
    out[i:i + n] += x[:n]


def low_drone(dur: float) -> np.ndarray:
    t = s.t_(dur)
    x = sum(a * np.sin(2 * np.pi * f * t + s.rng.uniform(0, 6)) for f, a in
            ((ROOT, 0.6), (ROOT * 1.004, 0.45), (ROOT * 2, 0.25), (ROOT * 2 * 1.414, 0.06)))   # the last: a tritone ghost
    return s.low(x * (0.7 + 0.3 * np.sin(2 * np.pi * t / dur * 3)), 220)


def cluster(dur: float) -> np.ndarray:
    """The minor second, swelling in over seconds and dying away, now and then."""
    out = np.zeros(int(s.SR * dur))
    at = s.rng.uniform(2, 6)
    while at < dur - 10:
        n = s.rng.uniform(7, 12)
        t = s.t_(n)
        x = sum(np.sin(2 * np.pi * f * t) + 0.3 * np.sin(2 * np.pi * f * 2.003 * t) for f in CLUSTER)
        place(out, 0.12 * s.low(x, 900) * np.sin(np.pi * t / n) ** 2, at)
        at += n + s.rng.uniform(6, 14)
    return out


def far_bell(f: float) -> np.ndarray:
    """A bell too far away: soft, dulled, and echoing three times."""
    b = s.low(s.bell(f, 3.5, 1.4), 2400)
    out = np.zeros(len(b) + int(s.SR * 2.4))
    for k, g in enumerate((1.0, 0.45, 0.2, 0.08)):
        place(out, g * b, k * 0.6)
    return out


def bells(dur: float) -> np.ndarray:
    out = np.zeros(int(s.SR * dur))
    at = s.rng.uniform(3, 6)
    while at < dur - 6:
        place(out, 0.09 * far_bell(float(s.rng.choice(FAR_NOTES))), at)
        at += s.rng.uniform(5, 11)
    return out


def reversed_swell(f: float) -> np.ndarray:
    """A bell and a breath played backwards: it rises out of nothing and stops dead."""
    n = 3.0
    x = s.bell(f, n, 1.0) + 0.5 * s.band(s.noise(n), f * 0.8, f * 1.6) * s.env(n, 0.01, 1.2)
    return s.low(x, 3000)[::-1]


def creak(dur: float = 2.2) -> np.ndarray:
    """A slow tone that sags out of tune, with a tremble in it: a rope, a door, a voice."""
    t = s.t_(dur)
    f = 310 - 26 * (t / dur) ** 1.5 + 4 * np.sin(2 * np.pi * 5.5 * t)
    x = np.sin(2 * np.pi * np.cumsum(f) / s.SR) + 0.3 * np.sin(4 * np.pi * np.cumsum(f) / s.SR)
    return s.low(x, 1400) * np.sin(np.pi * t / dur) ** 3


def scrape(dur: float = 1.8) -> np.ndarray:
    """Metal dragged on stone, somewhere else."""
    t = s.t_(dur)
    x = s.band(s.noise(dur), 1800, 2600, 4) * (0.5 + 0.5 * np.sin(2 * np.pi * 13 * t)) * np.sin(np.pi * t / dur) ** 2
    return s.low(x, 3000)


def oddities(dur: float) -> np.ndarray:
    """Reversed swells, creaks, scrapes and a heartbeat that comes in twos and threes, all sparse."""
    out = np.zeros(int(s.SR * dur))
    at = s.rng.uniform(6, 10)
    while at < dur - 8:
        pick = s.rng.integers(0, 4)
        if pick == 0:
            place(out, 0.14 * reversed_swell(float(s.rng.choice(FAR_NOTES)) / 2), at)
        elif pick == 1:
            place(out, 0.08 * creak(), at)
        elif pick == 2:
            place(out, 0.05 * scrape(), at)
        else:
            for k in range(int(s.rng.integers(2, 4))):
                place(out, 0.3 * s.sweep(62, 36, 0.32) * s.env(0.32, 0.004, 0.11), k * s.rng.uniform(0.7, 1.1))
        at += s.rng.uniform(7, 15)
    return out


def reverb(x: np.ndarray) -> np.ndarray:
    n = int(s.SR * REVERB_S)
    ir = s.rng.standard_normal(n) * np.exp(-np.linspace(0, 7, n))
    wet = fftconvolve(s.low(x, 5000), s.low(ir, 4000))[:len(x)]
    wet /= np.max(np.abs(wet)) + 1e-9
    return (1 - WET) * x / (np.max(np.abs(x)) + 1e-9) + WET * wet


def dread(dur: float) -> np.ndarray:
    t = s.t_(dur)
    wind = 0.1 * s.low(s.noise(dur), 300) * (0.5 + 0.5 * np.sin(2 * np.pi * t / 19) * np.sin(2 * np.pi * t / 7))
    return reverb(0.5 * low_drone(dur) + wind + cluster(dur) + bells(dur) + oddities(dur))


def main() -> None:
    s.music("explore", dread(96.0), PEAK)
    s.rng = np.random.default_rng(31)
    s.music("cave", s.low(dread(80.0), 1800), PEAK)
    print("dread music written")


if __name__ == "__main__":
    main()
