# Exterior art manifest (Chapter 1)

Owner: exterior art agent. Covers `art/exterior/` (outdoor tiles, buildings, exterior props). Style rules and anchors: `art/STYLE.md`.

All PNGs: Resurrect 64 only, alpha 0/255, outline `#2e222f` on buildings and props (none on ground tiles), light from the top-left, top-down 3/4 view, true scale (never upscaled).


## 1. Outdoor tiles (32x32) - `art/exterior/tiles/outdoor/`

| file | use |
|---|---|
| `curb_e.png` | sidewalk on the left, road on the right |
| `curb_n.png` | sidewalk above, road below: curb top + vertical face + gutter shadow (the usual curb under a sidewalk row) |
| `curb_n_driveway.png` | dropped curb where a driveway crosses a curb_n row |
| `curb_s.png` | road above, sidewalk below (only the lit lip shows) |
| `curb_w.png` | road on the left, sidewalk on the right |
| `dirt.png` | dry dirt path |
| `driveway.png` | driveway concrete (seam on top edge) |
| `driveway_plain.png` | driveway concrete, no seam |
| `flowerbed.png` | mulch bed with flowers/shrubs |
| `grass_0.png` | lawn (variant A) |
| `grass_1.png` | lawn (variant B) |
| `grass_2.png` | lawn (variant C) |
| `grass_flowers.png` | lawn with a few flowers |
| `road_0.png` | asphalt |
| `road_crack.png` | asphalt with a crack |
| `road_crosswalk.png` | crosswalk bars (for a horizontal road) |
| `road_edge_h.png` | asphalt + white edge line near the top |
| `road_line_h.png` | asphalt + dashed yellow centre line (horizontal road) |
| `road_line_v.png` | same, vertical road |
| `road_patch.png` | asphalt with a tar patch |
| `sidewalk_0.png` | concrete sidewalk slab |
| `sidewalk_1.png` | sidewalk slab with a stain |
| `soil.png` | bare dark mulch |

Variants are interchangeable; pick by a hash of the cell to avoid visible repetition. Footstep surfaces: grass -> grass; road/sidewalk/curb/driveway -> asphalt; dirt/flowerbed/soil -> grass.


## 2. Transition (Wang corner) sets - `art/exterior/tiles/wang/<set>_NN.png`

