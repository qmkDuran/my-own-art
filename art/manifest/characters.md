# Characters: Chapter 1 manifest

Owner: the character art agent. Files live in `art/characters/` (sprites), `art/characters/full/` (full animation
sheets) and `art/characters/portraits/` (128x128 portraits). Style follows `art/STYLE.md`: Resurrect 64, outline
`#2e222f`, light from the top-left, characters about 60 px tall, alpha 0 or 255 only.

## 1. Engine sheets (work with today's code, no changes needed)

`art/characters/<id>.png`: **256x192 = 4 columns x 3 rows of 64x64 frames**. The rows are `down`, `up`, `side`. Side
faces right and the engine mirrors it for left. The columns are 4 walk frames (frames 0, 2, 4 and 6 of the 8-frame walk
in the full sheet).

- `CharacterVisual` works out the frame size from the texture (`texture size / (hframes, vframes)`), so the current
  `"sheet": {"hframes": 4, "vframes": 3, "rows": {"down": 0, "up": 1, "side": 2}}` entries already fit. Frames are
  64 wide, not 32, because side walks and bodies with a backpack are about 30 to 40 px wide.
- Origin: feet at the bottom-centre. The lowest foot pixel of the standing frame is on row 63, centred on x = 32. The
  engine's offset (`-w/2, -h`) therefore puts the feet on the node position.
- Ids: `hero_female_body`, `hero_male_body`, `hair_long`, `hair_bob`, `hair_bun`, `hair_short`, `hair_buzz`,
  `hair_curly`, `mom`, `hollis` (columns = 4 **idle** frames, because he stands behind the counter), `dana`, `wade`,
  `looter`, `dog`.
- Suggested `fps`: 10 (8 is fine too). Each engine sheet holds every second walk frame, so 8 to 10 fps on the
  engine sheet matches the 10 fps of the full walk.

## 2. Full animation sheets (`art/characters/full/`)

`<id>_full.png` + `<id>_full.json`. **80x80 frames.** Each row is one animation in one direction, and frames run from
the left. The json lists for every row: `row`, `anim`, `dir` (down, up, side; side faces right), `frames`, `fps` and
`loop`. All frames of a character share one anchor: **feet at x = 40, lowest foot pixel on row 79** (from the first
frame of each row, so jumps and falls keep their motion). Unused cells are transparent.

| id | columns x rows | animations (rows), fps |
|---|---|---|
| hero_female_body / hero_male_body | 9 x 21 | idle 4f (r0-2) 6fps loop; walk 8f (r3-5) 10 loop; run 8f (r6-8) 14 loop; **swing** (bat) 9f (r9-11) 18; **roll** (dodge) 9f (r12-14) 16; hurt 6f (r15-17) 12; **down** (knocked out) 7f (r18-20) 10, hold the last frame |
| mom | 8 x 8 | idle 4f (r0-2) 6 loop; walk 8f (r3-5) 10 loop; talk 7f (r6, down only) 8 loop; **sit** 7f (r7, side only) 8, hold the last frame |
| hollis | 7 x 4 | idle 4f (r0-2) 6 loop; talk 7f (r3, down only) 8 loop |
| dana | 8 x 7 | idle 4f (r0-2) 6 loop; walk 8f (r3-5) 10 loop; **trapped** 7f (r6, down only) 8, hold the last frame (slumped, hand on her bleeding forehead) |
| wade / looter | 8 x 18 | idle (fight stance) 8f (r0-2) 8 loop; walk 8f (r3-5) 10 loop; **windup** 3f (r6-8) 8, hold the last frame for `windup` seconds; **attack** 3f (r9-11) 14; hurt 6f (r12-14) 12; down 7f (r15-17) 10, hold the last frame |
| dog (Biscuit) | 9 x 14 | idle 8f (r0-2) 6 loop; walk 8f (r3-5) 10 loop; run 8f (r6-8) 14 loop; growl/bark 6f (r9-11) 8 loop; **lunge** 9f (r12, side only) 14; **yelp**/flee 9f (r13, side only) 12, then play `run` away |

Windup and attack share one anchor, so `windup` followed by `attack` plays as one continuous punch. The punch is at
full extension around attack frame 1. Hero swing: the bat sweeps through roughly frames 3 to 6 of 9. Roll: the body is
lowest on roughly frames 3 to 6, which suits i-frames. These frame numbers come from eyeballing the sheets; tune them
in play.

## 3. Hero hair layers

`hair_<style>.png` (engine 4x3, 64x64) and `full/hair_<style>_full.png` (80x80) use **exactly the same layout as the
body of their gender**: same rows, columns and anchor. Draw them over the body in lockstep (as `add_layer` already
does). They have no json of their own and use the body's json (`hero_female_body_full.json` /
`hero_male_body_full.json`).

- Female body: `hair_long` (auburn ponytail), `hair_bob` (black bob), `hair_bun` (brown top bun). These are the
  picker's Long, Bob and Bun.
