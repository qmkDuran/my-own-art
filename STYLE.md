# LANTERNFALL — style guide

## View
**3/4 top-down, orthogonal** (square 32 px cells, like classic top-down pixel RPGs) — never isometric. Depth comes
from lighting, ground shadows under every body and prop, props with height drawn upward from their ground anchor,
and y-sorting (whatever stands lower on screen is in front). Ground anchor = bottom centre of every sprite.

## Rendering
- Base viewport 960 x 540, integer scaling (2x at 1080p), nearest filtering, pixel snap. Camera zoom 1.
- The world is **dark and muted** (CanvasModulate ~ (0.075, 0.08, 0.13)); light comes from the lantern (banded,
  warm), lit waylamps, glass crystals (faint teal) and effects. **Abilities shine**: bright, saturated, additive,
  unlit (`Fx.glow_material()`), and every big moment briefly lights its surroundings (`Fx.flash`). Effects stay
  short (≤ 0.35 s for hits) so combat stays readable.
- Emissive layers (`*_glow.png`): lantern panes, eyes, glints. In darkness you read creatures by their eyes and
  rims; in light you see the whole body.

## Palette (`art/palette.py`, mirrored in `scripts/core/pal.gd`)
Three families, 38 colours: **Dusk** darks (void→bone, blue-violet), **Lantern** warmth (ember_dk→sun), **Glass**
(glass_dp→glint, teal), plus muted moss/earth/stone bridges and a few accents (blood, rose, violet, skin). Every
sprite pixel must be in the palette (`tools/check_art.py`). UI uses palette names via `Pal.c()`; rarity colours
(blue magic, gold rare, green set, orange unique) are the only UI-only colours.

## Sprites
- 1 px dark outline (void) on everything; **cool rim light on the left** (dusk3/violet), **warm lantern rim on the
  right** (ember/rust) for people; top rims on props (mist/glint). Light direction is consistent: the moon-less
  ambient from above-left, the lantern from the Lamplighter's right.
- Size classes (visible body): the Lamplighter 52–62 px (with hat and staff), people 36–64 (children ~40),
  small enemies 24–44, medium 24–52, mini-bosses 100–126; bosses later 128–192. Checked by `check_art.py`.
- Feet stay on the same line through idle/walk/move frames (no sliding); attacks may leap.
- Silhouettes first: every character has one unmistakable shape (the Lamplighter's brim + hooked lantern staff +
  capelet; Ysolde's pike and helm; Lio's pointed hood; Hask's smoke horns; Teague's hood, cape and cold lantern).
- Front-facing people (mirrored to face the cursor side); attacks aim in any direction through effects (the whip
  sweeps an arc toward the cursor, Lancet fans a cone, projectiles fly at the cursor).

## Biomes (each recolours the same ground shader through `ground`)
- **Glasswood**: moss and dark glass, teal glints, glass stream. **Ember Road**: ash-dark fields with pale stubble,
  burnt bramble hedgerows with live embers, a black canal with ember glints. **Moth Hollow**: near-black cave rock,
  dusty floors, black pools, violet hunger nests, a silk-web nest floor. **Tallow**: round cobbles, warm windows,
  the Great Lantern's huge warm light, rampart tops seen from above.
- Tall things (trees, stalagmites, buildings) turn see-through when they stand in front of someone or of the caption.

## Ground
Shader-drawn from the terrain grid with palette colours and 4x4 ordered dithering; borders warped by noise (≤ 5 px
from the collision line); water, paths and the stone ring drawn from their true geometry (never staircase steps);
the forest's canopy shades open ground to its south.

## UI
- Fonts (OFL): **Pixelify Sans** titles 20 / body 10, **Silkscreen** small 8 (numbers, keys, labels). Whole-pixel
  sizes, no antialiasing, 2 px ink outline on text. Sizes only via `UiDraw.TITLE/BODY/SMALL`.
- Panels: ink fill, thin brass frame, amber corner rivets, a title bar; tooltips are the same in a deeper ink.
- Layout from the viewport size, never fixed coordinates; checked at 8 sizes of 16:9 and 16:10 (`--ui`).
- Tooltips carry real numbers (damage ranges after increases, radius in px, cooldown after recovery, affix tiers,
  differences against worn items).

## Words
One or two short sentences per line; a speaker on every line; lore optional; no walls of text.
