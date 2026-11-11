"""Builds the Lamplighter's sheets from the rig: every animation in all eight facings.

Two layers so the game can take the lantern away (Lantern Toss) and hang its light where the lantern really is:
  actors/lamplighter.png (+ _glow)          the man and his staff
  actors/lamplighter_lantern.png (+ _glow)  only the lantern's visible pixels, already hidden where he covers it
Rows are animation x facing (rig.DIRS order), up to 8 frames each. The anchors (lantern centre and its brightness) for every frame go to sprites.json with the animation data (lamplighter_anims.ANIMS)."""
from __future__ import annotations

import numpy as np
from PIL import Image

import lamplighter_anims as la
import lamplighter_body as lb
import rig

COLS = 8


def _frame(anim: str, d: str, i: int) -> tuple[Image.Image, Image.Image, Image.Image, Image.Image, list[float]]:
    p = la.pose(anim, i)
    full, anchors = lb.paint(p, rig.YAWS[d], lantern=True)
    body, _ = lb.paint(p, rig.YAWS[d], lantern=False)
    a, b = np.array(full.img), np.array(body.img)
    diff = np.any(a != b, axis=2) & (a[:, :, 3] > 0)
    lantern = np.zeros_like(a)
    lantern[diff] = a[diff]
    ga, gb = np.array(full.glow), np.array(body.glow)
    gdiff = np.any(ga != gb, axis=2)
    lglow = np.zeros_like(ga)
    lglow[gdiff] = ga[gdiff]
    lx, ly = anchors["lantern"]
    on = 1.0 if (p.lantern_on_staff or p.extra.get("lantern_screen") is not None) else 0.0
    anchor = [round(lx - rig.CX, 1), round(ly - rig.SOLE, 1), round(p.pane * on, 2)]
    return body.img, body.glow, Image.fromarray(lantern), Image.fromarray(lglow), anchor


def build(save, meta: dict) -> None:
    rows = [(anim, d) for anim in la.ANIMS for d in rig.DIRS]
    size = (COLS * rig.FRAME, len(rows) * rig.FRAME)
    sheets = [Image.new("RGBA", size, (0, 0, 0, 0)) for _ in range(4)]
    anchors: dict[str, list] = {anim: [] for anim in la.ANIMS}
    for r, (anim, d) in enumerate(rows):
        per_dir = []
        for i in range(la.ANIMS[anim]["frames"]):
            layers = _frame(anim, d, i)
            for sh, img in zip(sheets, layers[:4]):
                sh.paste(img, (i * rig.FRAME, r * rig.FRAME))
            per_dir.append(layers[4])
        anchors[anim].append(per_dir)
    save(sheets[0], sheets[1], "actors/lamplighter.png")
    save(sheets[2], sheets[3], "actors/lamplighter_lantern.png")
    anims = {}
    for k, (anim, spec) in enumerate(la.ANIMS.items()):
        n = spec["frames"]
        anims[anim] = {"row": k * len(rig.DIRS), "frames": n, "weights": spec.get("weights", [1.0] * n),
                       "fps": spec.get("fps", 12.0), "loop": spec.get("loop", False), "events": spec.get("events", {}),
                       "anchors": anchors[anim]}
    meta["lamplighter"] = {"frame": [rig.FRAME, rig.FRAME], "anchor": [rig.CX, rig.SOLE], "cols": COLS, "dirs": rig.DIRS,
                           "anims": anims, "poses": [[f"{a}_{d}", la.ANIMS[a]["frames"]] for a, d in rows]}
