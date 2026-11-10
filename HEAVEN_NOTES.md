# HEAVEN — handoff notes (keep updated at the end of every phase)

Working dir: `scratchpad/heaven/` (absolute: `/tmp/claude-0/-home-user-my-own-art/cb019c91-d4b5-5ec5-a8ec-8aef6ba03cf6/scratchpad/heaven/`).
Godot 4.7.2 binary: `scratchpad/godot/Godot_v4.7.2-stable_linux.x86_64`. Project: `heaven/game/`. Never touch any git repo or `/home/user/*` (read-only refs only).

## 1. Style rules
- **Palette:** Resurrect 64 only (`/home/user/project-revelation/art/style_anchors/resurrect64.hex`; loaded as `plh.R64/RGB/PAL`). Pass `target_palette` to every PixelLab call and quantize every final sprite (`quant()` in the build scripts). Additive light glows (`glow_*.png`, `throne_glow.png`, `rays.png`) are the only off-palette assets (smooth alpha FX).
- **Outline:** `#2e222f`. Light from the top-left (highlights on top-left bevels, shade on the bottom-right). View: 3/4 top-down.
- **Resolution:** viewport 960x540, window 1920x1080, stretch `canvas_items`, integer scale, nearest filter, 2D pixel snap. All coordinates in code are 960x540 viewport pixels.
- **Sizes:** tiles 32 px. Humans: 64x64 frames, feet on row 61, figure about 58–60 px tall. Elders 64x64 (seated on their throne). Living creatures 112 px. Trees 128x128 (trunk base at 64,112). Pearl gate 144x160 (arch about 85 px tall). Wall 110 px tall (bottom at y=160 in city/earth). Lamb 48 px, angels 32 px, animals 64 px (adult) / 48 px (young).
- **Depth:** backgrounds z -20/-10; water -9; glows -8/-15 (additive); bridge -7; a y-sorted `world` Node2D (z 0) holds trees, people, animals, houses and the player, all with origin at the feet; UI on a CanvasLayer. Glows over the scene z 5, particles z 6.
- **Mood:** bright, even light, no night, no dark shadows; soft light particles everywhere.

## 2. Biblical content rules used
- God the Father is never depicted: the throne holds a radial burst of light (jasper and carnelian, Rev 4:3), with no vertical body or head-like shape. In the city, the throne's light is only a glow at the river's source.
- Redeemed humans have real bodies: white robes, palms, no wings, no halos, no wounds, no frailty (1 Cor 15; Rev 7:9; 21:4). No children.
- Angels may have wings, but halos were removed. The four creatures have six wings with "eyes" drawn as jewel motifs (not horror). The Lamb is a white lamb with a 2-px muted mark only; the seven horns and seven eyes were omitted.
- Captions and NPC talk use KJV Scripture only, no invented doctrine or backstories. The hymn is the NICAEA tune (Dykes 1861, public domain), instrumental only.
- Physical sense: no floating objects, no one in water, doors face paths, collision matches the visuals. Check placements programmatically (see the earth sanity check).

