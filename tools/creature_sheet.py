"""A reference sheet of every creature: front and back battle sprites, party icon, name and element.
Run: python3 -I tools/creature_sheet.py OUT.png [scale]"""
from __future__ import annotations

import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent / "game"
CELL_W, CELL_H = 196, 104


def main(out: str, scale: int) -> None:
    species = json.loads((ROOT / "data/creatures.json").read_text())
    palette = json.loads((ROOT / "data/palette.json").read_text())
    cols = 3
    rows = (len(species) + cols - 1) // cols
    sheet = Image.new("RGBA", (cols * CELL_W + 8, rows * CELL_H + 8), palette["ink2"])
    draw = ImageDraw.Draw(sheet)
    draw.fontmode = "1"
    font = ImageFont.truetype(str(ROOT / "fonts/PixelifySans.ttf"), 11)
    for i, (sid, data) in enumerate(species.items()):
        x, y = 4 + (i % cols) * CELL_W, 4 + (i // cols) * CELL_H
        draw.rounded_rectangle((x + 2, y + 2, x + CELL_W - 2, y + CELL_H - 2), 3, fill=palette["paper"], outline=palette["ink"])
        for k, view in enumerate(("front", "back")):
            sprite = Image.open(ROOT / f"art/creatures/{sid}_{view}.png")
            sheet.alpha_composite(sprite, (x + 6 + k * 84, y + 18))
        sheet.alpha_composite(Image.open(ROOT / f"art/creatures/{sid}_icon.png"), (x + CELL_W - 30, y + 4))
        elem = Image.open(ROOT / f"art/ui/elem_{data['element']}.png")
        sheet.alpha_composite(elem, (x + 7, y + 6))
        draw.text((x + 20, y + 3), f"{data['name']}  ({data['element'].title()})", font=font, fill=palette["ink"])
    sheet.resize((sheet.width * scale, sheet.height * scale), Image.NEAREST).save(out)


if __name__ == "__main__":
    main(sys.argv[1], int(sys.argv[2]) if len(sys.argv) > 2 else 2)
