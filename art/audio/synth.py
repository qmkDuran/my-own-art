"""Every sound in LANTERNFALL, synthesised from numbers (numpy/scipy). CC0, made for this game.
Writes game/audio/*.wav (effects) and *.ogg (music loops, via ffmpeg). Run: python3 -I art/audio/synth.py"""
from __future__ import annotations

import subprocess
from pathlib import Path

import numpy as np
from scipy.io import wavfile
from scipy.signal import butter, sosfilt

SR = 44100
OUT = Path(__file__).resolve().parents[2] / "game" / "audio"
rng = np.random.default_rng(7)


# ------------------------------------------------------------------ building blocks
def t_(dur: float) -> np.ndarray:
    return np.arange(int(SR * dur)) / SR


def env(dur: float, a: float, d: float, curve: float = 4.0) -> np.ndarray:
    t = t_(dur)
    e = np.minimum(1.0, t / max(a, 1e-4)) * np.exp(-np.maximum(0.0, t - a) * curve / max(d, 1e-4))
    return e


def noise(dur: float) -> np.ndarray:
    return rng.uniform(-1, 1, int(SR * dur))


def band(x: np.ndarray, lo: float, hi: float, order: int = 2) -> np.ndarray:
    return sosfilt(butter(order, [lo, hi], btype="band", fs=SR, output="sos"), x)


def low(x: np.ndarray, f: float, order: int = 2) -> np.ndarray:
    return sosfilt(butter(order, f, btype="low", fs=SR, output="sos"), x)


def high(x: np.ndarray, f: float, order: int = 2) -> np.ndarray:
    return sosfilt(butter(order, f, btype="high", fs=SR, output="sos"), x)


def sine(freq: np.ndarray | float, dur: float, phase: float = 0.0) -> np.ndarray:
    f = np.broadcast_to(np.asarray(freq, dtype=float), (int(SR * dur),))
    return np.sin(2 * np.pi * np.cumsum(f) / SR + phase)


def sweep(f0: float, f1: float, dur: float) -> np.ndarray:
    return sine(np.geomspace(f0, f1, int(SR * dur)), dur)


def bell(freq: float, dur: float, decay: float = 3.0) -> np.ndarray:
    """A glassy bell: inharmonic partials with their own decays."""
    out = np.zeros(int(SR * dur))
    for k, (ratio, amp) in enumerate(((1.0, 1.0), (2.76, 0.5), (5.4, 0.25), (8.93, 0.12))):
        out += amp * sine(freq * ratio, dur) * env(dur, 0.002, dur / (decay * (1 + k * 0.8)))
    return out


def mix(*parts: np.ndarray) -> np.ndarray:
    n = max(len(p) for p in parts)
    out = np.zeros(n)
    for p in parts:
        out[:len(p)] += p
    return out


def pad_to(x: np.ndarray, dur: float) -> np.ndarray:
    out = np.zeros(int(SR * dur))
    out[:min(len(x), len(out))] = x[:len(out)]
    return out


def write(name: str, x: np.ndarray, peak: float = 0.85) -> None:
    x = x / (np.max(np.abs(x)) + 1e-9) * peak
    fade = min(len(x), int(SR * 0.01))
    x[-fade:] *= np.linspace(1, 0, fade)
    wavfile.write(OUT / f"{name}.wav", SR, (x * 32767).astype(np.int16))


