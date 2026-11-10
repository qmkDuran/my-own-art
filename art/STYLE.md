# Project R - shared art style (read before generating anything)

Owner of this file: the exterior art agent. All three art agents (exterior, characters, interiors+FX) follow it.

## Hard rules
- **Palette: Resurrect 64**, always passed to PixelLab as `target_palette` (`style_anchors/resurrect64.hex`, 64 colours, name "Resurrect 64"),
  with `style_options.color_palette = false`. After generation, snap every pixel to the palette (nearest in Lab) and set alpha to 0 or 255.
- **The only off-palette colours allowed** are the engine skin key ramp on skin-swap art (hero bodies, Mom, Mom's portraits):
  `#c89070` darkened by 0 / 0.10 / 0.15 / 0.30 / 0.45 -> `#c89070 #b48265 #aa7a5f #8c654e #6e4f3e` (see README "Skin palette swap").
- **Outline `#2e222f`, 1 px**, on characters, props and buildings (the silhouette edge). **No outline on ground tiles.**
- **Light from the top-left.** Top faces lightest, front faces mid, right/bottom edges darkest; drop shadows fall down-right.
- **Shading: 3-4 tones per material.** No dithered gradients on characters or props (dither only in large light pools / sky, as the mocks do). **No pure black** (darkest colour is `#2e222f`).
- **View: top-down 3/4** (Eastward / Stardew): ground and roofs seen from above at ~45 degrees, fronts of buildings and furniture face the camera, characters in 3/4.
- **Scale (never upscale; generate at final size, or reduce 2:1 / 3:1 by majority vote and re-outline):**
  view 960x540, tiles 32 px, characters ~60 px tall in 64x64 (engine) or 80x80 (full sheets) frames with feet at the bottom-centre,
  house doors ~70 px tall (1.15x a character), cars 150-210 px long in 3/4, furniture at real size (fridge ~60 px tall, couch ~75 px wide), portraits 128x128.
- Grounded suburban look, warm dusk mood in mocks; the sprites themselves are painted in neutral evening light (the engine adds CanvasModulate + PointLights).

## Style anchors (`art/style_anchors/`) - pass as PixelLab `style_image` on every generation
| use for | file | notes |
|---|---|---|
| characters | `anchor_character_hero_f.png` (27x60) | approved hero F sprite from the style test (clean, small head, realistic proportions) |
| portraits | `anchor_portrait_mom.png` (128x128) | approved early-50s Mom portrait |
| buildings, props, interiors | `anchor_building_crop_256.png` (256x256 crop of the Hale house front) or `anchor_prop_car_teal.png` | full house: `anchor_building_house_hale.png` (412x526, too big for style_image) |
| ground / floor tiles | `anchor_ground_tiles.png` (128x128: grass, sidewalk, curb, road with lane line) | ground tiles have no outline |

PixelLab note: `create-character-v3` + template animations are 1 generation per direction and keep the anchor look; the v3 custom animations cost ~3 per direction;
`generate-image-v2` above 170 px is 25 generations for one image and tends to draw small things at ~2x scale (reduce 2:1 afterwards). Max 8 concurrent jobs per account.
