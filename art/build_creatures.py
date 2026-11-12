"""Builds the trainer prototype's sprites: every creature (normal and shiny) and the trainer, into game/art/creatures/,
plus game/data/tamer/creature_sprites.json (frame size, anchor, poses). With a directory argument it also writes a
4x review sheet there. Run: python3 -I art/build_creatures.py [review_dir]"""
from __future__ import annotations

import json
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))   # -I drops the script's folder from the path
import creatures  # noqa: E402
import people  # noqa: E402
import props_route  # noqa: E402
from pix import sheet  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "game" / "art" / "creatures"
TRAINER = {"name": "Trainer", "role": "", "head": "cap", "hat": ("sea_dk", "sea", "sea_lt"), "hair": "earth",
           "coat": ("leaf_dk", "leaf", "leaf_lt"), "scale": 0.8, "hem": 47, "hem_w": 10, "pack": "earth_lt",
           "legs": "earth_dk", "skin": "skin_lt", "scarf": ("amber", "flame"), "belt": "earth_dk",
           "rim_cool": "sea_lt", "rim_warm": "amber"}
RIVALS = {
    "rival_ivo": {"name": "Ivo", "role": "", "head": "cap", "hat": ("rust", "ember", "flame"), "hair": "ink",
                  "coat": ("night", "dusk2", "dusk3"), "scale": 0.8, "hem": 47, "hem_w": 10, "pack": "earth",
                  "legs": "ink", "skin": "skin", "scarf": ("glint", "glass_lt"), "belt": "ink", "rim_cool": "mist",
                  "rim_warm": "flame"},
    "rival_mara": {"name": "Mara", "role": "", "head": "hood", "hat": ("violet", "violet_lt", "pale"),
                   "coat": ("sea_dk", "sea", "sea_lt"), "scale": 0.8, "hem": 55, "hem_w": 11, "legs": "night",
                   "skin": "skin_lt", "scarf": ("gold", "amber"), "belt": "earth_dk", "rim_cool": "violet_lt",
                   "rim_warm": "gold", "split": False},
}
TRAINER_POSES = ("idle", "walk")
REVIEW_SCALE = 4


def _save(img: Image.Image, glow: Image.Image, name: str) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    img.save(OUT / f"{name}.png")
    glow_path = OUT / f"{name}_glow.png"
    if glow.getbbox() is not None:
        glow.save(glow_path)
    else:
        glow_path.unlink(missing_ok=True)


def build() -> dict:
    meta: dict = {"creatures": {}, "trainer": {}}
    for sid, (_, _, _, floats) in creatures.SPECIES.items():
        for shiny in (False, True):
            img, glow = sheet(creatures.frames(sid, shiny), creatures.W, creatures.H)
            _save(img, glow, sid + ("_shiny" if shiny else ""))
        meta["creatures"][sid] = {"frame": [creatures.W, creatures.H], "anchor": [creatures.W // 2, creatures.FEET],
                                  "poses": list(creatures.POSES.items()), "floats": floats}
    rows = [[people.draw(TRAINER, pose, i) for i in range(people.POSES[pose])] for pose in TRAINER_POSES]
    img, glow = sheet(rows, 64, 64)
    _save(img, glow, "trainer")
    meta["trainer"] = {"frame": [64, 64], "anchor": [32, people.FEET], "poses": [[p, people.POSES[p]] for p in TRAINER_POSES]}
    for key, spec in RIVALS.items():                          # rival trainers share the trainer's sheet layout
        rows = [[people.draw(spec, pose, i) for i in range(people.POSES[pose])] for pose in TRAINER_POSES]
        img, glow = sheet(rows, 64, 64)
        _save(img, glow, key)
    return meta


def build_route_props() -> None:
    """The prototype's route props (trees, tall grass), merged into game/data/props.json (build_art.py makes the
    same entries when it rebuilds everything)."""
    path = ROOT / "game" / "data" / "props.json"
    meta = json.loads(path.read_text())
    for key, spec in props_route.MANIFEST.items():
        frames = [m() for m in spec.get("frames", [spec.get("draw")])]
        img, glow = sheet([frames], frames[0].w, frames[0].h)
        img.save(ROOT / "game" / "art" / "props" / f"{key}.png")
        meta[key] = {"size": [frames[0].w, frames[0].h], "frames": len(frames), "foot": spec["foot"], "light": "",
                     "flat": False, "glow": False}
    path.write_text(json.dumps(meta, indent=1))


def review(out: Path) -> None:
    """Every creature's sheet (normal above shiny) and the trainer, at 4x on a mid ground tone."""
    sheets = [Image.open(OUT / f"{sid}{suf}.png") for sid in creatures.SPECIES for suf in ("", "_shiny")]
    sheets.append(Image.open(OUT / "trainer.png"))
    w = max(s.width for s in sheets)
    h = sum(s.height for s in sheets)
    board = Image.new("RGBA", (w, h), (74, 92, 70, 255))
    y = 0
    for s in sheets:
        board.alpha_composite(s, (0, y))
        y += s.height
    board = board.resize((w * REVIEW_SCALE, h * REVIEW_SCALE), Image.NEAREST)
    out.mkdir(parents=True, exist_ok=True)
    board.save(out / "creature_sheet.png")


def main() -> None:
    meta = build()
    build_route_props()
    path = ROOT / "game" / "data" / "tamer" / "creature_sprites.json"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(meta, indent=1))
    if len(sys.argv) > 1:
        review(Path(sys.argv[1]))
    print("creatures built:", len(meta["creatures"]), "species + trainer")


if __name__ == "__main__":
    main()
