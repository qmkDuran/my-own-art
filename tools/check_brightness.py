"""Brightness check for the zone screenshots: in the play area (between the quest tracker and the skill bar),
the average luminance and the share of near-black pixels must sit in the Last Epoch-like mood band: readable
everywhere, darkness as an accent. UI-panel shots are skipped; Eclipse may be darker but never black.
Run: python3 -I tools/check_brightness.py SHOT_DIR   (exit 1 when a shot is outside the band)"""
from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

PLAY = (0.0, 0.11, 1.0, 0.86)                    # the play area as fractions of the frame (left, top, right, bottom)
NEAR_BLACK = 0.1
AVG_RANGE = (0.20, 0.33)            # aim for the middle: a rich dusk, not a bright day
BLACK_MAX = 0.25
NEAR_WHITE = 0.92
WHITE_MAX = 0.03                      # blown highlights: at most 3% of the play area near white
ECLIPSE_MIN = 0.10
PANELS = ("skill_tree", "passive", "inventory", "character", "loot_filter", "quest_log", "stash", "title",
          "eclipse_tree", "forge", "zone_overview")


def measure(path: Path) -> tuple[float, float, float]:
    img = Image.open(path).convert("RGB")
    w, h = img.size
    box = (int(PLAY[0] * w), int(PLAY[1] * h), int(PLAY[2] * w), int(PLAY[3] * h))
    a = np.asarray(img.crop(box), dtype=np.float32) / 255.0
    luma = a[:, :, 0] * 0.2126 + a[:, :, 1] * 0.7152 + a[:, :, 2] * 0.0722
    return float(luma.mean()), float((luma < NEAR_BLACK).mean()), float((luma > NEAR_WHITE).mean())


def main(folder: Path) -> int:
    bad = 0
    for path in sorted(folder.glob("*_1920x1080.png")):
        if any(k in path.name for k in PANELS):
            continue
        avg, black, white = measure(path)
        if path.name.startswith("eclipse"):
            ok = avg >= ECLIPSE_MIN
        elif path.name.startswith("noon"):                       # a breath of daylight: bright on purpose
            ok = black <= BLACK_MAX
        else:
            ok = AVG_RANGE[0] <= avg <= AVG_RANGE[1] and black <= BLACK_MAX
        blown = white > WHITE_MAX and not path.name.startswith("noon")
        ok = ok and not blown
        bad += 0 if ok else 1
        tag = "ok  " if ok else ("BLOWN" if blown else "DARK" if avg < AVG_RANGE[0] else "OUT ")
        print(f"{tag:5s} {path.name:44s} average {avg:5.1%}  near-black {black:5.1%}  near-white {white:5.1%}")
    print("BRIGHTNESS PASS" if bad == 0 else f"BRIGHTNESS FAIL ({bad} shots outside the band)")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(Path(sys.argv[1])))
