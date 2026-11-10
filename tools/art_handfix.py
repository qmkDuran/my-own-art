"""Hand fixes for the delivered Chapter 1 art (no generation, no API calls).

Reads the delivered originals from git (ORIGINAL_COMMIT) so it can be re-run safely, writes the
fixed PNGs in place under art/, and prints the new geometry of the rescaled buildings and cars
(the numbers that live in data/art.json as "footprint" / "door").

    python3 tools/art_handfix.py            # needs numpy, Pillow, scipy

What it does
- Buildings: shrinks by removing the least visible whole rows/columns (rows of siding or roof
  that repeat their neighbour), so outlines and details stay crisp. The roof band is compressed
  more than the door band, which keeps a door about one character tall. Day/night variants use
  the same removal masks so they stay pixel-aligned.
- Cars: 2:1 majority-vote reduction + re-outline (a car is now ~1.5-1.9x a character long).
- Bins/mailbox: row/column removal to real-world size next to a 58 px character.
- FX: fire, fire_medium, fire_small redrawn procedurally as swaying, tapering flame tongues
  (looping, palette colours only), replacing the round "blob" fire.
- Store floor: 6 vinyl-tile variants with uneven grout, a yellowed or replaced tile here and
  there, heel scuffs; plus a large wear decal (traffic paths) so the floor stops reading as a grid.
- Characters: female hero side-run ponytail leftovers removed and the dark-red sleeve recoloured
  to the jacket shadow; stray ponytail pixels removed from the bob hair; chair-leg outline
  leftovers removed from Mom's sit row; dog walk/run (down) frames resized to the idle size.
  Engine sheets (4x3, 64 px) are regenerated from the fixed full sheets.
- New props drawn by hand: couch_back (sofa seen from behind), mop_bucket_empty.
"""
from __future__ import annotations

import io
import json
import math
import subprocess
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

sys.path.insert(0, str(Path(__file__).resolve().parent))
from pixel_ops import (OUTLINE, ROOT, reduce_2to1, remove_stray_outline, rescale_pixel_art,  # noqa: E402
                       reoutline, save, shrink_lines, shrink_mask)

ORIGINAL_COMMIT = "1c9c6c3"


def original(rel: str) -> np.ndarray:
    data = subprocess.run(["git", "show", f"{ORIGINAL_COMMIT}:{rel}"], cwd=ROOT, capture_output=True, check=True).stdout
    return np.array(Image.open(io.BytesIO(data)).convert("RGBA"))


def hexc(h: str) -> tuple:
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def banded_row_keep(arr: np.ndarray, cuts: list[int], factors: list[float]) -> np.ndarray:
    keep = np.zeros(arr.shape[0], dtype=bool)
    prev = 0
    for c, f in zip(cuts + [arr.shape[0]], factors):
        seg = arr[prev:c]
        keep[prev:c] = shrink_mask(seg, round(seg.shape[0] * f), 0)
        prev = c
    return keep


def remap(v: float, keep: np.ndarray) -> int:
    v = int(round(v))
    return int(keep[:max(0, min(v, len(keep)))].sum())


GEOMETRY: dict = {}


def building(names: list[str], cuts, factors, width_factor, solid, door, walk_rects=()):
    base = original(f"art/exterior/buildings/{names[0]}.png")
    rows = banded_row_keep(base, cuts, factors) if factors else np.ones(base.shape[0], bool)
    cols = shrink_mask(base[rows], round(base.shape[1] * width_factor), 1)
    for name in names:
        arr = original(f"art/exterior/buildings/{name}.png")
        out = arr[rows][:, cols]
        save(out, ROOT / f"art/exterior/buildings/{name}.png")
    h, w = int(rows.sum()), int(cols.sum())
    x, y, rw, rh = solid
    fx0, fy0 = remap(x, cols), remap(y, rows)
    fx1, fy1 = remap(x + rw, cols), remap(y + rh, rows)
    GEOMETRY[names[0]] = {
        "size": [w, h],
        "footprint": [fx0, fy0, fx1 - fx0, fy1 - fy0],
        "door": [remap(door[0], cols), remap(door[1], rows)],
        "extra": [[remap(a, cols), remap(b, rows), remap(a + c, cols) - remap(a, cols), remap(b + d, rows) - remap(b, rows)]
                  for a, b, c, d in walk_rects],
    }


