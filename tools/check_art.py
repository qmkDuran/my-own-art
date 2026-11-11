"""Art rules (see STYLE.md): every pixel in the one palette and fully opaque or clear; sizes per class
(creatures 80x80 with a 40-80 px body, icons 24x24, people 9 frames of 16x32 with a 22-26 px body, tiles and
props on the 16 px grid, backdrops 320x180). Run: python3 -I tools/check_art.py  (exit 1 on any problem)"""
from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "art"))

import numpy as np
from PIL import Image

from palette import allowed_rgb

ART = Path(__file__).resolve().parent.parent / "game" / "art"
ALLOWED = allowed_rgb()


def bbox_size(im: Image.Image) -> tuple[int, int]:
    box = im.getchannel("A").getbbox()
    return (0, 0) if box is None else (box[2] - box[0], box[3] - box[1])


def palette_problems(path: Path, im: Image.Image) -> list[str]:
    px = np.array(im)
    alpha = px[..., 3]
    if ((alpha != 0) & (alpha != 255)).any():
        return [f"{path.name}: semi-transparent pixels"]
    bad = {tuple(int(v) for v in rgb) for rgb in px[alpha == 255][:, :3]} - ALLOWED
    return [f"{path.name}: {len(bad)} colours outside the palette, e.g. {sorted(bad)[:3]}"] if bad else []


def size_problems(path: Path, im: Image.Image) -> list[str]:
    rel = path.relative_to(ART).as_posix()
    w, h = im.size
    if rel.startswith("creatures/") and rel.endswith(("_front.png", "_back.png")):
        bw, bh = bbox_size(im)
        if (w, h) != (80, 80) or not 40 <= max(bw, bh) <= 80:
            return [f"{rel}: creature sprite {w}x{h}, body {bw}x{bh} (want 80x80, body 40-80)"]
    if rel.endswith("_icon.png") and (w, h) != (24, 24):
        return [f"{rel}: icon {w}x{h} (want 24x24)"]
    if rel.startswith("people/"):
        if (w, h) != (144, 32):
            return [f"{rel}: sheet {w}x{h} (want 144x32)"]
        _, bh = bbox_size(im.crop((0, 0, 16, 32)))
        if not 22 <= bh <= 28:
            return [f"{rel}: body {bh} px tall (want 22-28)"]
    if rel.startswith(("tiles/", "props/")) and (w % 16 or h % 8):
        return [f"{rel}: {w}x{h} is off the 16 px grid"]
    if rel.startswith("scenes/") and (w, h) != (320, 180):
        return [f"{rel}: backdrop {w}x{h} (want 320x180)"]
    return []


def main() -> int:
    problems: list[str] = []
    files = sorted(ART.rglob("*.png"))
    for path in files:
        im = Image.open(path).convert("RGBA")
        problems += palette_problems(path, im) + size_problems(path, im)
    for p in problems:
        print("ART", p)
    print(f"ART {'PASS' if not problems else 'FAIL'}: {len(files)} images, {len(problems)} problems")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
