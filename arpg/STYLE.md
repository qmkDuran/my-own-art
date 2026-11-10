# The Great Prince — style guide (self-contained hand-off)

Everything a new artist or agent needs to add art that matches. The reference is **Michael's approved sprite**
(`game/art/michael/idle.png`, front idle frame). The approved look, at true relative scale, is
`out/reference_sheet.png`; the world before/after this guide is `out/style_before_after.png`.

## 1. Fixed rules
| Rule | Value | Checked by |
|---|---|---|
| Palette, characters/items | Resurrect 64 only | `tools/check_palette.py` |
| Palette, world (props, buildings, ground) | the 31-colour **WORLD** palette in `art/style.py`: Michael's 20 colours + grass (165a4c 374e4a 547e64 92a984), embers/brick (6e2727 b33831), night blue (323353 484a77 4d65b4), warm light (f9c22b f79617) | `check_palette.py` |
| Outline | 1 px `#2e222f` around every sprite's silhouette (≥90% of edge pixels on world props). Demons: a 1 px coloured rim sits *outside* the outline (their identity colour) | `check_palette.py` |
| View | 3/4 top-down, the same angle as the houses and Michael: fronts face the camera, tops are foreshortened (a flat roof shows as a thin strip, never a plan view) | eye; `build_zone.store_roof_3q` shows the fix |
| Light | from the top-left: highlights on top/left edges, shade bottom/right; no baked cast shadows on characters | eye |
| Shading | 3–4 tones per material, little dithering on characters, dither allowed on ground textures | eye |
| Scale | Michael is **58 px** head-to-feet (64 px frames, feet on row 61). Doors ≈ **1.15×** Michael (≈67 px); cars **1.6–1.9×** (≈95–110 px long); fences about waist high (**0.4–0.6×**); people 64 px frames like Michael; large demons (Mauler, Fire Horse) drawn at 1.5× | `check_palette.py` (`style.PIECES`) |
| Rescaling | only through `style.pixel_rescale(num, den)` (nearest up, majority-colour down: no blur), then `to_world_palette`, then `outline` | `build_zone.to_style` |
| Pixel grid | camera zoom 1.0 (option 1.5) on a 960×540 base stretched by whole factors; sprites never rotated or sub-pixel scaled | — |
| Night | a CanvasModulate tint (0.17, 0.18, 0.30); fires are the main lights (orange, flickering), one flickering streetlight, the rift's red glow. Characters and interactables (light mask 2) also catch Michael's soft character light so they stay readable; the ground does not | `zone.gd`, `michael.gd` |
| Text | Pixelify Sans 20 (titles, weight 600) / 10 (body), Silkscreen 8 (labels, numbers); no antialiasing, kerning off, +2 px word spacing; only via `UiDraw.TITLE/BODY/SMALL` | — |
| Content | demons are shadowy and menacing, never gory; no satanic imagery (no pentagrams, inverted crosses, 666, goat idols, sigils); Michael fights only spiritual enemies; no God figure; Satan is not shown | review |

## 2. How to add a piece
1. World prop from existing art: add it to `props()` in `art/build_zone.py`; if it has a door, car length or fence
   height, add it to `style.PIECES` with its measured source size and the scale that meets the rule; place it in
   `layout()` with `[art, x, base y, footprint w, footprint h]`. Run `python3 art/build_zone.py`.
2. New generated art (PixelLab; every call through `heaven/tools/guard.py`): use the prompt structure in
   `art/gen_michael.py` / `art/gen_revelation.py`, `style_image` = Michael's front sprite, `target_palette` R64,
   64 px; check a batch before animating. Then quantize and outline in a build script.
3. Run the checks: `python3 -I tools/check_palette.py`, `python3 -I tools/check_verses.py`,
   `GODOT=<godot> game/tests/run_smoke.sh`; regenerate `python3 art/reference_sheet.py`.

## 3. Files
- `art/style.py` — palette lists, scale rules, `pixel_rescale`, `to_world_palette`, `outline`, `edge_outline_share`.
- `art/build_arpg.py` — Michael, demons (+ variants, Revelation enemies), items, praying people.
- `art/build_zone.py` — ground, minimap, props (in style), `game/data/zone.json`.
- `art/reference_sheet.py` — `out/reference_sheet.png`.
- `tools/check_palette.py` — palette, outline and scale checks (exit 1 on a problem).
- `art/ext/` — read-only copies of Project R's exterior art (sources of the world pieces).

## 4. Generating new world art (lessons from the Step 2 test, `out/world_test_compare.png`)
- Tiles: create-tiles-pro with two 32 px crops of Michael as style images and the world palette works; road tiles may
  come back as overlays on transparency - lay them on a solid fill.
- Buildings: generate at a canvas where the door is already ~67 px (house ~400+ px tall), not at 168 px: upscaling a
  168 px house 4x reads blobby beside Michael. Keep the straight-front 3/4 wording.

## 5. Known gaps against the rules
- Project R houses keep their own shading density (a little busier than Michael); light direction already matches.
- Houses come from four sources (mirrored/darkened for variety).
- The overpass is a flat hand-drawn deck without an outline (it is drawn overhead).