def buildings() -> None:
    # Hale / Dunmore colonial: roof + upper storey (rows < 372) x0.72, door band x0.9, base x0.85; width x0.8.
    building(["house_hale", "house_hale_night"], [372, 452], [0.72, 0.9, 0.85], 0.8,
             [0, 330, 412, 170], (207, 445), [(154, 500, 104, 26)])
    building(["house_dunmore", "house_dunmore_night"], [372, 452], [0.72, 0.9, 0.85], 0.8,
             [0, 330, 412, 170], (205, 445), [(154, 500, 104, 26)])
    # Okoro ranch: door is already about a character tall; only trim width (siding runs).
    building(["house_okoro"], [], [], 0.85, [0, 100, 406, 90], (130, 174), [(100, 176, 60, 30), (300, 140, 75, 50)])
    # Store: door was ~77 px; x0.8 both ways.
    building(["store_ridge_mart", "store_ridge_mart_dark"], [255], [0.8, 1.0], 0.8,
             [0, 150, 303, 105], (151, 239), [(0, 255, 303, 14)])


def cars() -> None:
    for name in ["car_silver", "car_teal", "suv_red", "car_wreck", "car_wreck_burned"]:
        out = reoutline(reduce_2to1(original(f"art/exterior/props/{name}.png")))
        # drop specks (generation dust) that are not part of the car body
        lab, n = ndimage.label(out[..., 3] > 0, structure=np.ones((3, 3)))
        if n > 1:
            sizes = ndimage.sum(np.ones_like(lab), lab, range(1, n + 1))
            for i, size in enumerate(sizes, 1):
                if size < 12:
                    out[lab == i] = 0
        ys, xs = np.nonzero(out[..., 3])
        out = out[: ys.max() + 1, xs.min(): xs.max() + 1]
        save(out, ROOT / f"art/exterior/props/{name}.png")
        GEOMETRY[name] = {"size": [out.shape[1], out.shape[0]]}


def small_props() -> None:
    for name, f in [("trash_can", 0.72), ("recycling_bin", 0.78), ("mailbox", 0.85)]:
        arr = original(f"art/exterior/props/{name}.png")
        out = shrink_lines(shrink_lines(arr, round(arr.shape[0] * f), 0), round(arr.shape[1] * f), 1)
        save(out, ROOT / f"art/exterior/props/{name}.png")
        GEOMETRY[name] = {"size": [out.shape[1], out.shape[0]]}


# --- Fire ---------------------------------------------------------------------------------

FIRE_RAMP = [hexc(h) for h in ["ae2334", "e83b3b", "fb6b1d", "f79617", "f9c22b", "fbff86"]]
FIRE_RIM = hexc("6e2727")


