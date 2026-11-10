# HEAVEN — handoff notes (keep updated at the end of every phase)

Working dir: `scratchpad/heaven/` (absolute: `/tmp/claude-0/-home-user-my-own-art/cb019c91-d4b5-5ec5-a8ec-8aef6ba03cf6/scratchpad/heaven/`).
Godot 4.7.2 binary: `scratchpad/godot/Godot_v4.7.2-stable_linux.x86_64`. Project: `heaven/game/`. Never touch any git repo or `/home/user/*` (read-only refs only).

## 1. Style rules
- **Palette:** Resurrect 64 only (`/home/user/project-revelation/art/style_anchors/resurrect64.hex`; loaded as `plh.R64/RGB/PAL`). Pass `target_palette` to every PixelLab call and quantize every final sprite (`quant()` in the build scripts). Additive light glows (`glow_*.png`, `throne_glow.png`, `rays.png`) are the only off-palette assets (smooth alpha FX).
- **Outline:** `#2e222f`. Light from the top-left (highlights on top-left bevels, shade on the bottom-right). View: 3/4 top-down.
- **Resolution:** viewport 960x540, window 1920x1080, stretch `canvas_items`, integer scale, nearest filter, 2D pixel snap. All coordinates in code are 960x540 viewport pixels.
- **Garden layout (Rev 22:1-2):** wall bottom 160; north grass bank 160–318 (trees base y 288); river 318–394; south bank 394–540 (trees base 516); gold street x 432–528 from the gate to the district; riverside path y 292–316 on the north bank (widened in the Shepherd pass). Trees x 100/320/640/860: every canopy (trunk base −54..+55 x, −109..+10 y) must lie fully on grass — `tools/scan_layout.py` checks this, plus people in water/behind canopies and earth props on paths/water. Bridge = deck exactly the street's width; parapets mirrored onto the street's edge bands (x 424–431 / 528–535), 5 evenly spaced posts.
- **Scale rule (true proportions):** person ~58 px; house ~3 people tall (~240–280 px), door a little taller than a person, windows at head height; vine trellis ~1.2x a person (70 px). Building generations at 168 px are Scale2x'd (`art/upscale.py`: EPX + outline thinning back to 1 px) so line weight matches.
- **Sizes:** tiles 32 px. Humans: 64x64 frames, feet on row 61, figure about 58–60 px tall. Elders 64x64 (seated on their throne). Living creatures 112 px. Trees 128x128 (trunk base at 64,112). Pearl gate 144x160 (arch about 85 px tall). Wall 110 px tall (bottom at y=160 in city/earth). Lamb 48 px, angels 32 px, animals 64 px (adult) / 48 px (young).
- **Depth:** backgrounds z -20/-10; water -9; glows -8/-15 (additive); bridge -7; a y-sorted `world` Node2D (z 0) holds trees, people, animals, houses and the player, all with origin at the feet; UI on a CanvasLayer. Glows over the scene z 5, particles z 6.
- **Mood:** bright, even light, no night, no dark shadows; soft light particles everywhere.

