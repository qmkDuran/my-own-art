# Ruins Edge v3: big set pieces

The top and mid tiers from the world-scale spec (`scale_research/CONCLUSION_AND_SPEC.md`, section 3): elder trees, a
gate landmark, a colossus head, large trees, tall wall segments and pillars, plus terrace and chasm edge tiles.
1 art px = 1 game px (hero 46 px, tile 32 px); nothing here is scaled. Each sprite is drawn at the size the spec asks
for, so all of them are taller than 110 px. That keeps them out of the crowded 46–110 px band.

Made with PixelLab `generate-image-v2` (Apollo world palette, a v2 tree or wall or the v2 colossus as the style
image), then cleaned: snapped to Apollo (0 off-palette pixels), graded one step with grade B (trees also get the v2
bark darkening: `884b2b→4d2b32, 602c2c→341c27, 7a4841→4d2b32, 4d2b32/341c27→241527`), stray pixels and islands
removed, a 1 px `#090A14` outline added, alpha set to 0/255, and trimmed. Light comes from the top left.
Cyan appears only on the colossus head's eye glow (kept ungraded, like the v2 colossus core).

## How to place a piece

- **Origin** is the pixel in the sprite that sits on the node's position, in sprite-local pixels from the top left.
  It is the base of the trunk, wall or tower, and it is the y-sort point. In Godot, use a `Sprite2D` with
  `centered = false` and `offset = -origin`, under a y-sorted parent.
- **Collision** is `w × h`, centred on the origin (a flat box at the base), unless the piece lists collision rects.
- Canopies do not need splitting. The hero is only ever behind a canopy when he stands north of the trunk base, and
  then the y-sort already draws the whole tree over him.

## Pieces

| File | Tier | Size (w×h) | Origin | Collision | Notes |
|---|---|---|---|---|---|
| `elder_tree_a.png` | L1 | 188×307 | (94, 243) | 48×18 | Elder tree with open roots. 6.7× hero; let the canopy run off the frame |
| `elder_tree_b.png` | L1 | 190×281 | (83, 221) | 52×20 | Elder tree, hollow trunk on broken stones |
| `elder_tree_c.png` | L1 | 189×301 | (103, 260) | 55×18 | Elder tree, leaning trunk, dead branches |
| `large_tree_a.png` | M1 | 160×192 | (79, 177) | 31×12 | Large tree, full canopy |
| `large_tree_b.png` | M1 | 156×192 | (85, 161) | 33×12 | Large tree, twisted trunk |
| `large_tree_c.png` | M1 | 156×188 | (77, 155) | 33×12 | Large tree, dying, bare branches |
| `gate_arch.png` | L2 | 224×220 | (60, 202) | rects (14,184)-(104,208) and (128,144)-(212,168) | Broken brick gate arch at a 3/4 angle. The left tower is in front and the right tower sits 40 px further back; the passage runs between them (x 104–128). See the halves below |
| `gate_arch_left.png` / `gate_arch_right.png` | L2 | 224×220 each (same canvas) | left (60, 202), right (170, 166) | as above, one rect each | `gate_arch` cut at x = 116. Place both at the same position and give each its own y-sort origin, so the hero walking through the passage goes in front of the back tower and behind the front tower |
| `gate_temple.png` | L2 (alt) | 213×224 | (70, 216) | rects (14,198)-(90,222) and (132,172)-(205,194) | Temple doorway: a front-facing facade with steps up to a dark doorway (decorative, not a passage), with the right side collapsed |
| `colossus_head.png` | L3 | 224×191 | (112, 165) | 150×40 | A giant fallen colossus skull with cables and a dim cyan glow in the eyes. Pair it with the v2 colossus arm or body. Slightly over the spec's 192×160 canvas; it is kept at its native size rather than scaled |
| `wall_breach.png` | M2 | 96×138 | (48, 124) | 92×18 | Full-height wall with a broken opening and roots |
| `wall_window.png` | M2 | 96×153 | (48, 139) | 92×18 | Wall with a tall gothic window (the tallest wall) |
| `wall_arch_window.png` | M2 | 96×137 | (48, 123) | 92×18 | Wall with an arched window |
| `wall_broken.png` | M2 | 96×124 | (48, 110) | 92×18 | Tall on the left, collapsed on the right. Use it to end a chain (flip it for the other end) |
| `wall_stepped.png` | M2 | 95×137 | (47, 123) | 92×18 | Wall with a stepped break in the middle |
| `pillar_tall_a.png` | M3 | 46×136 | (23, 128) | 26×12 | Whole column, clean |
| `pillar_tall_b.png` | M3 | 47×137 | (23, 129) | 26×12 | Whole column, wrapped in roots |
| `pillar_snapped.png` | M3 | 48×119 | (24, 111) | 26×12 | Column snapped at about 118 px. Hand-cut from a tall column so it stays above 110 px; PixelLab's snapped stubs came out 63–76 px, which is inside the band the spec forbids, so they were not used |

**Wall chains.** The walls are drawn at the same 3/4 angle as the v2 walls, with a thick left side face. Chain them
left to right with each segment 80–90 px to the right of the last, stepping 0 to ±100 px in y for a wall that
runs diagonally (see mock 2). Put pillars at the joins, and finish each end with `wall_broken`. Mirroring is fine,
but keep the light coming from the top left on the main runs.

## Edge tiles: `art/tiles/ruins_edge_v3_edges.png` + `ruins_edge_v3_edges_tileset.tres`

These are hand-coded in Python, not PixelLab, as the spec preferred: 32 px tiles, Apollo only, 5 columns × 8 rows. Put them on an overlay
`TileMapLayer` above `Ground`; their transparent pixels let the ground show through. The TileSet has one physics
layer (collision layer 1, as in v2), with the blocking shapes already set.

| Row | Content | Columns |
|---|---|---|
| 0 | T1 terrace lip: top 22 px clear, a mossy lit rim, then the face begins | 0 left end, 1–3 middle variants, 4 right end |
| 1 | T1 terrace face (earth/rock bank with roots and moss drips) | same |
| 2 | T1 terrace base: the face ends at row 2 + 22 px (a **64 px face** in total), then a contact shadow and fallen stones | same |
| 3 | T1 terrace sides and corners | 0 left side (drop to the left), 1 right side, 2 back rim, 3 and 4 inner corners |
| 4 | T2 chasm lip: a crumbly rim, then rock | 0 left end, 1–3 middle, 4 right end |
| 5 | T2 chasm face: fractured rock, getting darker | same |
| 6 | T2 chasm deep: rock fading to `#090A14` (rows 4–6 make a **96 px drop**) | same |
| 7 | T2 void and sides | 0–2 void variants, 3 left side (void on the left), 4 right side |

The middle tiles of a row can be placed in any order next to each other: every tile has a crack or seam on its left
column. The darkness beyond the chasm is meant to be code (a gradient or shader), as the spec says.

## Where things are

- Sheet at 3× with origins and collision boxes, and composed mocks at 640×360 (3×, lit and unlit, plus 480×270 crops at 4×):
  `scratchpad/step2_art/`.
- The sources and build scripts are in `scratchpad/step2_work/` (`build_v3.py`, `tools/edges.py`, `make_tres.py`,
  `mocks.py`, `sheet.py`), and the generation ledger is `pl/ledger.jsonl`.
