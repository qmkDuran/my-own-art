"""Layered combat and UI sounds: CC0 recordings (art/audio/cc0/, see game/audio/CREDITS.md) mixed with
synthesised layers (art/audio/synth.py) so every hit has a body, an attack and low end.
Writes game/audio/*.wav. Run after synth.py: python3 -I art/audio/layer.py"""
from __future__ import annotations

import subprocess
from pathlib import Path

import numpy as np

import synth as sy

CC0 = Path(__file__).resolve().parent / "cc0"


def rec(name: str, gain: float = 1.0, pitch: float = 1.0) -> np.ndarray:
    """A CC0 recording, mono, at the synth's rate (and optionally pitched by resampling)."""
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", str(CC0 / f"{name}.ogg"), "-ac", "1", "-ar", str(int(sy.SR / pitch)),
                          "-f", "s16le", "-"], capture_output=True, check=True).stdout
    x = np.frombuffer(raw, dtype=np.int16).astype(np.float64) / 32768.0
    return x / (np.max(np.abs(x)) + 1e-9) * gain


def thump(dur: float, f0: float = 110.0, f1: float = 38.0, gain: float = 1.0) -> np.ndarray:
    """The low end under a big hit or a kill."""
    return gain * sy.sweep(f0, f1, dur) * sy.env(dur, 0.002, dur * 0.6)


def whoosh(dur: float, gain: float = 0.6) -> np.ndarray:
    return gain * sy.band(sy.noise(dur), 600, 3200) * sy.env(dur, dur * 0.4, dur * 0.4)


def sizzle(dur: float, gain: float = 0.35) -> np.ndarray:
    return gain * sy.high(sy.noise(dur), 3500) * sy.env(dur, 0.005, dur * 0.5)


def main() -> None:
    sy.write("bolt", sy.mix(rec("rpg_spell_01", 0.8, 1.15), whoosh(0.22), sy.pad_to(sizzle(0.15, 0.2), 0.22)), 0.7)
    sy.write("impact", sy.mix(rec("sfx_hit_01", 0.8), thump(0.22, 140, 50, 0.9), sizzle(0.25)), 0.85)
    sy.write("kill_thump", sy.mix(rec("bang_bang_02", 0.7, 0.8), thump(0.5, 90, 30, 1.0)), 0.9)
    sy.write("flare", sy.mix(rec("rpg_spell_fire_05", 0.9), thump(0.4, 120, 40, 0.7)), 0.9)
    sy.write("hurt_dark", rec("rpg_creature_slime_03", 0.7, 1.3), 0.6)
    sy.write("hurt_moth", rec("rpg_creature_misc_02", 0.7, 1.5), 0.55)
    sy.write("hurt_beast", rec("rpg_creature_hurt_01", 0.8), 0.6)
    sy.write("hurt_glass", sy.mix(rec("sfx_glass_02", 0.7, 1.2), sizzle(0.2, 0.2)), 0.6)
    sy.write("die_dark", sy.mix(rec("rpg_creature_slime_01", 0.9), thump(0.35, 90, 35, 0.6)), 0.8)
    sy.write("die_moth", sy.mix(rec("rpg_creature_die_01", 0.7, 1.4), sizzle(0.4, 0.3)), 0.75)
    sy.write("die_beast", sy.mix(rec("rpg_creature_monster_03", 0.9), thump(0.4, 100, 35, 0.7)), 0.85)
    sy.write("die_glass", sy.mix(rec("sfx_glass_02", 0.8, 0.8), rec("rpg_stones_01", 0.6), thump(0.3, 120, 45, 0.5)), 0.8)
    sy.write("die_boss", sy.mix(rec("rpg_creature_roar_02", 1.0, 0.8), rec("bang_cannon_01", 0.8, 0.8), thump(1.0, 70, 25, 1.0)), 0.95)
    sy.write("die_straw", sy.mix(rec("sfx_paper_02", 0.8), rec("rpg_wood_02", 0.6)), 0.6)
    sy.write("pickup", rec("rpg_item_coins_01", 0.8), 0.6)
    sy.write("drop_rare", sy.mix(rec("rpg_item_gem_02", 0.8), sy.bell(1320, 0.6)), 0.7)
    sy.write("ui_click", rec("rpg_lock_01", 0.6, 1.4), 0.5)
    sy.write("ui_open", rec("rpg_book_01", 0.7, 1.1), 0.5)
    print("layered sounds written to", sy.OUT)


if __name__ == "__main__":
    main()