- Male body: `hair_short`, `hair_buzz`, `hair_curly`. These are the picker's Short, Buzz and Curly (`data/heroes.json`).
- How alignment works: each style is drawn once per direction (cut from a haired version of the same body). It is then
  placed on every frame by tracking the head (template correlation of the head silhouette and skin). In the knocked-out
  and roll frames it is also rotated by 90 degrees. Hair colours are fixed per style (plain R64, not swapped).

## 4. Skin key (palette swap)

`hero_female_body`, `hero_male_body`, `mom` (engine and full sheets) and `portrait_mom*` paint skin **only** with the
key ramp `#c89070` darkened by 0 / 0.10 / 0.15 / 0.30 / 0.45: `#c89070 #b48265 #aa7a5f #8c654e #6e4f3e`. The 0.12 and
0.20 shades are not used. No other pixel uses these colours. Hair layers, NPCs and the other portraits contain no key
colours. Everything else is Resurrect 64. These sprites need `"skin_swap": true`, which is already set in `data/art.json`.

## 5. Portraits (`art/characters/portraits/`, 128x128, transparent background)

| speaker | files |
|---|---|
| Mom (skin key) | `portrait_mom` (neutral, approved), `portrait_mom_happy` (smiling, approved), `portrait_mom_sad` (worried, eyes down, hands clasped), `portrait_mom_afraid` (teary, praying hands at the chin), `portrait_mom_praying` (eyes closed, praying); extras `portrait_mom_soft`, `portrait_mom_amused` |
| Hollis | `portrait_hollis`, `portrait_hollis_happy` |
| Dana | `portrait_dana` (dry half-smile), `portrait_dana_happy`, `portrait_dana_sad` |
| Wade | `portrait_wade` (exhausted), `portrait_wade_sad`, `portrait_wade_afraid`, `portrait_wade_angry` (wide-eyed panic) |

## 6. `data/art.json` changes needed (for the engine owner)

1. **Portrait paths**: change `res://art/portraits/<name>.png` to `res://art/characters/portraits/<name>.png` for
   `portrait_mom`, `_happy`, `_sad`, `_afraid`, `portrait_hollis`, `_happy`, `portrait_dana`, `_happy`, `_sad`,
   `portrait_wade`, `_sad`, `_afraid`, `_angry`.
2. **New entry**: `"portrait_mom_praying": {"extends": "portrait_mom", "path": "res://art/characters/portraits/portrait_mom_praying.png", "placeholder": {"mood": "praying"}}`.
   The same applies to `portrait_mom_soft` and `portrait_mom_amused` if wanted.
3. **Moods not drawn**: `portrait_hollis_sad`, `portrait_hollis_afraid` and `portrait_dana_afraid` have no art. Point
   them at `portrait_hollis` and `portrait_dana_sad`, or leave the placeholder. `portrait_looter*` has no art either:
   the generic looter has no portrait.
4. **Character sheets**: no change is needed. All `res://art/characters/<id>.png` paths and the 4x3 `sheet` blocks
   stay as they are. Optional: `"fps": 10`.
5. **To use the full animations**, add one entry per sheet, for example:
   ```json
   "hero_female_body_full": {"path": "res://art/characters/full/hero_female_body_full.png",
     "sheet": {"hframes": 9, "vframes": 21, "layout": "res://art/characters/full/hero_female_body_full.json"}, "skin_swap": true}
   ```
   Then have `CharacterVisual` pick `row = layout.rows[anim, dir]`, play `frames` at `fps`, and honour `loop`. Keep the
   hair layer on the same frame index. Ids: `<id>_full` for every character above, plus `hair_<style>_full` (same
   layout as its body, so `hframes` 9 and `vframes` 21).
6. `shadow` (`res://art/characters/shadow.png`) is not delivered, so the placeholder ellipse stays.

## 7. Known weak spots

- The heads, the female hero's especially, are bigger than ideal (they follow the approved style-test sprites).
- The template animations (down, hurt, the NPC idles) redraw the character each frame, so the face and the
  hair/cap shape drift a little between frames. Examples: Wade's hair looks larger from the back, and Hollis's side
  view differs from his front view.
- The female hero's side run shows a few dark-red pixels behind her (left over from the original ponytail). The long
  and bun styles hide them; bob does not fully.
- In the lying-down frames (down, roll), the hair is placed by a rotated head match, which is approximate.
- Mom `sit` turns from side to 3/4 front while sitting and was drawn with a chair, which has been removed. A few
  outline pixels may remain where the chair legs were. Place her on the scene's own chair.
- The dog was reduced 3:4 from 48 px (about 30 px tall now). In its walk and run down rows it is drawn a little smaller
  than in idle. Lunge and yelp exist for the side view only.
- Wade and the looter attack with a punch (no crowbar or bat), so the looter has no weapon to read as a pickaxe. The
  looter's `sfx_attack` is `bat_swing`, so `punch` may fit better.
