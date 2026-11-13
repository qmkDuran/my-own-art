# Cozy Night Town: notes

## The game (the vision)
**Defend the town at night, run your café by day.** A survivor-roguelite with a cozy heart:

1. **Night: defend.** Spooky-cute creatures drift in from the fog toward the town's lamps (sheet ghosts with lantern
   eyes, waddling pumpkin heads, lantern moths, shadow cats, skeleton crows, mushroom imps, scarecrows; the boss
   is the Gloom King, a cloaked shadow with a crown of candles). Your lantern magic fires on its own while you move
   (Vampire Survivors style), you pick level-up upgrades mid-run, and you relight lamps the creatures snuff out.
   Defeated creatures pop into sparkles and drop food ingredients (pumpkin goo, moth dust, ghost-pepper wisps,
   moonberries, bat-wing toffee). Losing is gentle: you wake up at the café and keep some ingredients.
2. **Between nights: the café.** The bakery becomes your café: cook recipes from the night's ingredients, serve
   the townsfolk (emote bubbles, expression portraits, little chats), earn coins, unlock recipes, make friends.
3. **Spend:** gear, permanent skills, café upgrades and pre-fight recipe buffs. Then the next night is harder.

There are only two activities, **defending** and **the café**. Nothing else (no farming, capture, fishing or
building) unless the core loop proves fun. The tone is a Halloween storybook (Luigi's Mansion, Over the Garden Wall,
Plants vs Zombies): never horror and never gore.

**Order of work:** (1) the town mood piece (this step, done); (2) one defence-night test in these streets (waves
from the fog, auto-firing lantern magic, about 8 upgrades, 3 creature types plus a mini boss, ingredient drops, a run
of 8 to 10 minutes, snuffed lamps to relight); (3) the café in the bakery (3 recipes, 2 or 3 customers with emotes
and portraits, coins, one upgrade shop). The 700-credit cap covers steps 1 to 3.

## Step 1: the town mood piece
A crooked storybook town, always at night. It has a cobbled square with a fountain, a big tree, a clock tower, a
bakery and a market stall; Lamp Street running west (it ends at a house and a town wall); a canal with a stone
bridge and a ginger cat on the canal wall; Lantern Alley running east, lit by wall lanterns; and a long flight of
steps up to an overlook terrace looking west down the canal. The player is a lamplighter apprentice with a hand
lantern. The baker chats at her stall and with the old man, the old man sits on his bench and strolls to the
fountain, and the child runs around the fountain and waves at the cat.

### Lighting (the star)
- **Renderer: Forward+** for volumetric fog, glow, SSR and SSAO. It renders here under xvfb through Vulkan on Mesa
  lavapipe (installed `mesa-vulkan-drivers` for the stills); `--rendering-driver opengl3` would force the
  Compatibility renderer, which has no volumetric fog. On a Windows PC Forward+ runs on any Vulkan/D3D12 GPU.
  `rendering_method.mobile` is Mobile, and Godot falls back to Compatibility on very old GPUs.
- **Moonlight:** a cool blue directional light with soft PCSS-style shadows (angular size 2 degrees, 4 splits to 70 m).
  The sky shader puts the moon disc and halo exactly in the light's direction.
- **Sky:** a custom shader with a deep blue gradient, a warm glow over the rooftops, twinkling hashed stars, the
  moon, and thin drifting clouds that thicken in the rain.
- **Warm lights:** 17 street lamps and 6 wall lanterns (omni lights with a small blooming flame and a gentle
  flicker), plus one or two small window lights in front of every street-facing house.
- **Glowing windows:** the Meshy textures have warm painted windows. The asset shader turns pixels in a warm
  hue/brightness/saturation window into emission, so windows and lantern glass glow and bloom with no extra
  textures or credits.
- **Light budget:** only the 5 lamps nearest the camera cast shadows (re-chosen 2.5 times a second); every light
  fades out past 55 to 70 m. The player's lantern always casts shadows.
- **Fog:** thin exponential distance fog with height falloff, volumetric fog (light shafts and halos round every
  lamp), and a denser low volumetric fog layer (a FogVolume) hugging the streets.
- **Wet cobbles:** a procedural cobble shader (Voronoi stones, mortar, bump) with a global `wetness` value. Wet
  stones darken and turn glossy, and noise-shaped puddles become near-mirrors (SSR plus 4 box-projected reflection
  probes captured once, over the canal, the square and Lamp Street). Rain adds ripple rings in the puddles.
