"""Builds every image the game uses from code (no external art): actor sheets with emissive layers, props, item and
skill icons, effect sprites, plus game/data/props.json and game/data/sprites.json (frame layouts and anchors).
Run: python3 -I art/build_art.py [review_dir]  — also writes a labelled reference sheet to review_dir if given."""
from __future__ import annotations

import json
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))   # -I drops the script's folder from the path
import enemies  # noqa: E402
import icons  # noqa: E402
import people  # noqa: E402
import props  # noqa: E402
import props_act1  # noqa: E402
import props_town  # noqa: E402
from pix import sheet  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
GAME = ROOT / "game"


def _save(img: Image.Image, glow: Image.Image | None, rel: str) -> None:
    path = GAME / "art" / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path)
    if glow is not None and glow.getbbox() is not None:
        glow.save(path.with_name(path.stem + "_glow.png"))


def build_people(meta: dict) -> None:
    rows = [[people.draw(people.LAMPLIGHTER, pose, i) for i in range(n)] for pose, n in people.POSES.items()]
    img, glow = sheet(rows, 64, 64)
    _save(img, glow, "actors/lamplighter.png")
    meta["lamplighter"] = {"frame": [64, 64], "anchor": [32, 61], "poses": list(people.POSES.items())}
    for key, spec in people.NPCS.items():
        img, glow = sheet([[people.draw(spec, "idle", i) for i in range(people.POSES["idle"])]], 64, 64)
        _save(img, glow, f"actors/npc_{key}.png")
        meta[f"npc_{key}"] = {"frame": [64, 64], "anchor": [32, 61], "poses": [["idle", people.POSES["idle"]]], "name": spec["name"],
                              "role": spec["role"]}


def build_townsfolk(meta: dict) -> None:
    """Passers-by in Tallow: idle and walk rows (they stroll between places)."""
    for key, spec in people.TOWNSFOLK.items():
        rows = [[people.draw(spec, pose, i) for i in range(people.POSES[pose])] for pose in ("idle", "walk")]
        img, glow = sheet(rows, 64, 64)
        _save(img, glow, f"actors/folk_{key}.png")
        meta[f"folk_{key}"] = {"frame": [64, 64], "anchor": [32, 61], "poses": [["idle", people.POSES["idle"]], ["walk", people.POSES["walk"]]]}


def build_enemies(meta: dict) -> None:
    for key, (fn, w, h) in enemies.KINDS.items():
        rows = [[fn(pose, i) for i in range(n)] for pose, n in enemies.POSES.items()]
        img, glow = sheet(rows, w, h)
        _save(img, glow, f"actors/{key}.png")
        meta[key] = {"frame": [w, h], "anchor": [w // 2, h - 4], "poses": list(enemies.POSES.items())}


def build_props() -> dict:
    out = {}
    for key, spec in {**props.MANIFEST, **props_act1.MANIFEST, **props_town.MANIFEST}.items():
        makers = spec.get("frames", [spec.get("draw")])
        frames = [m() for m in makers]
        img, glow = sheet([frames], frames[0].w, frames[0].h)
        _save(img, glow, f"props/{key}.png")
        out[key] = {"size": [frames[0].w, frames[0].h], "frames": len(frames), "foot": spec["foot"],
                    "light": spec.get("light", ""), "flat": spec.get("flat", False),
                    "glow": glow.getbbox() is not None}
    return out


def build_icons() -> dict:
    cols = max(n for _, n in icons.ITEM_DRAW.values()) * len(icons.VARIANT)
    atlas = Image.new("RGBA", (cols * 24, len(icons.ITEM_DRAW) * 24), (0, 0, 0, 0))
    for row, (base, (_, kinds)) in enumerate(icons.ITEM_DRAW.items()):
        for k in range(kinds):
            for v in range(len(icons.VARIANT)):
                atlas.alpha_composite(icons.item_icon(base, k, v).img, ((k * len(icons.VARIANT) + v) * 24, row * 24))
    _save(atlas, None, "ui/items.png")
    sk = [[icons._skill(n) for n in icons.SKILLS]]
    img, _ = sheet(sk, 24, 24)
    _save(img, None, "ui/skills.png")
    gl = [[icons._glyph(n) for n in icons.GLYPHS]]
    img, _ = sheet(gl, 16, 16)
    _save(img, None, "ui/glyphs.png")
    for name, frames in {"moth": [icons.fx_moth(0), icons.fx_moth(1)], "shard": [icons.fx_shard()],
                         "lantern": [icons.fx_lantern()], "spark": [icons.fx_spark()],
                         "crescent": [icons.fx_crescent()]}.items():
        img, _ = sheet([frames], frames[0].w, frames[0].h)
        _save(img, None, f"fx/{name}.png")
    return {"item_rows": list(icons.ITEM_DRAW.keys()), "item_kinds": {b: n for b, (_, n) in icons.ITEM_DRAW.items()},
            "variants": len(icons.VARIANT), "skills": icons.SKILLS, "glyphs": icons.GLYPHS}


def main() -> None:
    meta: dict = {}
    build_people(meta)
    build_townsfolk(meta)
    build_enemies(meta)
    prop_meta = build_props()
    icon_meta = build_icons()
    (GAME / "data" / "props.json").write_text(json.dumps(prop_meta, indent=1))
    (GAME / "data" / "sprites.json").write_text(json.dumps({"actors": meta, "icons": icon_meta}, indent=1))
    if len(sys.argv) > 1:
        import reference_sheet
        reference_sheet.write(Path(sys.argv[1]))
    print("art built:", len(meta), "actors,", len(prop_meta), "props")


if __name__ == "__main__":
    main()