def flame_strip(fw: int, fh: int, base_y: int, frames: int, tongues: list[dict], sparks: int, seed: int) -> np.ndarray:
    rng = np.random.default_rng(seed)
    sheet = np.zeros((fh, fw * frames, 4), dtype=np.uint8)
    yy, xx = np.mgrid[0:fh, 0:fw].astype(np.float64)
    spark_paths = [(rng.uniform(0.25, 0.75) * fw, rng.uniform(0, 1), rng.uniform(-1.5, 1.5)) for _ in range(sparks)]
    for k in range(frames):
        t = 2 * math.pi * k / frames
        field = np.zeros((fh, fw))
        for tg in tongues:
            height = tg["h"] * (1 + tg["amp"] * math.sin(tg["m"] * t + tg["ph"]))
            r = (base_y - yy) / max(height, 1)
            inside = (r >= -0.08) & (r <= 1)
            rc = np.clip(r, 0, 1)
            xc = tg["x"] + tg["sway"] * np.sin(t * tg["m2"] + tg["ph2"] + rc * 2.6) * rc ** 1.4
            width = tg["w"] * (1 - rc) ** 0.75 * (1 + 0.12 * math.sin(t * 2 + tg["ph"]))
            val = 1 - np.abs(xx - xc) / np.maximum(width, 0.01)
            heat = np.where(inside & (val > 0), np.sqrt(np.clip(val, 0, 1)) * (0.95 - 0.5 * rc) + 0.12 * (1 - rc), 0)
            field = 1 - (1 - field) * (1 - np.clip(heat, 0, 1))
            # a detached lick above the tip on part of the cycle: flicker
            lick = math.sin(tg["m"] * t + tg["ph"] + 1.2)
            if lick > 0.35 and tg.get("licks", True):
                ly = base_y - height - 2 - 3 * lick
                lx = tg["x"] + tg["sway"] * math.sin(t * tg["m2"] + tg["ph2"] + 2.6)
                lw, lh = max(0.8, tg["w"] * 0.16), max(1.5, tg["h"] * 0.09)
                d = ((xx - lx) / lw) ** 2 + ((yy - ly) / lh) ** 2
                field = np.maximum(field, np.where(d < 1, 0.5 * (1 - d) + 0.1, 0))
        frame = np.zeros((fh, fw, 4), dtype=np.uint8)
        bands = [0.08, 0.3, 0.52, 0.7, 0.86, 0.96]
        for i, thr in enumerate(bands):
            m = field > thr
            frame[m] = (*FIRE_RAMP[i], 255)
        filled = field > bands[0]
        pad = np.pad(filled, 1)
        edge = filled & ~(pad[:-2, 1:-1] & pad[2:, 1:-1] & pad[1:-1, :-2] & pad[1:-1, 2:])
        # dark rim only on the lower/outer sides keeps the silhouette readable on any ground
        rim = edge & (yy > base_y - 0.55 * fh)
        frame[rim] = (*FIRE_RIM, 255)
        for sx, sp, drift in spark_paths:
            ph = (k / frames + sp) % 1.0
            py = int(base_y - 0.35 * fh - ph * 0.6 * fh)
            px = int(sx + drift * ph * 6 + 1.5 * math.sin(ph * 9))
            if 0 <= px < fw and 0 <= py < fh and frame[py, px, 3] == 0:
                frame[py, px] = (*FIRE_RAMP[4 if ph < 0.6 else 2], 255)
        sheet[:, k * fw:(k + 1) * fw] = frame
    return sheet


def tongues_for(fw: int, height: float, count: int, rng: np.random.Generator, spread: float) -> list[dict]:
    out = []
    for i in range(count):
        centre = (i - (count - 1) / 2) / max(count - 1, 1)
        tall = 1 - 0.55 * abs(centre)
        out.append({
            "x": fw / 2 + centre * spread * fw + rng.uniform(-1, 1),
            "h": height * tall * rng.uniform(0.85, 1.05),
            "w": fw * rng.uniform(0.13, 0.18) * (1.3 if abs(centre) < 0.3 else 1.0),
            "amp": rng.uniform(0.10, 0.2), "m": int(rng.integers(1, 3)), "ph": rng.uniform(0, 6.28),
            "sway": rng.uniform(3.0, 5.0) * fw / 48, "m2": int(rng.integers(1, 3)), "ph2": rng.uniform(0, 6.28),
        })
    return out


def fire() -> None:
    rng = np.random.default_rng(7)
    specs = [("fire", 48, 64, 54, 46, 6, 0.62, 5), ("fire_medium", 36, 52, 51, 40, 5, 0.56, 3), ("fire_small", 20, 28, 27, 21, 3, 0.5, 1)]
    for name, fw, fh, base, height, count, spread, sparks in specs:
        sheet = flame_strip(fw, fh, base, 8, tongues_for(fw, height, count, rng, spread), sparks, int(rng.integers(1000)))
        save(sheet, ROOT / f"art/fx/{name}.png")