# ------------------------------------------------------------------ effects
def effects() -> None:
    write("hit", mix(low(noise(0.09), 900) * env(0.09, 0.001, 0.03), 0.6 * sweep(180, 60, 0.09) * env(0.09, 0.001, 0.05),
                     0.25 * bell(1900, 0.12, 6)), 0.7)
    write("bolt", mix(0.7 * sweep(1400, 520, 0.14) * env(0.14, 0.002, 0.06), band(noise(0.14), 1800, 5200) * env(0.14, 0.001, 0.04),
                      0.25 * bell(2200, 0.14, 7)), 0.6)
    write("crack", mix(high(noise(0.16), 2500) * env(0.16, 0.001, 0.02, 6), 0.5 * band(noise(0.16), 400, 1800) * env(0.16, 0.002, 0.05),
                       0.3 * bell(2600, 0.16, 5)), 0.8)
    write("flare", mix(0.9 * sweep(220, 50, 0.7) * env(0.7, 0.005, 0.3), low(noise(0.7), 1400) * env(0.7, 0.05, 0.25),
                       0.35 * mix(bell(1320, 0.7), bell(1980, 0.7)) * env(0.7, 0.03, 0.4)), 0.85)
    write("lantern_throw", band(noise(0.3), 500, 2500) * env(0.3, 0.1, 0.1), 0.5)
    write("lantern_land", mix(0.8 * sweep(140, 45, 0.5) * env(0.5, 0.001, 0.15), 0.5 * bell(820, 0.5, 4),
                              low(noise(0.5), 2000) * env(0.5, 0.02, 0.25)), 0.85)
    write("lantern_catch", 0.6 * bell(1240, 0.25, 6), 0.45)
    flutter = (0.5 + 0.5 * np.sign(np.sin(2 * np.pi * 34 * t_(0.45))))
    write("moths", band(noise(0.45), 700, 3500) * flutter * env(0.45, 0.04, 0.2) + 0.2 * bell(2200, 0.45), 0.5)
    write("dash", band(noise(0.26), 300, 2200) * env(0.26, 0.03, 0.1) + 0.3 * sweep(400, 900, 0.26) * env(0.26, 0.01, 0.1), 0.5)
    write("tonic", mix(0.6 * bell(660, 0.6), 0.4 * bell(990, 0.6), 0.3 * low(noise(0.6), 500) * env(0.6, 0.05, 0.2)), 0.5)
    write("hurt", mix(0.8 * sweep(160, 70, 0.25) * env(0.25, 0.001, 0.08), band(noise(0.25), 200, 900) * env(0.25, 0.005, 0.07)), 0.7)
    write("die_dark", mix(0.8 * sweep(200, 35, 0.5) * env(0.5, 0.002, 0.2), 0.5 * low(noise(0.5), 600) * env(0.5, 0.05, 0.25)), 0.7)
    write("die_glass", mix(*[0.4 * pad_to(np.concatenate([np.zeros(int(SR * rng.uniform(0, 0.12))), bell(rng.uniform(1800, 4200), 0.35, 5)]), 0.5)
                             for _ in range(9)], 0.6 * high(noise(0.5), 3000) * env(0.5, 0.001, 0.08)), 0.7)
    write("hiss", band(noise(0.3), 2000, 6000) * env(0.3, 0.08, 0.12), 0.35)
    write("leap", mix(band(noise(0.25), 120, 600) * env(0.25, 0.02, 0.12), 0.4 * sweep(90, 160, 0.25) * env(0.25, 0.02, 0.1)), 0.5)
    write("shard", mix(0.6 * sweep(3600, 1200, 0.28) * env(0.28, 0.002, 0.1), 0.3 * bell(2900, 0.28)), 0.5)
    write("boss_wind", mix(low(noise(0.8), 300) * np.linspace(0.2, 1, int(SR * 0.8)), 0.6 * sweep(50, 95, 0.8) * env(0.8, 0.6, 0.2)), 0.7)
    write("slam", mix(1.0 * sweep(110, 30, 0.9) * env(0.9, 0.001, 0.35), low(noise(0.9), 900) * env(0.9, 0.002, 0.25),
                      0.5 * high(noise(0.9), 2500) * env(0.9, 0.01, 0.15)), 0.95)
    write("chest", mix(band(noise(0.5), 250, 700) * env(0.5, 0.15, 0.2), 0.5 * pad_to(np.concatenate([np.zeros(int(SR * 0.25)), bell(1320, 0.5)]), 0.75)), 0.6)
    write("relight", mix(0.5 * sweep(220, 440, 1.0) * env(1.0, 0.4, 0.4), low(noise(1.0), 800) * env(1.0, 0.5, 0.3) * 0.4), 0.5)
    write("lamp_lit", mix(*[0.35 * bell(f, 2.0, 1.5) for f in (293.7, 440.0, 587.3, 880.0)], 0.5 * low(noise(2.0), 1200) * env(2.0, 0.05, 0.6)), 0.75)
    write("drop_item", 0.5 * bell(1600, 0.18, 6), 0.35)
    write("drop_rare", mix(*[0.4 * pad_to(np.concatenate([np.zeros(int(SR * 0.07 * k)), bell(f, 0.7)]), 1.0)
                             for k, f in enumerate((880, 1108.7, 1318.5, 1760))]), 0.6)
    write("pickup", 0.5 * bell(1046.5, 0.15, 6) + 0.3 * band(noise(0.15), 2000, 5000) * env(0.15, 0.001, 0.03), 0.4)
    write("level_up", mix(*[0.4 * pad_to(np.concatenate([np.zeros(int(SR * 0.11 * k)), bell(f, 1.2, 2)]), 1.6)
                            for k, f in enumerate((293.7, 440, 587.3, 740, 880))]), 0.75)
    write("ui_click", 0.6 * bell(1800, 0.06, 8), 0.3)
    write("ui_open", mix(band(noise(0.12), 600, 2000) * env(0.12, 0.01, 0.04), 0.3 * bell(1200, 0.12, 6)), 0.3)