- **Canal and fountain water:** a dark glassy water shader with slow waves.
- **Glow** (AgX tone mapping, screen-blend bloom) and a **warm/cool colour grade**: a per-channel curve that lifts
  the shadows towards blue and tints the highlights warm, plus a touch of contrast and saturation.
- **Particles:** firefly swarms over the square, canal, alley and overlook; dust motes that use a lit material,
  so they only show where lamplight hits them; the fountain's spill curtain.
- **Rain (R):** rain streaks around the camera, wetness rising from 0.35 to 0.95, thicker fog, a dimmer moon,
  more clouds, and rain sound fading in.
- **The player** gets a soft warm front fill and rim light from their lantern. These light only the player's own
  meshes, through a render layer, so the face always reads.

### Sound
All procedural (synthesised into short loops at start, no audio files): crickets, the fountain's trickle (3D, at
the fountain), a music-box lullaby from an upstairs window on Lamp Street (3D), and rain. No CC0 downloads, so
there is no CREDITS.md.

### Asset pipeline (Meshy)
- **Budget guard:** `scratchpad/meshy_town/meshy_guard.py` (budget.json starts at 8200, TEST_CAP 500, FLOOR 7650).
  Every paid call goes through `paid_post()` with its price from the pricing doc, and every call is logged in
  `spend_log.jsonl`. I measured first: one concept image cost exactly 6, and the first prop (image 3 plus mesh 15)
  cost exactly 18.
- **Style lock:** one style string in every prompt. I made 3 concept images (`nano-banana-2`): the night town, the
  lamplighter and a daylight asset style sheet.
- **Props and buildings:** image-to-image (`nano-banana-2-lite`, 3 credits) with the asset sheet as the style
  reference gives a clean, evenly lit picture of one object. Then image-to-3D with `meshy-t2.5` geometry (smart
  topology, 2,500 to 12,000 faces) and `meshy-n1` stylised texture (15 credits). I skipped the `meshy-6` emission
  texture (twice the price): the shader-made window glow does the same job for free.
- **Characters:** an image-to-image from the lamplighter concept (6 credits), then image-to-3D in A-pose (15),
  rigging (5, which also returns free walk and run clips) and library animations (3 each): player idle; baker
  idle, talk, sit; old man dozing idle, sit, talk; child idle, wave.
- `tools/shrink_glb.py` re-encodes the embedded textures as JPEG (1024 px for props and characters, 2048 px for
  buildings), and `tools/merge_clips.py` merges each character's clips into one GLB. The repo assets total 16 MB.
  The full list, with prompts and costs, is in `game/assets/meshy/ASSETS.md`.
- **Credits spent: 437 of the 500 cap** (balance 8200 to 7763): 18 on concepts, 198 on 11 props, 90 on 5
  buildings, 131 on 4 characters. No placeholders were needed. The new cap for steps 1 to 3 is 700 (floor 7450).

### Code
Typed GDScript in feature folders; each script has one job; all numbers are in `data/*.json`. See CODE_STYLE.md.
`tools/run_all.sh` runs the lint, a parse check and a headless smoke test (town built, shadow budget, walk/run/idle
clips, townsfolk routines, rain wets the town). `tools/shoot.sh` takes the review stills.

### Weak spots (honest)
- **Performance is untested on real hardware.** The stills were rendered on a CPU rasteriser (lavapipe), so I have
  no frame times. Volumetric fog, SSR, SSAO and several dozen lights should suit a mid-range GPU (Forward+ clusters the
  lights, and only 6 cast shadows), but if it struggles, lower the volumetric fog volume size in project settings
  or turn SSAO off in `lighting.json`.
- **Collisions are boxes.** Houses use shrunk bounding boxes, plus an invisible wall behind each row; the bridge deck
  is two ramps; the steps are one ramp. Walkable, but not exact: you can stand slightly "inside" an overhang.
- **Townsfolk walk straight lines** between hand-placed points (no navmesh), and they don't react to the player yet
  (dialogue comes with the café step).
- **The sit pose** is lifted by hand onto the bench; it may sink or float slightly as the clip breathes.
- **The cat is a still model** with code breathing and turning (no rig).
- **Some backdrop houses** at the far edges can look flat through gaps; the street ends are now closed by
  houses and town walls.
- **The window glow is colour-keyed**, so a few warm-painted non-window details (a door lamp, an orange cloth) also
  glow faintly.
- **The tree is unlit and dark** when seen from inside the square at night (silhouette framing).