# --- Store floor --------------------------------------------------------------------------------

def store_floor() -> None:
    base, grout, light, yellowed, scuff = hexc("c7dcd0"), hexc("9babb2"), hexc("ffffff"), hexc("b2ba90"), hexc("7f708a")
    rng = np.random.default_rng(11)

    def stroke(t, cx, cy, length, ang, colour, curve=0.25):
        for s_ in range(length):
            a = ang + curve * s_ / max(length, 1)
            x, y = int(round(cx + math.cos(a) * s_)), int(round(cy + math.sin(a) * s_))
            if 0 <= x < t.shape[1] and 0 <= y < t.shape[0]:
                t[y, x] = (*colour, 255)

    variants = []
    for v in range(8):
        t = np.zeros((32, 32, 4), dtype=np.uint8)
        t[...] = (*base, 255)
        # one 12" vinyl square per tile; the seam is a dotted, partly worn line, and on some
        # tiles one seam is filled flush, so the grid breaks up instead of a hard 1 px lattice
        top_seam, left_seam = v not in (3, 6), v not in (1, 4)
        for i in range(32):
            if top_seam and (i % 2 == 0 or rng.random() < 0.25) and rng.random() > 0.15:
                t[0, i, :3] = grout
            if left_seam and (i % 2 == 1 or rng.random() < 0.25) and rng.random() > 0.15:
                t[i, 0, :3] = grout
        if v != 7:      # 7 = a newer replacement square: clean, no fleck
            for _ in range(int(rng.integers(4, 9))):
                t[rng.integers(2, 31), rng.integers(2, 31), :3] = grout if rng.random() < 0.75 else light
        if v in (5, 6):  # soft grime patch (dithered, irregular) where the mop never quite reaches
            yy, xx = np.mgrid[0:32, 0:32]
            cx, cy = rng.uniform(8, 24), rng.uniform(8, 24)
            r = 7 + 3 * np.sin(np.arctan2(yy - cy, xx - cx) * 3 + rng.uniform(0, 6))
            blob = (np.hypot(xx - cx, yy - cy) < r) & ((xx + yy) % 2 == 0) & (rng.random((32, 32)) < 0.6)
            t[blob, :3] = yellowed if v == 6 else grout
        variants.append(t)
    for i, t in enumerate(variants):
        save(t, ROOT / f"art/interior/tiles/floor_store_{i}.png")
    save(variants[0], ROOT / "art/interior/tiles/floor_store.png")
    save(variants[5], ROOT / "art/interior/tiles/floor_store_scuffed.png")

    # Wear decal (store floor area, 640x384): scuff strokes along the traffic paths
    # (door -> counter, door -> aisles -> coolers) and grime where floor meets the walls.
    W, H = 640, 384
    wear = np.zeros((H, W, 4), dtype=np.uint8)
    paths = [[(304, 380), (300, 300), (190, 285), (130, 300)], [(304, 380), (318, 230), (330, 110), (440, 40)],
             [(304, 330), (470, 230), (520, 110)], [(140, 300), (120, 120), (90, 40)]]
    for path in paths:
        for (x0, y0), (x1, y1) in zip(path, path[1:]):
            seg = math.hypot(x1 - x0, y1 - y0)
            ang = math.atan2(y1 - y0, x1 - x0)
            for _ in range(int(seg / 6)):
                s_ = rng.random()
                px = x0 + (x1 - x0) * s_ + rng.normal(0, 13)
                py = y0 + (y1 - y0) * s_ + rng.normal(0, 9)
                colour = scuff if rng.random() < 0.35 else grout
                stroke(wear, px, py, int(rng.integers(3, 8)), ang + rng.normal(0, 0.5), colour, rng.uniform(-0.6, 0.6))
    yy, xx = np.mgrid[0:H, 0:W]
    edge = (np.minimum(np.minimum(xx, W - 1 - xx), yy) < 4) & (rng.random((H, W)) < 0.25)
    wear[edge] = (*grout, 255)
    save(wear, ROOT / "art/interior/props/store_floor_wear.png")