## 3. PixelLab lessons (API v2; the key is injected by the proxy as `Authorization: Bearer dummy`)
- **Every POST goes through `tools/guard.py::paid_post(path, body, est, label)`.** It enforces START/CAP and stops if USD credits move. GETs use `guard.get`. The log is `spend_log.txt`; `total_used` there is computed from the balance.
- **Real costs:**
  - `generate-image-v2`: 10 gens at sizes up to 128 px (64 px gives 16 variants, 48 px gives 25, 32 px gives 64, 86–128 px gives 4). 144–170 px costs 15.
  - `create-tiles-pro` (16 tiles of 32 px): 10.
  - `create-character-v3` from a 64 px reference image with `n_directions: 4`: 1.
  - `/characters/animations`, template mode `walking-8-frames`: 1 per direction (the job's usage shows USD, but the balance drops in generations, not USD).
  - `skeleton-v3` mode: 3 per direction (steadier identity).
- **Good settings:**
  - `style_image` = `anchor_character_hero_f.png` for characters, `anchor_building_crop_256.png` for buildings and props, `style_options.color_palette=false`, plus `target_palette` R64.
  - Listing variety in the prompt ("each image a different person/animal from this list: …") gives diverse batches.
- **Failures and workarounds:**
  - Template walk in the west direction dropped the hero's palm: use skeleton-v3 for that direction, or pick walkers without palms.
  - A `reference_images` entry of the hero made the man-faced creature look like the player: avoid character refs when the result must look different.
  - Some outputs came with an opaque background (the ox): flood-fill removal.
  - Generated angels had halos, and buildings, trees and animals had ground patches: remove by hand (`keep_main`, `erode_ground`).
  - The first throne core read as a human silhouette: replaced by a hand-made burst.
- `fetchchar.py NAME CID` downloads rotations and animations (free).

## 4. Pipeline scripts (run from `heaven/`; none of these call the API unless named gen_*/mk*)
All build scripts import shared helpers from **`art/common.py`**: palette (`PALA`, `H`, `C`, `OUTL`), `dith`, `quant`, `snap_rgb`, `radial_glow`, `feet_to`, `breathe`, `kneel(frame, facing)`, `palm_mask`, `sway`, `recolor`, `strip_bg`, `keep_main`, `erode_ground`. Re-running every script reproduces `game/art` byte-for-byte (verified with sha1 in the cleanup pass).

| Script | Does |
|---|---|
| `tools/plh.py`, `tools/guard.py` | API helpers (`gimg`, palette) and the **budget guard** (every paid POST) |
| `art/gen_*.py`, `art/mkchar.py`, `art/mkwalker.py`, `art/mk4dir.py`, `tools/anim.py` | **paid** generation scripts (already run; outputs in `art/raw/`) |
| `art/build_char.py` | hero sheet `game/art/hero.png` (7 rows: idle d/u/side x4, walk d/u/side x8, kneel d/u/side) + `out/character_sheet_3x.png` |
| `art/build_walkers.py` | `game/art/people/walkerA/B.png` (same 7-row layout) |
| `art/build_people4.py` | 4-dir standing people `pNN.png` (rows down/up/left; cols idle/breathe/kneel/palmA/palmB), speech bubble, `out/people4_sheet_3x.png` |
| `art/build_trees.py` | trees of life (dirt patch removed) |
| `art/build_scene.py` | city bg (wall bands, gem foundation, gold sheen, banks, river bed), bridge, water ripples, glows |
| `art/build_throne_sprites.py` | creatures (+ the man-faced head repaint), Lamb, elders (rounded heads, bow frames, crowns), angels |
| `art/build_throne_scene.py` | throne-room bg, burst core, lamps, `art/throne/layout.json` |
| `art/build_wings.py` | wing flap frames (column shear) for creatures and angels |
| `art/build_earth.py` | new-earth bg (path, stream, roses, contact shadows), animals, hay stack, houses, vines, field trees, hammer, basket, `art/earth/layout.json` |
| `art/audio/synth.py` | **all audio** (procedural, CC0) into `game/audio/` |
| `art/mock*.py` | quick PIL composites to check layouts before Godot |

Order after a palette or helper change: build_char → build_walkers → build_people4 → build_trees → build_scene → build_throne_sprites → build_throne_scene → build_wings → build_earth, then `godot --headless --path game --import`.

## 5. Game architecture (`game/`)
Thin scenes over shared, typed components. **Content lives in data**: `game/data/{city,throne,earth}.json` (people, walkers, verses, zone captions, colliders, demo routes, titles). Art geometry comes from `art/throne/layout.json` and `art/earth/layout.json` (written by the build scripts).

| Folder | Module | Responsibility |
|---|---|---|
| `scripts/core` | `InputSetup` | registers actions once (move, talk/worship = E); `is_escape()` |
| | `SpriteFactory` | `sprite()` (top-left), `grounded()` (feet origin), `glow()` (centred additive), `additive()`, `content_bottom()` |
| | `Blockers` | StaticBody rect colliders: `add`, `add_all` (data rects), `footprint` (at an object's feet) |
| | `Fx` | particles: `motes`, `glow_motes`, `sparkles`, `smoke` |
| | `SceneData` | JSON loading + `vec/rect/color/waypoints/points` |
| | `Audio` (autoload, `audio.gd`) | music cross-fade, ambience loops, one-shots |
| | `Travel` | static state across scene changes (`arriving`, `demo`) |
| `scripts/actors` | `Player` | 8-way movement, autopilot (Vector3 x, y, pause), `stepped` signal, kneel, static `build_frames()` |
| | `Npc` | `Npc.standing(person, pos, mode, facing, verse)` / `Npc.walker(sheet, loop, verse, steps)`; `speak(who)` turns and shows a bubble |
| `scripts/ui` | `CaptionBar` | CanvasLayer: white fade, title, caption, hint. Caption priority: suppressed > spoken > forced > zone (`zone_resolver`, `wait_for_title`) |
| | `UiText` | the one label factory (monogram 16/32, outlined) |
| `scripts/talk` | `TalkSystem` | nearest Npc within 52 px → `speak` + caption for 5.5 s |
| `scripts/demo` | `DemoRecorder` | data-driven scripted walks: start/face/pause/waypoints, timed events (scene method names), SceneTree-bound quit |
| `scripts/camera` | `CameraRig` | Camera2D with **integer zoom levels** [1,2,3], map-bound clamping, `tour()`; at level 1 on one screen it is invisible |
| `scripts/scenes` | `SceneBase` | skeleton: data → background → y-sorted world → player → people → overlay → captions/talk/camera → audio → `_begin()`. Hooks: `_build_background/_build_world/_build_overlay/_setup_captions/_start_audio/_on_action/_tick/_begin`. Esc → menu |
| | `city.gd`, `throne.gd`, `earth.gd`, `menu.gd` | the scenes (main.tscn = city) |
| `scripts/throne` | `HeavenlyHost`, `ThroneLight`, `LivingCreatures`, `ElderCircle` | angels; burst/lamps/lightning; creatures + wings; elders, crowns, bowls, worship |
| `scripts/earth` | `Herd`, `Builder` | animals (idles, voices); hammer + knock |
| `tests` | `probe.gd` (autoload, `--probe`), `smoke_test.gd` (autoload, `--smoke`), `run_smoke.sh` | regression probes and the smoke test |

- **Collision:** Blockers from data rects or layout numbers; the wall is open only at the gate passage x 462–502, the city river only on the bridge deck x 440–520, and the stream rects come from the art mask.
- **Gate flow:** city gate light → new earth (Rev 21:25-26); the earth gate → city (spawn 482,186).
- **Tests:**
  - `GODOT=<bin> game/tests/run_smoke.sh` loads menu/city/throne/earth for about 5 s each and checks: player spawned, colliders > 0, talk returns the nearest person (city/earth), kneel works (throne), no script errors.
  - Probe: `godot --headless --fixed-fps 60 --path game -- --demo --probe` logs `PROBE scene f=.. p=x,y blockers=N npcs=N` every 30 frames. Baselines are in `art/baseline/*.log`; player paths are deterministic (verified twice).
- **Record:** `xvfb-run -a -s "-screen 0 1920x1080x24" godot --rendering-driver opengl3 --fixed-fps 60 --write-movie DIR/f.png --path game -- ARGS`.
  - ARGS: `--demo` (city), `--throne --demo`, `--throne --closeup`, `--earth-demo`.
  - Mux: `ffmpeg -framerate 60 -i DIR/f%08d.png -i DIR/f.wav -c:v libx264 -pix_fmt yuv420p -crf 16 -c:a aac -b:a 192k -shortest out.mp4`.
  - About 5–7 min per 35 s.
- **Known benign log line:** "N resources still in use at exit" (one-shot sound players alive at quit).

## 6. Budget history (generations)
| Phase | Cap | Spent | Notes |
|---|---|---|---|
| City + character | 110 | 67 | char 17, tiles 10, wall 15, gate 15, tree 10 |
| Throne room | 90 | 80 | elder 10, 4 creatures + 1 redo 50, lamb 10, angels 10 |
| Throne fixes, sound, heads, wings | 0 | 0 | all by hand / code |
| People | 30 | 18 | batch 10, two 4-dir walkers 8 |
| New earth | 80 | 50 | animals 20, houses 10, frame 10, vines 10 |
| People fix pass | 15 | 11 | 11 x 4-dir create-character-v3 (1 each, ~3 min each) |
| Code cleanup | 0 | 0 | refactor only; behaviour verified identical |
Balance after the people fix pass: 254.5 generations; USD 2.18083 throughout.

## 7. Known weak spots
- Gold plaza grid and rigid horizontal city layout; flat bridge; synthetic-sounding music.
- People: the 4-dir rotations differ slightly from the original front sprites; palm sway is still subtle (4 px at the tip); the kneel is a hand-drawn robe pool (simple); side-view kneel is weakest.
- Creatures' wing motion is a shear (stepped edges); elders turn only left/right.
- New earth: houses come from oblique-view generations (slightly different perspective from the top-down meadow); the builder's hammer is small; the animals' idle is only a 1–2 px head dip.

## 8. Queued phases (wait for the coordinator's go and guard reset)
1. **New earth scale + zoom** (cap 40):
   - Regenerate the houses at about 3 people tall (doors slightly taller than a person, matching the top-down 3/4 view) and the house under construction; vine rows about 1.2x person height.
   - Expand to about 3x2 screens with a following camera (`CameraRig.target`, `bounds`): wall + gate along the top, villages, vineyards, meadows, stream, animals.
   - Integer zoom 1x/2x/3x on the mouse wheel and +/- (`CameraRig.set_level`), UI unaffected; maybe the city too.
   - Deliver screenshots at each zoom and an mp4.
2. **City district screen** (cap ~30): an adjacent screen with the great street of gold toward the throne light (light only), dwellings (John 14:2) with doors on the street, people at their homes, nations bringing glory (Rev 21:24-26). Uncluttered.
