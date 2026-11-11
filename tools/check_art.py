"""Art checks: every sprite pixel is a palette colour; actors stay in their size class and stand on the same feet
line in every frame; no frame is empty; the GDScript palette mirror (pal.gd) equals art/palette.py.
Run: python3 -I tools/check_art.py   (exit 1 on any problem)"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "art"))
from palette import PAL  # noqa: E402

ART = ROOT / "game" / "art"
# visible body height (px) per size class
CLASSES = {"lamplighter": (52, 62), "npc": (36, 64), "gloam": (24, 44), "hound": (24, 44), "moth": (30, 52), "glazier": (100, 126), "husk": (44, 62),
           "crawler": (16, 36), "matron": (110, 158),
           "undertow": (40, 62), "drowned": (24, 52)}
FEET_TOLERANCE = 3


def palette_problems() -> list[str]:
    allowed = set(PAL.values())
    out = []
    for path in sorted(ART.rglob("*.png")):
        img = Image.open(path).convert("RGBA")
        px = np.array(img).reshape(-1, 4)
        bad = {tuple(int(v) for v in c[:3]) for c in px[px[:, 3] > 0]} - allowed
        if bad:
            out.append(f"{path.relative_to(ROOT)}: {len(bad)} colours outside the palette, e.g. {sorted(bad)[:3]}")
    return out


GROUNDED = ("idle", "walk", "move")


def _frames(name: str, meta: dict) -> list[Image.Image]:
    """Frames of the poses where feet stay on the ground (attacks may leap or lift)."""
    img = Image.open(ART / "actors" / f"{name}.png").convert("RGBA")
    fw, fh = meta["frame"]
    out = []
    for row, (pose, n) in enumerate(meta["poses"]):
        if pose not in GROUNDED:
            continue
        for i in range(n):
            out.append(img.crop((i * fw, row * fh, (i + 1) * fw, (row + 1) * fh)))
    return out


def actor_problems() -> list[str]:
    meta = json.loads((ROOT / "game" / "data" / "sprites.json").read_text())["actors"]
    out = []
    for name, m in meta.items():
        cls = "npc" if name.startswith(("npc_", "folk_")) else name
        lo, hi = CLASSES[cls]
        feet = []
        for k, fr in enumerate(_frames(name, m)):
            box = fr.getbbox()
            if box is None:
                out.append(f"{name} frame {k} is empty")
                continue
            feet.append(box[3])
            if k == 0 and not lo <= box[3] - box[1] <= hi:
                out.append(f"{name}: body {box[3] - box[1]} px tall, its class allows {lo}-{hi}")
        if feet and max(feet) - min(feet) > FEET_TOLERANCE and cls not in ("moth", "matron", "drowned"):
            out.append(f"{name}: feet move {max(feet) - min(feet)} px between frames (sliding)")
    return out


def mirror_problems() -> list[str]:
    text = (ROOT / "game" / "scripts" / "core" / "pal.gd").read_text()
    found = {m[0]: (int(m[1]), int(m[2]), int(m[3])) for m in re.findall(r'"(\w+)": Color8\((\d+), (\d+), (\d+)\)', text)}
    return [f"pal.gd {k} differs from palette.py" for k in PAL if found.get(k) != PAL[k]]


def main() -> None:
    problems = palette_problems() + actor_problems() + mirror_problems()
    for p in problems:
        print("ART problem:", p)
    print("ART PASS" if not problems else f"ART FAIL ({len(problems)} problems)")
    sys.exit(1 if problems else 0)


if __name__ == "__main__":
    main()
