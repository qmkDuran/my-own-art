"""The music of Monster Tamer: title, town, route, grove and battle loops (all original), plus every sound
effect. Run: python3 -I art/audio/songs.py  (writes game/audio/*.wav)"""
from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

import numpy as np

from synth import (RATE, arps, bass, drums, envelope, freq, mix, noise, parse, pulse, save, triangle, voice)

SONGS = {
    "title": {
        "bpm": 84, "chords": ["F", "C", "D/min", "A#", "F", "C", "A#", "C"],
        "lead": "A4:1.5 G4:.5 F4:1 C5:1 | G4:2 E4:1 C4:1 | A4:1.5 C5:.5 D5:1 A4:1 | A#4:3 -:1 | "
                "C5:1.5 A4:.5 F4:1 A4:1 | G4:2 C5:1 E5:1 | D5:1.5 C5:.5 A#4:1 G4:1 | C5:3 -:1",
        "drums": "--------", "arp_oct": 4,
    },
    "town": {
        "bpm": 112, "chords": ["C", "A/min", "F", "G", "C", "A/min", "F", "G"],
        "lead": "E5:.5 G5:.5 C6:1 G5:.5 E5:.5 D5:1 | C5:.5 E5:.5 A5:1 G5:1 E5:1 | "
                "F5:.5 A5:.5 C6:1 A5:.5 F5:.5 E5:1 | D5:1 G5:1 B4:1 D5:1 | "
                "E5:.5 G5:.5 C6:1 D6:.5 C6:.5 G5:1 | A5:.5 G5:.5 E5:1 C5:1 E5:1 | "
                "F5:1 A5:.5 G5:.5 F5:1 E5:1 | D5:1.5 E5:.5 C5:2",
        "drums": "k-h-s-h-", "arp_oct": 4,
    },
    "route": {
        "bpm": 132, "chords": ["G", "E/min", "C", "D", "G", "E/min", "C", "D"],
        "lead": "D5:.5 G5:.5 B5:1 A5:.5 G5:.5 D5:1 | E5:1 G5:.5 B5:.5 E6:1.5 D6:.5 | "
                "C6:1 B5:.5 A5:.5 G5:1 E5:1 | F#5:1 A5:1 D6:2 | "
                "B5:.5 A5:.5 G5:1 D5:1 G5:1 | E5:.5 F#5:.5 G5:1 B5:1 E6:1 | "
                "C6:.5 B5:.5 A5:1 E5:1 A5:1 | D6:1 C6:.5 A5:.5 G5:2",
        "drums": "k-hhs-hh", "arp_oct": 4,
    },
    "grove": {
        "bpm": 92, "chords": ["D/min", "C", "G", "D/min", "A#", "C", "G", "A/min"],
        "lead": "A4:1 D5:1 E5:1 F5:1 | E5:2 C5:1 G4:1 | B4:1.5 D5:.5 G5:2 | F5:1 E5:1 D5:2 | "
                "D5:1 F5:1 A5:1 G5:1 | E5:2 G5:1 C5:1 | D5:1 B4:1 G4:1 B4:1 | A4:3 -:1",
        "drums": "k---h---", "arp_oct": 3,
    },
    "battle": {
        "bpm": 152, "chords": ["A/min", "A/min", "F", "G", "A/min", "A/min", "F", "E"],
        "lead": "A5:.5 -:.5 A5:.5 C6:.5 E6:1 D6:.5 C6:.5 | B5:1 C6:.5 B5:.5 A5:1 E5:1 | "
                "F5:.5 A5:.5 C6:.5 F6:.5 E6:1 C6:1 | D6:1 B5:.5 G5:.5 D6:1 B5:1 | "
                "A5:.5 -:.5 A5:.5 C6:.5 E6:1 G6:.5 E6:.5 | F6:1 E6:.5 D6:.5 C6:1 A5:1 | "
                "F5:.5 A5:.5 C6:.5 A5:.5 F6:1 E6:1 | E6:1 D6:.5 C6:.5 B5:1 G#5:1",
        "drums": "k-hsk-sh", "arp_oct": 3,
    },
}


