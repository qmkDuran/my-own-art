# MONSTER TAMER — style guide

## View and scale
- Classic top-down handheld view on a 16 px grid. Base screen **320x180**, `stretch_mode = viewport`, integer
  scaling (4x at 720p, 6x at 1080p), nearest filtering; wider/taller screens expand the view (UI anchors adapt;
  checked at 16:9, 16:10, 1366x768, 4:3 and 2:1 by `--ui`).
- People are 16x32 frames (bodies 24 px tall: chibi proportions, head about half), four facings, two-step walk.
- Battle creatures are 80x80 sprites (bodies 40-80 px); yours are seen from behind, the foe from the front; both
  are mirrored so they face each other across the stage. Party/journal icons are 24x24.

## Palette (`art/palette.py`, 64 colours)
Warm plum inks instead of black, cream paper, six greens, earth and wood, water and sky, fire and sun, flowers,
violet, stone, teal, skin, and the **withered** family (dry olive-greys and mud). Every world colour has a
withered twin (`WITHER`), which is how the healing world is drawn: the same art, drained. Every sprite pixel is
in the palette (`tools/check_art.py`); UI uses palette names only.

## Sprites
- Light from the upper left: each part is cel shaded (lit rim upper-left, shadow band lower-right, a contour
  where it overlaps another part), with a coloured outer outline (the darkest tone of what it touches).
- Faces: big friendly eyes with a cream glint, small blush. Silhouettes first: every creature has one clear
  shape (moss blanket, flame tail, droplet curl, thistle crown, rain cloud, stone coat, dandelion puff, ember wings).
- Buildings: plaster walls on a stone footing, tiled roofs with eaves, doors and windows on the wall line,
  window boxes with flowers. Fences join to their neighbours. Trees stand in whole 2x2 blocks.
- Terrain joins seamlessly: path and water are autotiled from 8x8 quadrants (outer corners, edges, inner corners);
  grass varies by a fixed hash, never random per load.

## UI
- Pixelify Sans 11 px for text, Silkscreen 8 px for small capitals (labels, stats). Both OFL (`game/fonts`).
- Panels: cream paper, 1 px plum-ink border, 3 px corners; selection is an amber pointer, highlight cards get an
  ember border. Titles sit in dark tabs above the sheet. Nothing overlaps or leaves its panel (`--ui`).
- The battle stage: foe on the upper left pad with its card upper right; yours lower right with its card left;
  messages bottom left, commands bottom right. The timing ring is drawn over the target: a cream target circle,
  an ink-edged coloured ring shrinking onto it (amber = strike, blue = brace, rose = gentle).

## Sound
Chiptune made in code: pulse lead with a soft echo, pulse arpeggios, triangle bass, noise drums. Cheerful town,
bright route, hushed grove, driving battle, gentle title. Effects are short and soft.
