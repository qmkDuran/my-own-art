"""Builds every game image from code into game/art/, plus game/data/palette.json.
Run: python3 -I art/build_art.py"""
from __future__ import annotations

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

from PIL import Image

import creatures_bloom
import creatures_cinder
import creatures_tide
import creatures_wild
import icons
import people
import props
import scenes
import tiles
from palette import PALETTE
from pix import Canvas

GAME = Path(__file__).resolve().parent.parent / "game"
OUT = GAME / "art"
SPRITE = 80
ICON = 24
CREATURES = {
    "mossfawn": creatures_bloom.mossfawn, "grovehart": creatures_bloom.grovehart,
    "thistlehog": creatures_bloom.thistlehog, "emberkit": creatures_cinder.emberkit,
    "hearthfox": creatures_cinder.hearthfox, "kindlemoth": creatures_cinder.kindlemoth,
    "ripplet": creatures_tide.ripplet, "rivermane": creatures_tide.rivermane,
    "drizzlesnail": creatures_tide.drizzlesnail, "cobblemole": creatures_wild.cobblemole,
    "puffwren": creatures_wild.puffwren,
}
WORLD_PROPS = {
    "tree": props.tree, "pine": props.pine, "bush": props.bush, "rock": props.rock, "sign": props.sign,
    "mailbox": props.mailbox, "wellspring": props.wellspring, "bramble": props.bramble, "stump": props.stump,
    "mushrooms": props.mushrooms, "shore_rocks": props.shore_rocks,
}
INDOOR_PROPS = {
    "wall": props.wall, "wall_window": props.wall_window, "bed": props.bed, "table": props.table,
    "shelf": props.shelf, "counter": props.counter, "plant": props.plant, "rug": props.rug, "basin": props.basin,
    "stove": props.stove, "mat": props.mat,
}
HOUSES = {"home": 1, "healer": 1, "shop": 2, "neighbor": 1}


def save(c: Canvas, rel: str, withered: bool = False) -> None:
    path = OUT / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    c.image().save(path)
    if withered:
        c.image(withered=True).save(path.with_name(path.stem + "_withered.png"))


def strip(cells: list[Canvas]) -> Canvas:
    out = Canvas(sum(c.w for c in cells), max(c.h for c in cells))
    x = 0
    for c in cells:
        out.paste(c, x, 0)
        x += c.w
    return out


def build_creatures() -> None:
    for name, draw in CREATURES.items():
        for view in ("front", "back"):
            c = Canvas(SPRITE, SPRITE)
            draw(c, view, 1.0)
            save(c.finish(), f"creatures/{name}_{view}.png")
        icon = Canvas(ICON, ICON)
        draw(icon, "front", ICON / SPRITE)
        save(icon.finish(), f"creatures/{name}_icon.png")


def build_world() -> None:
    save(strip([tiles.grass(v) for v in range(4)]), "tiles/grass.png", True)
    for kind in ("path", "water"):
        save(tiles.terrain(kind), f"tiles/{kind}.png", True)
    floor = Canvas(16, 16)
    tiles.TEXTURES["floor"](floor)
    save(floor, "tiles/floor.png")
    save(tiles.tall_grass(False), "tiles/tall_grass.png", True)
    save(tiles.tall_grass(True), "tiles/tall_grass_front.png", True)
    save(tiles.flower_bed(), "tiles/flowers.png", True)
    save(props.bridge(), "tiles/bridge.png", True)
    save(props.bridge_v(), "tiles/bridge_v.png", True)
    save(strip([props.fence(m) for m in range(16)]), "props/fence.png", True)
    for name, make in WORLD_PROPS.items():
        save(make(), f"props/{name}.png", True)
    for name, make in INDOOR_PROPS.items():
        save(make(), f"props/{name}.png")
    for kind, door in HOUSES.items():
        save(props.house(kind, door), f"props/house_{kind}.png")


def build_people() -> None:
    for name, (colours, style, skirt) in people.PEOPLE.items():
        path = OUT / f"people/{name}.png"
        path.parent.mkdir(parents=True, exist_ok=True)
        people.render_sheet(colours, style, skirt).save(path)


def build_ui() -> None:
    for k in ("bloom", "cinder", "tide", "gale", "stone"):
        save(icons.element(k), f"ui/elem_{k}.png")
    for k in ("wary", "playful", "hungry", "sleepy"):
        save(icons.mood(k), f"ui/mood_{k}.png")
    for k in ("sunberry", "smoky_nut", "sweet_kelp", "mending_salve", "spring_tonic"):
        save(icons.item(k), f"ui/item_{k}.png")
    save(icons.heart(True), "ui/heart_full.png")
    save(icons.heart(False), "ui/heart_empty.png")
    save(icons.cursor(), "ui/cursor.png")
    save(scenes.title(), "scenes/title.png")
    save(scenes.battle("meadow"), "scenes/battle_meadow.png")
    save(scenes.battle("grove"), "scenes/battle_grove.png", True)
    save(scenes.intro("hush"), "scenes/intro_hush.png")
    save(scenes.intro("shoot"), "scenes/intro_shoot.png")


def write_palette() -> None:
    (GAME / "data").mkdir(parents=True, exist_ok=True)
    (GAME / "data/palette.json").write_text(json.dumps(PALETTE, indent=1) + "\n")


if __name__ == "__main__":
    build_creatures()
    build_world()
    build_people()
    build_ui()
    write_palette()
    print("art built into", OUT)
