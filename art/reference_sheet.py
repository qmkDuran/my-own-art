"""A labelled review sheet of everything build_art.py made, at 3x, on the game's dusk ground colour, with each sprite's
emissive layer shown again over a black panel (what you see in the dark). Writes reference_sheet.png and
npc_lineup.png into the given directory."""
from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

from palette import PAL

ROOT = Path(__file__).resolve().parent.parent
ART = ROOT / "game" / "art"
FONT = ROOT / "game" / "fonts" / "PixelifySans.ttf"
BG = PAL["moss_dk"] + (255,)
SCALE = 3


def _font(size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(FONT), size)


def _first_frame(name: str, w: int, h: int) -> Image.Image:
    return Image.open(ART / name).convert("RGBA").crop((0, 0, w, h))


def _row(label: str, tiles: list[tuple[str, Image.Image]], width: int) -> Image.Image:
    h = max(t.height for _, t in tiles) * SCALE + 46
    out = Image.new("RGBA", (width, h), BG)
    d = ImageDraw.Draw(out)
    d.text((10, 6), label, font=_font(22), fill=PAL["gold"])
    x = 10
    for name, t in tiles:
        big = t.resize((t.width * SCALE, t.height * SCALE), Image.NEAREST)
        if x + big.width > width:
            break
        out.alpha_composite(big, (x, 34))
        d.text((x, 34 + big.height - 2), name, font=_font(14), fill=PAL["pale"])
        x += big.width + 14
    return out


def write(dest: Path) -> None:
    dest.mkdir(parents=True, exist_ok=True)
    meta = json.loads((ROOT / "game" / "data" / "sprites.json").read_text())["actors"]
    props = json.loads((ROOT / "game" / "data" / "props.json").read_text())
    width = 2200
    poses = [(f"{a} {d}", lamplighter_frame(meta, a, d, 1)) for a in ("idle", "walk", "bolt1", "bolt2", "cast", "dash")
             for d in ("s", "e", "n")]
    rows = [_row("The Lamplighter (8 facings, rig-drawn; a few of his animations)", poses, width)]
    npcs = [(m["name"].split(" ")[-1], _first_frame(f"actors/{k}.png", 64, 64)) for k, m in meta.items() if k.startswith("npc_")]
    npcs += [(k[5:], _first_frame(f"actors/{k}.png", 64, 64)) for k in meta if k.startswith("folk_")]
    rows.append(_row("People of Tallow and the Dusk", npcs, width))
    foes = []
    for k in ("gloam", "hound", "moth", "glazier"):
        w, h = meta[k]["frame"]
        foes += [(f"{k} idle", _first_frame(f"actors/{k}.png", w, h)),
                 (f"{k} attack", Image.open(ART / f"actors/{k}.png").convert("RGBA").crop((w, 2 * h, 2 * w, 3 * h)))]
    rows.append(_row("Enemies of the Glasswood (small 48 / medium 64 / mini-boss 128)", foes, width))
    big = [(k, _first_frame(f"props/{k}.png", *v["size"])) for k, v in props.items() if v["size"][1] >= 60]
    small = [(k, _first_frame(f"props/{k}.png", *v["size"])) for k, v in props.items() if v["size"][1] < 60]
    rows.append(_row("Props: trees, buildings, the wall", big[:9], width))
    rows.append(_row("Props: set-piece and edge details", small, width))
    icons = Image.open(ART / "ui/items.png").convert("RGBA")
    rows.append(_row("Item icons (24 px) and skill icons", [("items", icons), ("skills", Image.open(ART / "ui/skills.png").convert("RGBA")),
                                                            ("glyphs", Image.open(ART / "ui/glyphs.png").convert("RGBA"))], width))
    total = sum(r.height for r in rows)
    sheet = Image.new("RGBA", (width, total), BG)
    y = 0
    for r in rows:
        sheet.alpha_composite(r, (0, y))
        y += r.height
    sheet.save(dest / "reference_sheet.png")
    _lineup(dest, meta)


def lamplighter_frame(meta: dict, anim: str, d: str, i: int) -> Image.Image:
    """One frame of the Lamplighter, body and lantern layers together, cut to 64x64 around his feet."""
    m = meta["lamplighter"]
    fw = m["frame"][0]
    r = m["anims"][anim]["row"] + m["dirs"].index(d)
    box = (i * fw, r * fw, (i + 1) * fw, (r + 1) * fw)
    img = Image.open(ART / "actors/lamplighter.png").convert("RGBA").crop(box)
    img.alpha_composite(Image.open(ART / "actors/lamplighter_lantern.png").convert("RGBA").crop(box))
    cx, feet = m["anchor"]
    return img.crop((cx - 32, feet - 61, cx + 32, feet + 3))


def _lineup(dest: Path, meta: dict) -> None:
    """The NPC lineup at 4x with names and roles: the cast as the player meets them."""
    keys = ["lamplighter"] + [k for k in meta if k.startswith("npc_")]
    cell = 64 * 4
    img = Image.new("RGBA", (cell * len(keys) + 20, cell + 110), PAL["night"] + (255,))
    d = ImageDraw.Draw(img)
    for i, k in enumerate(keys):
        fr = (lamplighter_frame(meta, "idle", "s", 0) if k == "lamplighter" else _first_frame(f"actors/{k}.png", 64, 64))
        fr = fr.resize((cell, cell), Image.NEAREST)
        img.alpha_composite(fr, (10 + i * cell, 10))
        name = meta[k].get("name", "The Lamplighter")
        role = meta[k].get("role", "the Ninth of the order")
        d.text((14 + i * cell, cell + 20), name, font=_font(17), fill=PAL["gold"])
        d.text((14 + i * cell, cell + 48), role, font=_font(14), fill=PAL["pale"])
    img.save(dest / "npc_lineup.png")