# --- Characters ---------------------------------------------------------------------------------

def is_colour(a: np.ndarray, c: tuple) -> np.ndarray:
    return (a[..., 0] == c[0]) & (a[..., 1] == c[1]) & (a[..., 2] == c[2]) & (a[..., 3] > 0)


def fix_edges_after_erase(frame: np.ndarray, erased: np.ndarray) -> None:
    """Pixels that now border the erased area become outline (silhouette stays closed)."""
    opaque = frame[..., 3] > 0
    grown = ndimage.binary_dilation(erased, structure=np.array([[0, 1, 0], [1, 1, 1], [0, 1, 0]]))
    frame[grown & opaque & ~erased, :3] = OUTLINE


def female_body() -> None:
    rel = "art/characters/full/hero_female_body_full.png"
    sheet = original(rel)
    reds = [(179, 56, 49), (158, 69, 57), (110, 39, 39)]
    skin = [(180, 130, 101), (140, 101, 78)]
    for row in (6, 7, 8):
        for col in range(9):
            fr = sheet[row * 80:(row + 1) * 80, col * 80:(col + 1) * 80]
            if not fr[..., 3].any():
                continue
            red = np.zeros(fr.shape[:2], bool)
            for c in reds:
                red |= is_colour(fr, c)
            sk = np.zeros_like(red)
            for c in skin:
                sk |= is_colour(fr, c)
            if row == 8 and sk.any():
                ys, xs = np.nonzero(sk)
                top = ys.min()
                head_x = xs[ys < top + 20].mean()
                lab, n = ndimage.label(red)
                for i in range(1, n + 1):
                    comp = lab == i
                    cy, cx = np.nonzero(comp)
                    dx, dy = cx.mean() - head_x, cy.mean() - (top + 20)
                    if dx < -6 and -6 < dy < 8:   # the lump behind the neck = old ponytail
                        fr[comp] = 0
                        fix_edges_after_erase(fr, comp)
            # dark-red sleeve -> jacket shadow orange so the far arm reads as the same jacket
            m179, m158, m110 = is_colour(fr, (179, 56, 49)), is_colour(fr, (158, 69, 57)), is_colour(fr, (110, 39, 39))
            fr[m179, :3] = (205, 104, 61)
            if row in (7, 8):
                fr[m158, :3] = (205, 104, 61)
                fr[m110, :3] = (158, 69, 57)
    sheet = remove_stray_outline(sheet, 3)
    save(sheet, ROOT / rel)


def hair_bob() -> None:
    rel = "art/characters/full/hair_bob_full.png"
    sheet = original(rel)
    stray = is_colour(sheet, (110, 39, 39)) | is_colour(sheet, (22, 90, 76))
    sheet[stray] = 0
    sheet = remove_stray_outline(sheet, 4)
    save(sheet, ROOT / rel)


def mom_sit() -> None:
    rel = "art/characters/full/mom_full.png"
    sheet = original(rel)
    row = 7
    strip = sheet[row * 80:(row + 1) * 80].copy()
    for col in range(8):
        fr = strip[:, col * 80:(col + 1) * 80]
        if not fr[..., 3].any():
            continue
        # chair legs: thin outline-only lines in the lower part, behind/below the seat
        cleaned = remove_stray_outline(fr, 8)
        # also drop small detached bits (a leg foot) not connected to the body
        lab, n = ndimage.label(cleaned[..., 3] > 0, structure=np.ones((3, 3)))
        if n > 1:
            sizes = ndimage.sum(np.ones_like(lab), lab, range(1, n + 1))
            biggest = 1 + int(np.argmax(sizes))
            cleaned[(lab != biggest) & (lab > 0)] = 0
        strip[:, col * 80:(col + 1) * 80] = cleaned
    sheet[row * 80:(row + 1) * 80] = strip
    save(sheet, ROOT / rel)


