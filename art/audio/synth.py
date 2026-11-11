"""Code-made chiptune for Monster Tamer: four-voice music loops (pulse lead, pulse harmony, triangle bass,
noise drums) and every sound effect, written as 16-bit mono WAVs into game/audio/. All composed for this game.
Run: python3 -I art/audio/synth.py"""
from __future__ import annotations

import wave
from pathlib import Path

import numpy as np

RATE = 22050
OUT = Path(__file__).resolve().parents[2] / "game" / "audio"
NOTE_INDEX = {"C": 0, "C#": 1, "D": 2, "D#": 3, "E": 4, "F": 5, "F#": 6, "G": 7, "G#": 8, "A": 9, "A#": 10, "B": 11}


def freq(note: str) -> float:
    name, octave = note[:-1], int(note[-1])
    return 440.0 * 2 ** ((NOTE_INDEX[name] + 12 * (octave + 1) - 69) / 12)


def pulse(f: float, n: int, duty: float = 0.5) -> np.ndarray:
    t = np.arange(n) * f / RATE
    return np.where((t % 1.0) < duty, 1.0, -1.0)


def triangle(f: float, n: int) -> np.ndarray:
    t = (np.arange(n) * f / RATE) % 1.0
    return 4 * np.abs(t - 0.5) - 1


def noise(n: int, seed: int = 1) -> np.ndarray:
    return np.random.default_rng(seed).uniform(-1, 1, n)


def envelope(n: int, attack: float = 0.005, decay: float = 0.6, sustain: float = 0.6) -> np.ndarray:
    a = max(1, int(attack * RATE))
    env = np.full(n, sustain)
    env[:a] = np.linspace(0, 1, a)
    d = min(n - a, int(decay * RATE * 0.25))
    if d > 0:
        env[a:a + d] = np.linspace(1, sustain, d)
    rel = min(n, int(0.03 * RATE))
    env[-rel:] *= np.linspace(1, 0, rel)
    return env


def voice(notes: list[tuple[str, float]], beat: float, wave_fn, vol: float) -> np.ndarray:
    """A melody line: (note or '-', length in beats)."""
    parts = []
    for note, beats in notes:
        n = int(beat * beats * RATE)
        if note == "-":
            parts.append(np.zeros(n))
        else:
            parts.append(wave_fn(freq(note), n) * envelope(n) * vol)
    return np.concatenate(parts)


def parse(line: str) -> list[tuple[str, float]]:
    """'C5:1 E5:.5 -:.5' -> [(C5, 1), (E5, .5), (-, .5)]"""
    out = []
    for tok in line.split():
        note, beats = tok.split(":")
        out.append((note, float(beats)))
    return out


def drums(bars: int, beat: float, pattern: str, vol: float) -> np.ndarray:
    """pattern per bar of 8 eighths: k kick, s snare, h hat, - rest."""
    step = int(beat / 2 * RATE)
    out = np.zeros(step * 8 * bars)
    for b in range(bars):
        for i, ch in enumerate(pattern):
            at = (b * 8 + i) * step
            if ch == "k":
                n = int(0.12 * RATE)
                f = np.linspace(120, 40, n)
                hit = np.sin(2 * np.pi * np.cumsum(f) / RATE) * np.linspace(1, 0, n) ** 2
            elif ch == "s":
                n = int(0.1 * RATE)
                hit = noise(n, b * 8 + i) * np.linspace(1, 0, n) ** 2 * 0.6
            elif ch == "h":
                n = int(0.03 * RATE)
                hit = noise(n, 99 + i) * np.linspace(1, 0, n) * 0.3
            else:
                continue
            out[at:at + len(hit)] += hit[:len(out) - at] * vol
    return out


def arps(chords: list[str], beat: float, octave: int, vol: float, duty: float = 0.25) -> np.ndarray:
    """Each chord one bar of eighth-note arpeggios (root, third, fifth, third...)."""
    out = []
    for chord in chords:
        root, kind = chord.split("/") if "/" in chord else (chord, "maj")
        steps = [0, 4, 7, 12] if kind == "maj" else [0, 3, 7, 12]
        base = NOTE_INDEX[root]
        for i in range(8):
            semis = base + steps[[0, 1, 2, 3, 2, 1, 2, 1][i]]
            name = [k for k, v in NOTE_INDEX.items() if v == semis % 12][0]
            note = f"{name}{octave + semis // 12}"
            n = int(beat / 2 * RATE)
            out.append(pulse(freq(note), n, duty) * envelope(n, decay=0.3, sustain=0.3) * vol)
    return np.concatenate(out)


def bass(chords: list[str], beat: float, octave: int, vol: float, pattern: list[float]) -> np.ndarray:
    out = []
    for chord in chords:
        root = chord.split("/")[0]
        for beats in pattern:
            out.append(triangle(freq(f"{root}{octave}"), int(beat * beats * RATE)) * vol)
    return np.concatenate(out)


def mix(*tracks: np.ndarray) -> np.ndarray:
    n = max(len(t) for t in tracks)
    out = np.zeros(n)
    for t in tracks:
        out[:len(t)] += t
    peak = np.max(np.abs(out)) or 1
    return out / peak * 0.8


def save(name: str, data: np.ndarray) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    pcm = (np.clip(data, -1, 1) * 32000).astype("<i2")
    with wave.open(str(OUT / f"{name}.wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(pcm.tobytes())