# ------------------------------------------------------------------ music
D_MINOR = [146.83, 174.61, 196.0, 220.0, 261.63, 293.66, 349.23, 392.0, 440.0, 523.25, 587.33]


def drone(dur: float, root: float) -> np.ndarray:
    t = t_(dur)
    x = sum(a * np.sin(2 * np.pi * f * t + rng.uniform(0, 6)) for f, a in ((root, 0.5), (root * 1.003, 0.4), (root * 1.5, 0.3),
                                                                            (root * 2.0, 0.15)))
    swell = 0.6 + 0.4 * np.sin(2 * np.pi * t / dur * 4)
    return x * swell


def explore(dur: float = 64.0) -> np.ndarray:
    """Exploring: a low drone, wind in the glass, slow chimes from the D minor pentatonic, a far heartbeat."""
    out = 0.35 * drone(dur, 73.42) + 0.12 * low(noise(dur), 400) * (0.6 + 0.4 * np.sin(2 * np.pi * t_(dur) / 16))
    pent = [146.83, 174.61, 220.0, 261.63, 293.66, 349.23, 440.0, 523.25]
    for k in range(int(dur / 1.6)):
        if rng.random() < 0.7:
            start = int(SR * (k * 1.6 + rng.uniform(0, 0.4)))
            b = 0.18 * bell(rng.choice(pent) * 2, 3.0, 1.2)
            out[start:start + len(b)] += b[:max(0, len(out) - start)]
    for k in range(int(dur / 4)):
        start = int(SR * k * 4)
        thump = 0.25 * sweep(70, 40, 0.3) * env(0.3, 0.005, 0.12)
        out[start:start + len(thump)] += thump[:max(0, len(out) - start)]
    return out


def boss(dur: float = 48.0) -> np.ndarray:
    """The Glazier: 120 bpm drums, a driving bass ostinato, a tense string pad, glass hits on the off-beats."""
    bpm = 120
    beat = 60 / bpm
    out = 0.25 * low(drone(dur, 73.42), 600)
    bass_line = [73.42, 73.42, 87.31, 65.41]
    for b in range(int(dur / beat)):
        s = int(SR * b * beat)
        kick = (1.0 if b % 2 == 0 else 0.6) * sweep(120, 40, 0.35) * env(0.35, 0.001, 0.12)
        out[s:s + len(kick)] += kick[:max(0, len(out) - s)]
        f = bass_line[(b // 4) % 4]
        note = 0.35 * low(np.sign(sine(f, beat * 0.9)), 500) * env(beat * 0.9, 0.005, beat * 0.6)
        out[s:s + len(note)] += note[:max(0, len(out) - s)]
        if b % 4 == 3:
            sn = 0.4 * band(noise(0.25), 800, 5000) * env(0.25, 0.001, 0.06)
            out[s:s + len(sn)] += sn[:max(0, len(out) - s)]
        if b % 8 == 5:
            g = 0.2 * bell(rng.choice([1174.66, 1396.91, 1760.0]), 1.0, 2)
            out[s:s + len(g)] += g[:max(0, len(out) - s)]
    saw = sum(np.sin(2 * np.pi * 146.83 * k * t_(dur) * 1.0) / k for k in range(1, 8))
    out += 0.08 * low(saw, 1200) * (0.5 + 0.5 * np.sin(2 * np.pi * t_(dur) / 8))
    return out


def music(name: str, x: np.ndarray) -> None:
    x = x / (np.max(np.abs(x)) + 1e-9) * 0.8
    xf = int(SR * 2)
    x[:xf] = x[:xf] * np.linspace(0, 1, xf) + x[-xf:] * np.linspace(1, 0, xf)
    x = x[:-xf]
    tmp = OUT / f"{name}_tmp.wav"
    wavfile.write(tmp, SR, (x * 32767).astype(np.int16))
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(tmp), "-c:a", "libvorbis", "-q:a", "4", str(OUT / f"{name}.ogg")],
                   check=True)
    tmp.unlink()


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    effects()
    music("explore", explore())
    music("boss", boss())
    print("audio written to", OUT)


if __name__ == "__main__":
    main()