def dog() -> None:
    rel = "art/characters/full/dog_full.png"
    sheet = original(rel)
    idle = sheet[0:80, 0:80]
    ys, _ = np.nonzero(idle[..., 3])
    target_h = ys.max() - ys.min() + 1
    for row in (3, 6):   # walk down, run down are drawn ~20% smaller than idle down
        for col in range(9):
            fr = sheet[row * 80:(row + 1) * 80, col * 80:(col + 1) * 80]
            if not fr[..., 3].any():
                continue
            ys, xs = np.nonzero(fr[..., 3])
            y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
            factor = min(1.35, target_h / (y1 - y0)) if row == 3 else min(1.3, (target_h - 2) / (y1 - y0))
            if factor <= 1.02:
                continue
            big = rescale_pixel_art(fr[y0:y1, x0:x1], factor)
            nh, nw = big.shape[:2]
            cx = (x0 + x1) // 2
            new = np.zeros_like(fr)
            top, left = y1 - nh, cx - nw // 2
            new[max(0, top):y1, max(0, left):left + nw] = big[max(0, -top):, max(0, -left):]
            fr[...] = new
    save(sheet, ROOT / rel)


def engine_sheets() -> None:
    """Rebuild the 4x3 engine sheets (64 px, rows down/up/side) from the fixed full sheets."""
    for cid, layout in [("hero_female_body", "hero_female_body"), ("hair_bob", "hero_female_body"), ("mom", "mom"), ("dog", "dog")]:
        full = np.array(Image.open(ROOT / f"art/characters/full/{cid}_full.png").convert("RGBA"))
        lay = json.loads((ROOT / f"art/characters/full/{layout}_full.json").read_text())
        rows = {(r["anim"], r["dir"]): r["row"] for r in lay["rows"]}
        out = np.zeros((192, 256, 4), dtype=np.uint8)
        for ri, d in enumerate(["down", "up", "side"]):
            src = rows[("walk", d)]
            for c in range(4):
                col = c * 2
                out[ri * 64:(ri + 1) * 64, c * 64:(c + 1) * 64] = full[src * 80 + 16:src * 80 + 80, col * 80 + 8:col * 80 + 72]
        save(out, ROOT / f"art/characters/{cid}.png")


# --- New hand-drawn props ---------------------------------------------------------------------

