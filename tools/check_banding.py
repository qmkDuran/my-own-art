"""Banding check: light pools must fall off smoothly, with no visible contour rings. Along rays from the light's
centre (averaged over many angles to cancel texture and dither), the luminance may not jump between neighbouring
radii by more than a small step. Run on the title shot (a flat dark background around the lantern glow) and on
gameplay shots (the lantern pool around the Lamplighter).
Run: python3 -I tools/check_banding.py SHOT_DIR   (exit 1 when rings show)"""
from __future__ import annotations

import math
import sys
from pathlib import Path

import numpy as np
from PIL import Image

RAYS = 72
MAX_STEP = 0.01                        # luminance drop (0..1) between radii 2 px apart (rays averaged, 3-sample smoothing)
CENTRES = {"title": (0.5, 0.25, 40, 300)}               # (x, y, from r, to r) per shot, at 1920 wide
INNER = 0.25                           # the pool is checked from this share of its radius ...
OUTER = 0.85                           # ... to this one (inside the dashed radius ring)


def largest_drop(p: np.ndarray) -> float:
    """A ring is a sudden drop going outward; texture under the light wobbles both ways and is smoothed out."""
    if len(p) < 4:
        return 0.0
    smooth = np.convolve(p, np.ones(3) / 3.0, mode="valid")
    return float(max(0.0, -np.min(np.diff(smooth))))


def profile(img: np.ndarray, cx: float, cy: float, r0: int, r1: int) -> np.ndarray:
    h, w = img.shape
    out = []
    for r in range(r0, r1, 2):
        vals = []
        for k in range(RAYS):
            a = 2 * math.pi * k / RAYS
            x, y = int(cx + math.cos(a) * r), int(cy + math.sin(a) * r)
            if 0 <= x < w and 0 <= y < h:
                vals.append(img[y, x])
        out.append(np.median(vals) if vals else 0.0)
    return np.array(out)


def _luma(path: Path) -> np.ndarray:
    a = np.asarray(Image.open(path).convert("RGB"), dtype=np.float32) / 255.0
    return a[:, :, 0] * 0.2126 + a[:, :, 1] * 0.7152 + a[:, :, 2] * 0.0722


## The in-game lantern pool on open ground (the shot writes its centre and radius beside it).
def _pool(folder: Path) -> int:
    meta = folder / "lightpool.txt"
    shots = sorted(folder.glob("lightpool_*.png"))
    if not meta.exists() or not shots:
        return 0
    cx, cy, r, vw = (float(v) for v in meta.read_text().split())
    luma = _luma(shots[0])
    k = luma.shape[1] / vw
    p = profile(luma, cx * k, cy * k, int(r * k * INNER), int(r * k * OUTER))
    step = largest_drop(p)
    print(f"{'ok  ' if step <= MAX_STEP else 'RINGS'} {shots[0].name:40s} largest step along the radius {step:.4f}")
    return 0 if step <= MAX_STEP else 1


def main(folder: Path) -> int:
    bad = 0
    for name, (fx, fy, r0, r1) in CENTRES.items():
        for path in sorted(folder.glob(f"{name}_*.png")):
            a = np.asarray(Image.open(path).convert("RGB"), dtype=np.float32) / 255.0
            luma = a[:, :, 0] * 0.2126 + a[:, :, 1] * 0.7152 + a[:, :, 2] * 0.0722
            h, w = luma.shape
            scale = w / 1920.0
            p = profile(luma, w * fx, h * fy, int(r0 * scale), int(r1 * scale))
            step = largest_drop(p)
            ok = step <= MAX_STEP
            bad += 0 if ok else 1
            print(f"{'ok  ' if ok else 'RINGS'} {path.name:40s} largest step along the radius {step:.4f}")
    bad += _pool(folder)
    print("BANDING PASS" if bad == 0 else f"BANDING FAIL ({bad} shots)")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(Path(sys.argv[1])))