16 tiles per set, plus `<set>_sheet_4x4.png` (preview, tile NN at row NN//4, column NN%4). **NN = 8*NW + 4*NE + 2*SW + 1*SE**, where a corner bit is 1 when that map vertex is the *upper* terrain. Paint terrain on the (W+1)x(H+1) vertex grid; every cell reads its 4 corners. All 16 tiles share one edge shape, so every combination is seamless. NN=0 is all lower, NN=15 all upper.

| set | lower (bit 0) | upper (bit 1) | look |
|---|---|---|---|
| `grass_sidewalk` | grass | sidewalk | crisp concrete edge, lit top-left lip, darker bottom-right edge |
| `dirt_grass` | dirt | grass | ragged lawn edge over a dirt path (paths and bare yards) |
| `flowerbed_grass` | flower bed | grass | lawn around beds: a bed is a patch of 0s in a lawn of 1s |
| `grass_driveway` | grass | driveway | driveway slab edge into the lawn |

## 3. Buildings - `art/exterior/buildings/`

Whole sprites at true scale. **Origin: bottom-centre** (foot of the front steps); y-sort by the bottom edge. Rectangles are `[x, y, w, h]` in pixels from the image top-left.

| file | size | solid collision | door (interaction point) | notes |
|---|---|---|---|---|
| `house_hale.png` | 412x526 | [0, 330, 412, 170]; steps x 154-258, y 500-526 stay walkable | (207, 445) | Hale house, 12 Linden Court: 1970s two-storey colonial, porch. Daytime/unlit windows. |
| `house_hale_night.png` | 412x526 | same | same | windows lit warm (evening, night with power) |
| `house_dunmore.png` | 412x526 | same as Hale | (205, 445) | neighbour Walt Dunmore: mirrored colonial, beige siding, green door |
| `house_dunmore_night.png` | 412x526 | same | same | windows lit |
| `house_okoro.png` | 406x206 | [0, 100, 406, 90]; stoop x 100-160, y 176-206 walkable | (130, 174); garage door x 300-375 | neighbour Okoro: one-storey ranch + garage (door ~55 px, see weak spots) |
| `store_ridge_mart.png` | 303x269 | [0, 150, 303, 105]; step y 255-269 walkable | (151, 239) | Ridge Mart corner store, open: lit sign "RIDGE MART / PHARMACY & DELI", lit windows |
| `store_ridge_mart_dark.png` | 303x269 | same | same | after the power cut: sign and windows dark |

Lights to add in the engine: Hale porch lamp beside the door (about (240, 395)); store window spill below the windows (y ~ 240, warm); lit house windows (warm, small). The roofs extend upward a lot (3/4 view): put buildings on a y-sorted layer so characters walking behind a building are hidden by its roof.
Name note: the sign says "RIDGE MART" as the lead asked; the script calls the shop "Ridge Corner Market". Re-stamping the sign is a 1-minute script change.


## 4. Exterior props - `art/exterior/props/`

**Origin: bottom-centre** unless noted. Collision = suggested footprint at the bottom of the sprite.

| file | size | collision | notes |
|---|---|---|---|
| `basketball_hoop.png` | 70x165 | 8x6 pole foot | driveway basketball hoop |
| `car_silver.png` | 218x128 | ellipse ~200x44 at the bottom | silver sedan, parked, front faces down-left |
| `car_teal.png` | 169x133 | ellipse ~150x40 at the bottom (body footprint) | small teal EV hatchback, parked, front faces down-left (mirror for down-right) |
| `car_wreck.png` | 223x157 | ellipse ~200x48 at the bottom | crashed SUV (Okoro): crumpled front, broken windscreen; add fx/fire + fx/smoke over the bonnet for the burning states |
| `car_wreck_burned.png` | 223x157 | ellipse ~200x48 at the bottom | burned-out wreck (after the fire). Burning states = car_wreck + fx/fire + fx/smoke over the bonnet (FX agent) |
| `delivery_bot.png` | 43x53 | 40x14 at the bottom | six-wheeled sidewalk delivery robot |
| `ev_charger.png` | 17x53 | 14x8 at the bottom | EV charger post |
| `fence_chainlink.png` | 32x44 | 32x6 at the bottom | chain-link fence module (see-through), tiles horizontally (anchor bottom-left for fences) |
| `fence_picket.png` | 32x40 | 32x8 at the bottom | white picket fence module, 32 px wide, tiles horizontally (anchor bottom-left for fences) |
| `fence_picket_broken.png` | 32x40 | 32x8 at the bottom | picket module with a missing picket (anchor bottom-left for fences) |
| `fence_privacy.png` | 32x56 | 32x8 at the bottom | tall wooden privacy fence (backyards), tiles horizontally (anchor bottom-left for fences) |
| `for_sale_sign.png` | 34x60 | 6x4 at the post foot | For Sale sign post (blank board, reduced 2:1) |
| `hedge.png` | 64x40 | 64x14 at the bottom | trimmed hedge, 64 px module (anchor bottom-left for fences) |
| `hedge_32.png` | 32x40 | 32x14 at the bottom | trimmed hedge, 32 px module (anchor bottom-left for fences) |
| `hydrant.png` | 17x33 | 12x6 at the bottom | fire hydrant (reduced 3:1 to true scale) |
| `mailbox.png` | 26x48 | 6x4 at the post foot | mailbox on a post |
| `news_drone.png` | 46x30 | - | delivery/news drone (flying, no ground contact; draw a separate shadow) |
| `planter.png` | 52x48 | 48x12 at the bottom | wooden planter box with shrub (reduced 2:1) |
| `recycling_bin.png` | 37x49 | 24x10 at the bottom | blue recycling bin (reduced 2:1) |
| `streetlight.png` | 84x169 | 8x6 pole foot | curved street light; lamp head at the top-left (approved style test) |
| `suv_red.png` | 219x161 | ellipse ~200x48 at the bottom | red SUV, parked, front faces down-left |
| `trash_can.png` | 40x57 | 24x10 at the bottom | green wheelie bin (reduced 2:1 to true scale) |
| `tree.png` | 136x182 | 16x10 trunk at the bottom | leafy street tree (approved style test) |

Cars face down-left in 3/4; mirror for down-right. No baked shadows: draw a soft dark ellipse under cars and characters. Small props reduced 2:1 or 3:1 from the generated sheet were re-outlined (never upscaled).


## 5. Paths for `data/art.json` (engine agent)

The current art.json points at `res://art/tiles/...` and `res://art/props/...`. Suggested new paths:

| art.json id | new path |
|---|---|
| `tile_grass` | `res://art/exterior/tiles/outdoor/grass_0.png` |
| `tile_sidewalk` | `res://art/exterior/tiles/outdoor/sidewalk_0.png` |
| `tile_curb` | `res://art/exterior/tiles/outdoor/curb_n.png` |
| `tile_road` | `res://art/exterior/tiles/outdoor/road_0.png` |
| `tile_road_line` | `res://art/exterior/tiles/outdoor/road_line_h.png` |
| `tile_path` | `res://art/exterior/tiles/outdoor/sidewalk_1.png` |
| `tile_driveway` | `res://art/exterior/tiles/outdoor/driveway.png` |
| `car_blue` | `res://art/exterior/props/car_teal.png` |
| `car_red` | `res://art/exterior/props/suv_red.png` |
| `suv_silver` | `res://art/exterior/props/car_silver.png` |
| `car_wreck` | `res://art/exterior/props/car_wreck.png` |
| `streetlight` | `res://art/exterior/props/streetlight.png` |
| `tree` | `res://art/exterior/props/tree.png` |
| `hedge` | `res://art/exterior/props/hedge.png` |
| `fence` | `res://art/exterior/props/fence_picket.png` |
| `mailbox` | `res://art/exterior/props/mailbox.png` |
| `hydrant` | `res://art/exterior/props/hydrant.png` |
| `trash_can` | `res://art/exterior/props/trash_can.png` |
| `for_sale_sign` | `res://art/exterior/props/for_sale_sign.png` |

No longer needed (buildings are whole sprites): `tile_siding`, `tile_siding_blue`, `tile_roof`, `tile_store_brick`, `tile_store_roof`, `porch`, `house_door`, `store_door`, `store_sign`, `store_window`. New ids to add: the buildings, `car_wreck_burned`, `basketball_hoop`, `delivery_bot`, `ev_charger`, `recycling_bin`, `planter`, `news_drone`, fence/hedge variants, Wang sets. Not made: `van` (self-driving delivery van), `bike`.


## 6. Mocks

Street mocks (960x540 and 1920x1080) are in the art agent scratchpad `revelation_art/` (`mock_street_dusk_*`, `mock_street_night_chaos_*`). They are lit with a palette LUT (6 light levels + 4x4 Bayer dither, emissive pixels untouched). Engine equivalent: `CanvasModulate` about `#8a7aa0` at dusk, `#4a4870` at night, plus additive PointLight2D pools (street lamps warm, car fire orange).