def couch_back() -> None:
    """The dusty-rose sofa seen from behind (it faces the TV), painted with couch.png's own colours."""
    W, H = 73, 33
    rail, panel, shade, deep = hexc("cf657f"), hexc("a24b6f"), hexc("753c54"), hexc("45293f")
    pillow, pillow_dark = hexc("ab947a"), hexc("966c6c")
    img = np.zeros((H, W, 4), dtype=np.uint8)
    yy, xx = np.mgrid[0:H, 0:W]
    body = (xx >= 1) & (xx <= W - 2) & (yy >= 5) & (yy <= H - 5)
    # rounded top corners
    body &= ~(((xx < 4) | (xx > W - 5)) & (yy < 7))
    img[body] = (*panel, 255)
    img[body & (yy <= 8)] = (*rail, 255)                     # top rail catches the light
    img[body & (yy == 9)] = (*shade, 255)
    img[body & (xx >= W - 8) & (yy > 9)] = (*shade, 255)     # right end in shade
    img[body & (yy >= H - 7)] = (*shade, 255)                # lower skirt
    for sx in (W // 3, 2 * W // 3):                          # seams between the back cushions
        img[(xx == sx) & (yy > 10) & (yy < H - 7)] = (*shade, 255)
    # throw pillows peeking over the back
    for cx in (16, 54):
        bump = ((xx - cx) / 8.0) ** 2 + ((yy - 5) / 4.0) ** 2 < 1
        img[bump & (yy < 6)] = (*pillow, 255)
        img[bump & (yy < 6) & (xx > cx + 3)] = (*pillow_dark, 255)
    img[(yy >= H - 4) & (yy < H - 1) & np.isin(xx, [4, 5, W - 6, W - 5])] = (*deep, 255)   # legs
    img = reoutline(img)
    save(img, ROOT / "art/interior/props/couch_back.png")


def delivery_van() -> None:
    """Self-driving delivery van: the (reduced) SUV body repainted fleet white. No driver seat
    shows through the dark glass, which is the point of the scene."""
    arr = np.array(Image.open(ROOT / "art/exterior/props/suv_red.png").convert("RGBA"))
    ramp = {"e83b3b": "ffffff", "ea4f36": "ffffff", "f57d4a": "ffffff", "b33831": "c7dcd0", "ae2334": "c7dcd0",
            "c32454": "9babb2", "9e4539": "7f708a", "6e2727": "7f708a", "7a3045": "625565", "831c5d": "625565"}
    masks = {src: is_colour(arr, hexc(src)) for src in ramp}
    for src, dst in ramp.items():
        arr[masks[src], :3] = hexc(dst)
    save(arr, ROOT / "art/exterior/props/van.png")


def mop_bucket_empty() -> None:
    arr = original("art/interior/props/mop_bucket.png")
    erase = np.zeros(arr.shape[:2], bool)
    erase[:23, :10] = True          # the mop handle, leaning out to the upper left
    erase &= arr[..., 3] > 0
    arr[erase] = 0
    fix_edges_after_erase(arr, erase)
    arr = remove_stray_outline(arr, 4)
    save(arr, ROOT / "art/interior/props/mop_bucket_empty.png")


def wall_end_tiles() -> None:
    """Splits the 32x64 tall wall end pieces into upper/lower 32x32 tiles (the engine draws a
    two-row wall face one cell at a time)."""
    for room in ["living", "hall", "kitchen", "bedroom", "bathroom", "store", "basement"]:
        for side in ["l", "r"]:
            tall = original(f"art/interior/tiles/wall_face_{room}_tall_end_{side}.png")
            save(tall[:32], ROOT / f"art/interior/tiles/wall_face_{room}_upper_end_{side}.png")
            save(tall[32:], ROOT / f"art/interior/tiles/wall_face_{room}_lower_end_{side}.png")


def _canvas(w: int, h: int) -> np.ndarray:
    return np.zeros((h, w, 4), dtype=np.uint8)


def _rect(img, x0, y0, x1, y1, colour) -> None:
    img[y0:y1, x0:x1] = (*hexc(colour), 255)


def _line(img, x0, y0, x1, y1, colour) -> None:
    n = max(abs(x1 - x0), abs(y1 - y0)) + 1
    for i in range(n):
        x = round(x0 + (x1 - x0) * i / max(n - 1, 1))
        y = round(y0 + (y1 - y0) * i / max(n - 1, 1))
        if 0 <= y < img.shape[0] and 0 <= x < img.shape[1]:
            img[y, x] = (*hexc(colour), 255)


def small_props_by_hand() -> None:
    out = ROOT / "art/exterior/props"
    # Side gate for the privacy fence: same planks, plus a Z brace, hinges and a latch.
    gate = original("art/exterior/props/fence_privacy.png")
    ys, xs = np.nonzero(gate[..., 3])
    top, bottom = ys.min() + 6, ys.max() - 6
    _line(gate, 3, bottom - 2, 28, top + 14, "4c3e24")
    _line(gate, 3, bottom - 3, 28, top + 13, "694f62")
    _rect(gate, 3, top + 12, 29, top + 15, "4c3e24")
    _rect(gate, 3, bottom - 4, 29, bottom - 1, "4c3e24")
    for hy in (top + 13, bottom - 3):
        _rect(gate, 1, hy - 1, 4, hy + 2, "3e3546")
    _rect(gate, 26, (top + bottom) // 2 - 1, 30, (top + bottom) // 2 + 2, "9babb2")
    save(gate, out / "fence_privacy_gate.png")

    # Church flyer taped to a lamp post (8x11).
    fl = _canvas(9, 12)
    _rect(fl, 0, 0, 9, 12, "2e222f")
    _rect(fl, 1, 1, 8, 11, "ffffff")
    for y in (3, 5, 7):
        _rect(fl, 2, y, 7, y + 1, "7f708a")
    _rect(fl, 2, 9, 4, 10, "4d9be6")
    save(fl, out / "flyer.png")

    # Kid's bike, side view (wheels, red frame, seat, bars), standing on its kickstand.
    bk = _canvas(38, 25)
    yy, xx = np.mgrid[0:25, 0:38]
    for cx in (8, 29):
        d = np.hypot(xx - cx, yy - 16)
        bk[(d <= 7.5) & (d > 5.5)] = (*hexc("2e222f"), 255)
        bk[(d <= 5.5) & (d > 4.6)] = (*hexc("625565"), 255)
        bk[d <= 1.2] = (*hexc("9babb2"), 255)
    for (a, b, c, d_) in [(8, 16, 17, 16), (17, 16, 25, 8), (8, 16, 14, 8), (14, 8, 25, 8), (17, 16, 13, 6), (25, 8, 29, 16)]:
        _line(bk, a, b, c, d_, "b33831")
        _line(bk, a, b - 1, c, d_ - 1, "e83b3b")
    _rect(bk, 10, 4, 17, 6, "2e222f")      # seat
    _line(bk, 25, 8, 24, 3, "625565")      # stem
    _rect(bk, 21, 2, 28, 4, "2e222f")      # bars
    save(bk, out / "bike.png")

    inner = ROOT / "art/interior/props"
    # Pegboard strip of 9-volt batteries for the checkout counter (stands on the counter top).
    bh = _canvas(18, 24)
    _rect(bh, 0, 0, 18, 24, "2e222f")
    _rect(bh, 1, 1, 17, 22, "9babb2")
    _rect(bh, 1, 1, 17, 3, "c7dcd0")
    for row, y in enumerate((5, 13)):
        for x in (3, 10):
            _rect(bh, x + 2, y - 2, x + 3, y, "625565")       # hook
            _rect(bh, x, y, x + 5, y + 6, "2e222f")
            _rect(bh, x + 1, y + 1, x + 4, y + 5, "f79617" if (x + row) % 2 else "e83b3b")
            _rect(bh, x + 1, y + 1, x + 4, y + 2, "fbb954")
    _rect(bh, 2, 22, 16, 24, "3e3546")       # foot
    save(bh, inner / "battery_hook.png")

    # Cork notice board (lost cat, guitar lessons, free kittens, "Need prayer? Ask Hollis").
    nb = _canvas(32, 24)
    _rect(nb, 0, 0, 32, 24, "2e222f")
    _rect(nb, 1, 1, 31, 23, "7a3045")
    _rect(nb, 2, 2, 30, 22, "cd683d")
    for (x, y, w, h, c) in [(4, 4, 8, 9, "ffffff"), (14, 3, 7, 6, "fbb954"), (22, 5, 6, 8, "f68181"), (5, 15, 9, 5, "8fd3ff"), (17, 12, 9, 8, "ffffff")]:
        _rect(nb, x, y, x + w, y + h, c)
        _rect(nb, x + 1, y + 2, x + w - 1, y + 3, "7f708a")
        nb[y, x + w // 2] = (*hexc("e83b3b"), 255)
    save(nb, inner / "notice_board.png")


def main() -> None:
    wall_end_tiles()
    small_props_by_hand()
    buildings()
    cars()
    small_props()
    fire()
    store_floor()
    female_body()
    hair_bob()
    mom_sit()
    dog()
    engine_sheets()
    couch_back()
    mop_bucket_empty()
    delivery_van()
    for name, geo in GEOMETRY.items():
        print(name, json.dumps(geo))


if __name__ == "__main__":
    main()
