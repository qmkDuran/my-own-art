"""Brightness and readability of the review stills, against game/data/readability.json: the mean luminance and the
share of near-black and near-white pixels of each still, and how strongly the creatures stand out (a still with
creatures against the same still without them). Prints READABILITY PASS or FAIL lines; exits 1 on a failure.
Run: python3 -I tools/readability.py STILLS_DIR"""
from __future__ import annotations

import json
import sys
from pathlib import Path

from PIL import Image, ImageChops

TARGETS = Path(__file__).resolve().parent.parent / "game" / "data" / "readability.json"
SAMPLE = (400, 225)


def luminance(path: Path) -> list[float]:
    image = Image.open(path).convert("L").resize(SAMPLE)
    return [value / 255.0 for value in image.tobytes()]


def still_problems(name: str, values: list[float], t: dict) -> list[str]:
    mean = sum(values) / len(values)
    black = sum(v < t["near_black"] for v in values) / len(values)
    white = sum(v > t["near_white"] for v in values) / len(values)
    print(f"READABILITY {name}: mean {mean:.3f}, near-black {black:.1%}, near-white {white:.1%}")
    out = []
    if not t["mean_min"] <= mean <= t["mean_max"]:
        out.append(f"{name}: mean luminance {mean:.3f} outside {t['mean_min']}..{t['mean_max']}")
    if black > t["near_black_share_max"]:
        out.append(f"{name}: {black:.1%} near-black (muddy)")
    if white > t["near_white_share_max"]:
        out.append(f"{name}: {white:.1%} near-white (blown out)")
    return out


def creature_problems(folder: Path, t: dict) -> list[str]:
    on, off = folder / "contrast_on.png", folder / "contrast_off.png"
    if not on.exists() or not off.exists():
        return ["creature contrast stills missing"]
    lum_on, lum_off = luminance(on), luminance(off)
    mask = [abs(a - b) > t["creature_diff"] for a, b in zip(lum_on, lum_off)]
    share = sum(mask) / len(mask)
    diffs = [abs(a - b) for a, b, keep in zip(lum_on, lum_off, mask) if keep]
    contrast = sum(diffs) / len(diffs) if diffs else 0.0
    print(f"READABILITY creatures: {share:.1%} of the frame, mean contrast against the background {contrast:.3f}")
    out = []
    if share < t["creature_share_min"]:
        out.append(f"creatures cover only {share:.1%} of the frame")
    if contrast < t["creature_contrast_min"]:
        out.append(f"creatures blend into the background (contrast {contrast:.3f})")
    return out


def main() -> None:
    folder = Path(sys.argv[1])
    t = json.loads(TARGETS.read_text())
    problems = []
    for name in t["stills"]:
        path = folder / f"{name}.png"
        if path.exists():
            problems += still_problems(name, luminance(path), t)
        else:
            problems.append(f"{name}: still missing")
    problems += creature_problems(folder, t)
    for p in problems:
        print("READABILITY FAIL", p)
    print("READABILITY PASS" if not problems else "READABILITY FAIL")
    sys.exit(1 if problems else 0)


if __name__ == "__main__":
    main()