def song(spec: dict) -> np.ndarray:
    beat = 60.0 / spec["bpm"]
    chords = spec["chords"]
    lead_notes = parse(spec["lead"].replace("|", " "))
    lead = voice(lead_notes, beat, lambda f, n: pulse(f, n, 0.25), 0.28)
    echo = np.concatenate([np.zeros(int(beat * 0.75 * RATE)), lead * 0.35])[:len(lead)]
    harmony = arps(chords, beat, spec["arp_oct"], 0.12, 0.125)
    low = bass(chords, beat, 2, 0.4, [1.5, 0.5, 1, 1])
    beats = drums(len(chords), beat, spec["drums"], 0.35) if spec["drums"].strip("-") else np.zeros(1)
    once = mix(lead, echo, harmony, low, beats)
    return np.concatenate([once, once])


def sweep(f0: float, f1: float, secs: float, duty: float = 0.5, vol: float = 0.6) -> np.ndarray:
    n = int(secs * RATE)
    f = np.geomspace(f0, f1, n)
    phase = np.cumsum(f) / RATE
    return np.where(phase % 1 < duty, 1.0, -1.0) * np.linspace(1, 0, n) * vol


def notes(seq: str, secs: float, duty: float = 0.5, vol: float = 0.5, tri: bool = False) -> np.ndarray:
    parts = []
    for name in seq.split():
        n = int(secs * RATE)
        wave_ = triangle(freq(name), n) if tri else pulse(freq(name), n, duty)
        parts.append(wave_ * envelope(n, decay=0.4, sustain=0.4) * vol)
    return np.concatenate(parts)


def thud(secs: float, vol: float) -> np.ndarray:
    n = int(secs * RATE)
    f = np.linspace(180, 50, n)
    return np.sin(2 * np.pi * np.cumsum(f) / RATE) * np.linspace(1, 0, n) ** 2 * vol


SFX = {
    "move": lambda: notes("A5", 0.03, 0.25, 0.3),
    "select": lambda: notes("C6 G6", 0.05, 0.25, 0.35),
    "cancel": lambda: notes("G5 C5", 0.05, 0.25, 0.3),
    "bump": lambda: thud(0.08, 0.6),
    "door": lambda: sweep(300, 120, 0.15, 0.5, 0.4),
    "alert": lambda: notes("E6 E6", 0.06, 0.25, 0.4),
    "encounter": lambda: np.concatenate([sweep(200, 900, 0.25), sweep(900, 400, 0.15)]),
    "hit": lambda: noise(int(0.12 * RATE), 3) * np.linspace(1, 0, int(0.12 * RATE)) * 0.7,
    "hit_strong": lambda: mix(noise(int(0.18 * RATE), 4) * np.linspace(1, 0, int(0.18 * RATE)), thud(0.18, 0.8)),
    "timing_perfect": lambda: notes("C6 E6 G6 C7", 0.04, 0.125, 0.35),
    "timing_good": lambda: notes("C6 G6", 0.05, 0.125, 0.3),
    "timing_miss": lambda: notes("C5", 0.04, 0.5, 0.15),
    "heal": lambda: notes("C5 E5 G5 C6 E6", 0.07, 0.5, 0.3, True),
    "buff": lambda: sweep(300, 1200, 0.25, 0.25, 0.35),
    "debuff": lambda: sweep(1000, 250, 0.25, 0.25, 0.35),
    "trust": lambda: notes("E6 G6 B6", 0.06, 0.5, 0.3, True),
    "befriend": lambda: notes("C5 E5 G5 C6 G5 C6 E6", 0.1, 0.25, 0.35),
    "level": lambda: notes("G5 A5 B5 D6", 0.07, 0.25, 0.35),
    "evolve": lambda: notes("C5 G5 C6 E6 G6 C7", 0.12, 0.25, 0.35),
    "restore": lambda: notes("F5 A5 C6 F6 A6 C7 F7", 0.12, 0.5, 0.3, True),
    "jingle": lambda: notes("C6 E6 G6", 0.08, 0.25, 0.3),
    "save": lambda: notes("G5 C6", 0.08, 0.5, 0.3, True),
    "buy": lambda: notes("B5 E6", 0.05, 0.25, 0.3),
}


if __name__ == "__main__":
    for name, spec in SONGS.items():
        save("music_" + name, song(spec))
    for name, make in SFX.items():
        save("sfx_" + name, make())
    print("audio written:", len(SONGS), "songs,", len(SFX), "effects")
