"""Tallow's sound, made from numbers: not music but the town itself. Wind over the ramparts, the Great Lantern's
low roar and crackle, a smith's hammer from the forge in bursts, a murmur of people you cannot make out, a cart
now and then, and the Order's bell far off. Run: cd art/audio && python3 town.py   (writes game/audio/town.ogg)"""
from __future__ import annotations

import numpy as np

import synth as s
from dread import place, reverb

DUR = 72.0
PEAK = 0.45
HAMMER = 1250.0                           # the anvil's ring
BELL = 196.0


def lantern_roar(dur: float) -> np.ndarray:
    t = s.t_(dur)
    roar = s.low(s.noise(dur), 160) * (0.8 + 0.2 * np.sin(2 * np.pi * t / 5.3))
    crackle = np.zeros(len(t))
    for _ in range(int(dur * 9)):
        place(crackle, s.high(s.noise(0.02), 2500) * s.env(0.02, 0.001, 0.006) * s.rng.uniform(0.2, 1.0), s.rng.uniform(0, dur - 0.1))
    return 0.6 * roar + 0.12 * crackle


def hammer(dur: float) -> np.ndarray:
    """The forge: three to six strikes, a rest, again."""
    out = np.zeros(int(s.SR * dur))
    at = s.rng.uniform(1, 4)
    while at < dur - 6:
        for k in range(int(s.rng.integers(3, 7))):
            ring = s.bell(HAMMER * s.rng.uniform(0.98, 1.02), 0.6, 9)
            place(out, 0.18 * s.low(ring, 4000), at + k * 0.62)
            place(out, 0.1 * s.band(s.noise(0.05), 2000, 6000) * s.env(0.05, 0.001, 0.01), at + k * 0.62)
        at += s.rng.uniform(7, 13)
    return out


def murmur(dur: float) -> np.ndarray:
    """Voices too far to understand: speech-band noise shaped at the pace of syllables."""
    t = s.t_(dur)
    voices = sum(s.band(s.noise(dur), lo, lo * 2.2) for lo in (300.0, 600.0))
    syll = np.clip(np.sin(2 * np.pi * 4.3 * t + 3 * np.sin(2 * np.pi * 0.31 * t)), 0, 1) ** 2
    swell = 0.5 + 0.5 * np.sin(2 * np.pi * t / 17)
    return 0.12 * voices * (0.3 + 0.7 * syll) * swell


def carts_and_bell(dur: float) -> np.ndarray:
    out = np.zeros(int(s.SR * dur))
    for at in np.arange(s.rng.uniform(5, 9), dur - 4, 23.0):
        n = 3.0
        rumble = s.low(s.noise(n), 220) * np.sin(np.pi * s.t_(n) / n) ** 2
        clack = sum(np.roll(s.high(s.noise(n), 1500) * s.env(n, 0.001, 0.02), int(s.SR * k * 0.28)) for k in range(9))
        place(out, 0.25 * rumble + 0.04 * clack * np.sin(np.pi * s.t_(n) / n), float(at))
    for at in (14.0, 52.0):
        place(out, 0.06 * s.low(s.bell(BELL, 5.0, 0.8) + 0.5 * s.bell(BELL * 2.76, 5.0, 1.5), 1800), at)
    return out


def town(dur: float) -> np.ndarray:
    t = s.t_(dur)
    wind = 0.15 * s.band(s.noise(dur), 200, 900) * (0.5 + 0.5 * np.sin(2 * np.pi * t / 11))
    return reverb(wind + lantern_roar(dur) + hammer(dur) + murmur(dur) + carts_and_bell(dur))


def main() -> None:
    s.rng = np.random.default_rng(53)
    s.music("town", town(DUR), PEAK)
    print("town ambience written")


if __name__ == "__main__":
    main()