## 2. Biblical content rules used
- God the Father is never depicted: the throne holds a radial burst of light (jasper and carnelian, Rev 4:3), with no vertical body or head-like shape. In the city, the throne's light is only a glow at the river's source.
- Redeemed humans have real bodies: white robes, palms, no wings, no halos, no wounds, no frailty (1 Cor 15; Rev 7:9; 21:4). No children.
- Angels may have wings, but halos were removed. The four creatures have six wings with "eyes" drawn as jewel motifs (not horror). The Lamb is a white lamb with a 2-px muted mark only; the seven horns and seven eyes were omitted.
- Captions and NPC talk use **NIV (2011)** Scripture only, no invented doctrine or backstories. All verse text is in `game/data/verses.json` (entries: ref, cited verses, exact fragments, '...' for deliberate omissions, '\n' line breaks); scene data refers to it as `{key}` / `{key|block}` (resolved by `Scripture` in `SceneData.load_json`). Never type NIV text from memory: `tools/fetch_niv.py` caches whole chapters from Bible Gateway into `art/niv_source.json` — a **local check cache only: never ship it in the game or the repo**; `tools/check_verses.py` fails on any fragment that is not an exact substring, records the verse count (51 now; Biblica's limit is 500), and exits 0 with a note when the cache is absent. The Biblica notice is on the menu, in README and CREDITS.md.
- **No kneel poses anywhere** (user decision): every NPC stands, the Shepherd's group stands, and worship in the throne room is the music swell + "Holy, holy, holy" (Rev 4:8) text while the player stands facing the throne (hint "E: worship"). The hymn is the NICAEA tune (Dykes 1861, public domain), instrumental only. Kneel art, build code and game code were deleted.
- **The Shepherd (Rev 7:17)** is rendered per Rev 1:13-16: robe to the feet, golden sash, white hair, bronze feet, and the face as light only (white → fbff86 → f9c22b ramp radiating from the face centre, no features). Staff; no sword, no stars, no wound marks. Additive glow + sparkles. People stand at a respectful distance facing him.
- **Skin:** exactly one skin ramp per character (front, side, back, walk), taken from the approved front idle frame after cleaning; clean faces (eyes readable on deep tones, no blotches). `tools/check_skin.py` must report 1 for every character.
- The headscarf woman (p04) was removed entirely (data, sheets, build outputs, her only verse).
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
All build scripts import shared helpers from **`art/common.py`**: palette (`PALA`, `H`, `C`, `OUTL`), `dith`, `quant`, `snap_rgb`, `radial_glow`, `feet_to`, `breathe`, `palm_mask`, `sway`, `recolor`, `strip_bg`, `keep_main`, `erode_ground`. Re-running every script reproduces `game/art` byte-for-byte (verified with sha1 in the cleanup pass).

| Script | Does |
|---|---|
| `tools/plh.py`, `tools/guard.py` | API helpers (`gimg`, palette) and the **budget guard** (every paid POST) |
| `art/gen_*.py`, `art/mkchar.py`, `art/mkwalker.py`, `art/mk4dir.py`, `tools/anim.py` | **paid** generation scripts (already run; outputs in `art/raw/`) |
| `art/build_char.py` | hero sheet `game/art/hero.png` (6 rows: idle d/u/side x4, walk d/u/side x8) + `out/character_sheet_3x.png` |
| `art/build_walkers.py` | `game/art/people/walkerA/B.png` (same 6-row layout) |
| `art/build_people4.py` | 4-dir standing people `pNN.png` for 00 01 02 05 06 07 09 10 14 15 (rows down/up/left; cols idle/breathe/palmA/palmB), speech bubble, `out/people4_sheet_3x.png` |
| `art/build_shepherd.py` | the Shepherd `people/shepherd.png` (rows down/up/left = south/north/mirrored east rotation; cols idle/breathe) from `art/raw/ch_shepherd_rot_*`: face → light ramp, feet → bronze; `out/shepherd_sheet_3x.png` |
| `art/skin.py`, `art/fix_skin.py` | one skin ramp per character: drift colours → ladder, per-character `merge`/`face_merge` clean-ups (p00 lifted one step so eyes read, p07 chin blotch), every off-ramp skin pixel → nearest ramp shade. Applied in place to hero, walkers, pNN, shepherd |
| `art/skin_sheets.py` | `out/skin_fix_before_after.png` (front/side/back, before vs after, 3x; before copies in `art/work/skin_before/`) and `out/npc_lineup.png` |
| `tools/check_skin.py` | fails unless every character (incl. residents p31-35 and bearers, checked against their source ramp shifted) has exactly 1 skin ramp |
| `art/build_trees.py` | trees of life (dirt patch removed) |
| `art/build_scene.py` | garden bg (wide grass banks, river, riverside path, gold street with symmetric edges, wall + gate via wall.py), straight mirrored bridge, water ripples, glows |
| `art/build_throne_sprites.py` | creatures (+ the man-faced head repaint), Lamb, elders (rounded heads, bow frames, crowns), angels |
| `art/build_throne_scene.py` | throne-room bg, burst core, lamps, `art/throne/layout.json` |
| `art/build_wings.py` | wing flap frames (column shear) for creatures and angels |
| `art/wall.py` | shared city outer works: `draw_sky`, `wall_strip(width)` (jasper bands + 12-stone foundation), `pearl_gate()`, `add_city_top(bg, gate_x)` — any width |
| `art/upscale.py` | Scale2x + outline thinning for true-scale buildings |
| `art/build_district.py` | city district (rooms below/right of the garden): `game/art/district/dbg.png` (1920x540 at world y 540: calm gold yards, bright great street with gem-set curbs, door walkways, planters, jasper balustrade, light haze), dwellings (Scale2x), gifts, gift-bearer sheets (walkers' west walk + gift composited before the chest), new residents `people/p31-p35.png` (skin-ramp shifts of existing people via `skin.shift_colour` = new individuals, no duplicates), `layout.json` (incl. `gift_boxes` for the skin check) |
| `art/gen_district.py` | **paid**: dwellings (straight-front wording reused) and gifts |
| `art/build_earth.py` | **1920x1080** new-earth map: wall + gate across the top, main path + cross road + door paths, stream, roses, contact shadows; animals, hay stack, 5 houses (Scale2x), straight-front vine rows raised by hand, field trees, hammer, basket, `art/earth/layout.json` (map_size, houses, vine_rows, animals, trees, stream_rects) |
| `art/audio/synth.py` | **all audio** (procedural, CC0) into `game/audio/` |
| `tools/fetch_niv.py`, `tools/check_verses.py` | NIV source cache + exact-text check of `game/data/verses.json` |
| `tools/extend_font.py` | adds ‘ ’ “ ” – — … ® ™ é pixel glyphs to monogram → `game/fonts/monogram_ext.ttf` |
| `tools/scan_layout.py` | layout sanity scan across scenes |
| `art/mock*.py` | quick PIL composites to check layouts before Godot |

Order after a palette or helper change: build_char → build_walkers → build_people4 → build_shepherd → **fix_skin** → build_district → build_trees → build_scene → build_throne_sprites → build_throne_scene → build_wings → build_earth → skin_sheets, then `python3 -I tools/check_skin.py` and `godot --headless --path game --import`. fix_skin must run after any people/hero rebuild and before build_district.

## 5. Game architecture (`game/`)
Thin scenes over shared, typed components. Scripture text comes only from `data/verses.json` via `Scripture` (`scripts/core/scripture.gd`). **Content lives in data**: `game/data/{city,throne,earth}.json` (people, walkers, verses, zone captions, colliders, demo routes, titles). Art geometry comes from `art/throne/layout.json` and `art/earth/layout.json` (written by the build scripts).

| Folder | Module | Responsibility |
|---|---|---|
| `scripts/core` | `InputSetup` | registers actions once (move, run = Shift / pad B, talk/worship = E / pad A, places = T or Tab / pad Y); `is_escape()` |
| | `SpriteFactory` | `sprite()` (top-left), `grounded()` (feet origin), `glow()` (centred additive), `additive()`, `content_bottom()` |
| | `Blockers` | StaticBody rect colliders: `add`, `add_all` (data rects), `footprint` (at an object's feet) |
| | `Fx` | particles: `motes`, `glow_motes`, `sparkles`, `smoke` |
| | `SceneData` | JSON loading + `vec/rect/color/waypoints/points` |
| | `Audio` (autoload, `audio.gd`) | music cross-fade, ambience loops, one-shots |
| | `Travel` | static state across scene changes (`arriving`, `throne_from`, `demo`, `place_at`/`place_face` for fast travel) |
| `scripts/actors` | `Player` | 8-way movement, run (x1.8 speed, x1.6 animation), autopilot (Vector3 x, y, pause), `stepped` signal, static `build_frames()` |
| | `Npc` | `Npc.standing(person, pos, mode, facing, verse)` / `Npc.walker(sheet, loop, verse, steps)`; `quotes` rotate per talk (`take_quote()`); `speak(who)` turns and shows a bubble; meta `soften_music` lowers the music while it speaks (the Shepherd) |
| `scripts/ui` | `CaptionBar` | CanvasLayer: white fade, title, caption, hint. Caption priority: suppressed > spoken > forced > zone (`zone_resolver`, `wait_for_title`) |
| | `PlacesMenu` | fast-travel list from `data/places.json` (scene, spot, facing); chosen place → `SceneBase.travel` with the white fade, arrival via `Travel.place_at`. Key hint hidden on white fades |
| | `UiText` | the one label factory (monogram 16/32, outlined) |
| `scripts/talk` | `TalkSystem` | nearest Npc within 52 px → `speak` + caption for 5.5 s |
| `scripts/demo` | `DemoRecorder` | data-driven scripted walks: start/face/pause/waypoints, timed events (scene method names), SceneTree-bound quit |
| `scripts/camera` | `CameraRig` (rooms) | optional `rooms` (data `"rooms"`): at normal scale the camera frames the target's room and slides 0.6 s to the next, so each screen keeps its composition; `snap_to_target()` on start/respawn |
| | `CameraRig` | follow camera with **integer screen scales** 1 = overview, 2 = normal, 3 = close (camera zoom = scale / 2, since the window is 2x). Steps go through a 0.2 s soft white veil (no blurry in-between zoom). `min_scale()` from map bounds (one-screen maps: 2 and 3 only), clamped; `go_to/step/cycle/tour` |
| `scripts/scenes` | `SceneBase` | skeleton: data → background → y-sorted world → player → people → overlay → captions/talk/camera → audio → `_begin()`. Hooks: `_build_background/_build_world/_build_overlay/_setup_captions/_start_audio/_on_action/_tick/_begin`. Esc → menu |
| | `city.gd`, `throne.gd`, `earth.gd`, `menu.gd` | the scenes (main.tscn = city). Zoom input in SceneBase: mouse wheel, `+`/`-`, `Z` cycles. Demo events `zoom_overview/zoom_normal/zoom_close`. Scenes give `_map_bounds()` (earth: from layout map_size) |
| `scripts/throne` | `HeavenlyHost`, `ThroneLight`, `LivingCreatures`, `ElderCircle` | angels; burst/lamps/lightning; creatures + wings; elders, crowns, bowls, worship |
| `scripts/earth` | `Herd`, `Builder` | animals (idles, voices); hammer + knock |
| `scripts/city` | `District` | district bg, dwellings + footprints, planters, west-end light (glow + slowly turning rays, sparkles), motes |
| `tests` | `probe.gd` (autoload, `--probe`), `smoke_test.gd` (autoload, `--smoke`), `run_smoke.sh` | regression probes and the smoke test |

- **Collision:** Blockers from data rects or layout numbers; the wall is open only at the gate passage x 462–502, the city river only on the bridge deck x 440–520, and the stream rects come from the art mask.
- **Gate flow:** city gate light → new earth (Rev 21:25-26); the earth gate → city (spawn 482,186). Garden riverside path west into the river's source light → throne room (Rev 22:1); great street west into the light → throne room (Rev 22:3-4); throne room bottom edge → back to where the player came from (`Travel.throne_from`). All transitions use `SceneBase.travel()` / `arrive_at()`; demos chain into the next scene with `"then"` + `continue_demo()`. Smoke test covers all six ways. City map is 1920x1080 in three rooms: garden (0,0), district (0,1) and (1,1); the garden street continues south between dwellings into the great street.
- **Record args:** also `--district-demo` (garden → district → light → homes, with talk and a close zoom on the bearers).
- **Tests:**
  - `GODOT=<bin> game/tests/run_smoke.sh` loads menu/city/throne/earth for about 5 s each and checks: player spawned, colliders > 0, talk returns the nearest person (city/earth), worship works (throne: player frozen facing up, toggles back), all six transitions, running is ≥1.6x walking, fast travel to the throne room, no script errors.
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
| Garden fixes + NIV + paths to the throne | 0 | 0 | all by hand / code |
| City district | 30 | 25 | dwellings 15 (168 px, straight-front 4/4 usable), gifts 10 (64 x 32 px); bearers and residents made by hand |
| Scale + zoom | 40 | 40 | house2x 15, frame2x 15 (168 px = 15 each), vines2x 10 (came out oblique: unused; the straight v1 row was raised by hand instead) |
| Shepherd + run/teleport + kneel removal + skin pass | 15 | 11 | Shepherd 64 px image 10 (16 variants, seed 121), 4-dir create-character-v3 1; everything else by hand / code |
Balance after the Shepherd pass: 178.5 generations (confirmed via balance GET); USD 2.18083 throughout.

## 7. Known weak spots
- Gold plaza grid and rigid horizontal city layout; flat bridge; synthetic-sounding music.
- People: the 4-dir rotations differ slightly from the original front sprites; palm sway is still subtle (4 px at the tip). Skin pass: ramps are per character (front frame), not a single global ladder window, so light characters keep 5–6 shades; p00 was lifted one step (deep brown, not near-black) so his eyes read.
- Shepherd: idle only (no walk), side view is the mirrored east rotation (the west one had the staff over the face); the light face is a hand ramp, readable at 2x/3x but small at 1x.
- Creatures' wing motion is a shear (stepped edges); elders turn only left/right.
- New earth: houses are straight-front now but their roofs are seen fairly low; the meadow is a calm hand-painted base (soft patches, tufts, clustered roses) and is roomy between groups; the animals' idle is only a 1–2 px head dip; the builder's hammer is small.
- Zoom: the overview (1x) makes 64 px people small; captions stay screen-size (by design).
- District: dwellings only on the north side of the great street (front-view art can't face north); the south terrace below the street is open gold + balustrade + haze (calm but plain); bearers all walk west in two lanes; residents/bearers are recolours of existing people (new individuals by skin tone, same builds).
- Lesson: before paying for a piece, reuse the exact view wording/settings that already worked (the district dwellings came out 4/4 usable that way); an oblique vine batch was wasted in the scale pass.

## 8. Queued phases
(none: the Shepherd pass is done — wait for the coordinator.)
