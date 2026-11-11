"""The Lamplighter's animation sheets for review: one PNG per animation, eight facings by its frames, at 4x, body
and lantern layers together with the glow added, on the night colour. Run: python3 -I tools/anim_sheet.py OUT_DIR"""
from __future__ import annotations

import json
import sys
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
ART = ROOT / "game" / "art" / "actors"
ZOOM = 4
BG = (29, 27, 44, 255)


def frame(sheets: list[Image.Image], fw: int, row: int, i: int) -> Image.Image:
    box = (i * fw, row * fw, (i + 1) * fw, (row + 1) * fw)
    out = Image.new("RGBA", (fw, fw), BG)
    out.alpha_composite(sheets[0].crop(box))
    out.alpha_composite(sheets[1].crop(box))
    glow = Image.new("RGBA", (fw, fw), (0, 0, 0, 0))
    glow.alpha_composite(sheets[2].crop(box))
    glow.alpha_composite(sheets[3].crop(box))
    return ImageChops.add(out, Image.merge("RGBA", (*glow.convert("RGB").point(lambda v: v // 3).split(), Image.new("L", (fw, fw), 0))))


def main(out: Path) -> None:
    out.mkdir(parents=True, exist_ok=True)
    m = json.loads((ROOT / "game" / "data" / "sprites.json").read_text())["actors"]["lamplighter"]
    sheets = [Image.open(ART / f"{n}.png").convert("RGBA") for n in
              ("lamplighter", "lamplighter_lantern", "lamplighter_glow", "lamplighter_lantern_glow")]
    fw = m["frame"][0]
    for anim, a in m["anims"].items():
        n = a["frames"]
        img = Image.new("RGBA", (n * fw * ZOOM + 60, len(m["dirs"]) * fw * ZOOM + 30), BG)
        d = ImageDraw.Draw(img)
        d.text((8, 6), f"{anim}: {n} frames, weights {a['weights']}, events {a['events']}", fill=(255, 215, 122))
        for k, dname in enumerate(m["dirs"]):
            d.text((8, 30 + k * fw * ZOOM + fw * ZOOM // 2), dname.upper(), fill=(180, 178, 207))
            for i in range(n):
                f = frame(sheets, fw, a["row"] + k, i).resize((fw * ZOOM, fw * ZOOM), Image.NEAREST)
                img.paste(f, (60 + i * fw * ZOOM, 30 + k * fw * ZOOM))
        img.save(out / f"lamplighter_{anim}.png")
    print(f"wrote {len(m['anims'])} sheets to {out}")


if __name__ == "__main__":
    main(Path(sys.argv[1]))
