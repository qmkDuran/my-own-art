# Cozy Night Town: notes

> **Superseded:** the game's direction is now **VISION.md** ("Zelda meets Destiny": missions out into regions,
> aimed combat, puzzles, class and skill trees, loot). The café / survivor-roguelite vision below is kept for
> history; the defence night and its auto-fire magic will be replaced by the aimed combat core.

## The game (the original vision, superseded)
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

**Order of work:** (1) the town mood piece (done); (2) one defence-night test in these streets (waves
from the fog, auto-firing lantern magic, about 8 upgrades, 3 creature types plus a mini boss, ingredient drops, a run
of 8 to 10 minutes, snuffed lamps to relight); (3) the café in the bakery (3 recipes, 2 or 3 customers with emotes
and portraits, coins, one upgrade shop). The 700-credit cap covers steps 1 to 3.

## Polish fixes after the first playtest
- **Walk:** feet slid ("goat feet"): the game assumed the walk clip covers 1.6 m/s, but a planted foot only travels
  about 1.2. Each character now measures its own clips' foot speed when it loads and plays them at body speed /
  foot speed. A smoke check guards it, and `tools/` has a side-view walk sheet (`--walk-sheet`).
- **Dash:** now a Shift tap, a 0.2 s ease-out burst that stays grounded, with a dust puff.
- **Jump:** Space. It uses Meshy's "Regular Jump" (3 credits) started from its take-off, with the clip's own rise
  capped so physics lifts the body. Coyote time 0.12 s, a jump buffer, heavier fall gravity, and a landing puff.
- **Bridge flicker:** the canal walls' tops were coplanar with the street (z-fighting). They now sit 3 cm lower,
  and the parapet gap matches the bridge. A layout check fails on any visible box top lying on the street plane.
- **Gaps between houses:** brick garden walls now close each gap between two houses' measured ground floors. The
  quay ends are closed by a hedge on a low wall, and the remaining edge walls show a faint warm mist veil within
  3 m.
- **GPU heat:** a 60 fps cap and VSync are on by default (F / V change them; saved), fullscreen runs at the
  display's resolution (F11), and Low is much lighter (no volumetric fog, reflections or AO, 1024 px shadow maps,
  one shadowed lamp, no MSAA, FSR at 77%).
- **Seam line on characters:** every character has a UV seam down its front centre. Downscaling and mipmaps bled
  the dark texture gutter into it. `tools/shrink_glb.py` now pads colours outward from the UV islands before
  shrinking, and all Meshy assets were rebuilt.
- **Outskirts:** a meadow frames the town, a ring of 110 Meshy trees and 520 simple trees (MultiMeshes), five
  hills, a lake to the south and 44 cottage lights. The first version's meadow covered the canal and hid the
  water; it is now four planes around the town.
- **Canal fish:** 26 softly glowing koi (teal, amber, lilac) swim along the canal by the square and bridge.

## Second playtest fixes
- **Posture:** the old Meshy "Idle" (action 0) stood with bent knees and splayed legs, and the free rig walk leaned
  back. The player now uses library "Idle 9" (249) and "Casual Walk" (30), 9 credits with one alternative idle
  tried; side-view stills show straight legs and an upright walk.
- **Open town:** fewer houses (each row placed once, in order, with 3 to 7 m walkable gaps), no backdrop rows, no
  brick gap walls, gap fillers or invisible row walls, no hedges, no mist veil. You can walk between houses and out
  onto the meadow (now with a floor) up to an invisible ring hidden in a dense band of 260 trees at the world's
  edge. Wall lanterns are only placed where a house wall is behind them.
- **Canal:** invisible walls on the parapets, 3 m tall, so nobody walks or jumps in; the bridge stays open. The
  collision suite has hopping probes at the canal's edges.
- **Lamps:** the small glowing ball under each lamp is gone. The light sits inside the lamp's glass (which glows
  through the asset shader), and the lamp models don't cast shadows, so the glass doesn't block its own light.
- **Props:** a bench's collision box is taller than any jump (its visible top is the backrest, so a box that high
  left you floating over the seat). Hopping probes at every prop check that wherever one ends up standing on a
  prop, its feet are within 5 cm of the visible top; the player and townsfolk stand within 5 cm of the floor.
- **Benches and sitting:** a sit step names the bench near a spot, and the seat is worked out from where that bench
  really stands; with no bench there, the sit is skipped. The suite checks every sitter: a bench under them, hips
  within 5 cm of the seat (plus the body's own clearance), facing the bench's way.
- **Sound:** the cricket loop is gone; now and then one cricket chirps quietly somewhere 14 to 32 m away (every 8
  to 20 s). Footsteps for the player and townsfolk, synthesised per surface (cobbles, the bridge, the meadow's
  grass, a few variants each with random pitch and level), are played at the foot-plant moments measured from
  each walk and run clip. Floors carry their surface as metadata.
- **Controls:** V dashes (Shift only runs), F9 VSync, F1 fly mode, F3 performance overlay, F10 Windows renderer
  (Vulkan or Direct3D 12 via override.cfg, from the next start).

## The glow rule: "Luigi's Mansion, not LED headlights"
Every glow in the game is **soft, warm and diffuse**: a gentle halo that falls off smoothly and keeps its colour
(warm amber, candle orange, ghostly teal and green). There are no white-hot cores, hard star points or big
bloom smears.
- **Bloom:** the WorldEnvironment glow is wide and gentle (levels 3 to 6 with falling weights, intensity 0.5, HDR
  threshold 1.4, no bloom term), so only genuinely bright light sources bloom.
- **Small glows** (lamp flames, fireflies, candles, bolts) all come from `SoftGlow`: a small core in the light's
  own saturated colour with emission capped at 1.6, plus a wide billboard halo with a smooth falloff.
- **Particles:** fireflies, sparkles and pickups are soft round sprites, additive but capped. Pickups are lit,
  with only a faint glow of their own, so they read as things to pick up, not as lights.
- **Ghosts:** about one in five sheet ghosts carries a small, dim amber light from its lantern eyes, so it softly
  lights its surroundings. The Gloom King has a soft purple glow.
- **Magic near the camera:** anything glowing that comes within about 2 to 3 m of the camera shrinks away.
- **The readability check enforces it:** in the busy-wave stills (defence, boss, busy) at most 1.5% of the frame
  may be above 0.85 luminance, every still keeps near-white pixels under 0.5%, and the player and creatures must
  still stand out from the effects.

## Lantern Flare showcase effect (the starter attack)
The idea is shape and motion over brightness, in a warm amber palette, borrowing principles from Genshin-style
effects (layered colour cores, crisp pop shapes, a ground ring, anticipation, snappy timing, a lingering afterglow)
with original designs only:
- **Wind-up** (0.14 s): warm motes swirl in to the lantern, with a small halo swell and a brief soft light.
- **Flight** (about 0.3 s):
  - A teardrop flame (`vfx_flame.gdshader`: amber core, orange, then a deep red, fading edge, with flicker and
    wobble) inside a soft halo.
  - The Blender spiral ribbon spinning behind it with a scrolling glow (or a camera-facing ribbon trail in the
    pure-Godot version).
  - Embers shed along the way, and a small moving light.
- **Impact** (on the creature's near side):
  - A six-point **star pop** that snaps open, bright but coloured.
  - A soft light pop on the cobbles.
  - The Blender **swirl ring** expanding with a scrolling, dissolving edge (or an SDF ring).
  - The Blender **ember flipbook** plus a few loose embers, and warm **smoke-puff** flipbooks.
  - Hit-stop of 3 frames on kills or strong hits only, and a tiny camera nudge on crits only (12% crit chance,
    x2 damage).
  - Sounds synthesised in code: a whoosh on cast, a warm chime pop and a crackle tail.
- **Aftermath:** a glowing ember decal on the stones that cools over 1.5 s, with drifting embers.
- **On the creature:** a squash and a knockback on each hit. On defeat it dissolves into light (noise dissolve
  with a warm edge), pops into sparkles, and the drops appear there.
- **Reusable pieces** (`game/vfx/`, all configured in `data/vfx.json`): WindupGather, FlameWisp, RibbonTrail,
  ImpactBurst, StarPop, EmberMark, ParticleBursts (Godot sprites or flipbooks), EffectLight, Dissolve, HitFeel,
  VfxQuota and VfxKit.
- **Graphics tiers:** effect lights are capped per tier (2, 4 or 8 at once; a light with no free slot is simply
  skipped), trails are off on Low, and particle counts scale with density.
- **The NaN bug:** a NaN in the first ribbon shader (`pow` of a slightly negative number at the mesh edge) made the
  effect meshes bloom into white blobs; it is clamped now.
- **Blender-assisted vs pure Godot:** `data/vfx.json` "source" switches between them (Blender is the default).
  Asset cost of the Blender version:

  | Asset | Size |
  | --- | --- |
  | Ember flipbook (1000 px, 5x5 frames) | 272 KB |
  | Smoke flipbook | 340 KB |
  | Swirl ring mesh (130 vertices) | 6 KB |
  | Spiral ribbon mesh | 10 KB |
  | **Total** | **about 630 KB** |

  Runtime cost is a handful of extra draw calls per impact (a flipbook quad instead of sprite particles, one
  ring mesh), about the same as the pure-Godot version. The rendered perf probe with flares firing during a
  150-creature wave stays within its budgets (see below).
- **Reproducing the assets:** `blender -b -P tools/vfx/make_flipbooks.py -- OUT 25 200`, then
  `python3 tools/vfx/pack_flipbook.py OUT ember_burst game/assets/vfx/ember_burst.png 5` (and the same for
  smoke_puff), and `blender -b -P tools/vfx/make_meshes.py -- game/assets/vfx`.
- **Review clips:** used only for my own timing review (Godot's movie writer to a PNG sequence), then deleted.
  Only stills are delivered.

## Step 2: the defence-night test (N in game)
- **Loop:** the townsfolk go indoors and creatures drift in from the fog for 9 minutes. The pace and mix are set
  by `data/defence.json`: a trickle that thickens, plus four surges. The **Gloom King** comes at 7:00. Win by
  beating him or surviving until dawn; fainting wakes you at the café door with half the ingredients.
- **Creatures** (Meshy, static, moved in code, 18 credits each):
  - **Sheet ghost** (floats, through walls).
  - **Pumpkin head** (hops, solid: slides around houses).
  - **Lantern moth** (flies to the nearest lit lamp and snuffs it).
  - **Gloom King:** a mini boss with a purple glow so his dark cloak reads. He summons ghosts and snuffs lamps
    near him.

  The rule is deliberate: spirits drift through walls, while walkers collide and only spawn where they can reach
  you (a walkable-grid flood fill).
- **Lamps:** snuffed lamps go dark (the area really dims). Stand by one for 1.2 s to relight it. Near a lit lamp
  you slowly heal.
- **Lantern magic** (`data/skills.json`, level = base + per_level x (level - 1), scaled by passives):
  - **Attacks:** Lantern Flare (starter), Firefly Swarm, Candle Ring, Moonbeam, Bell Chime.
  - **Passives:** Brighter Wick, Warm Scarf, Quick Boots, Steady Hands (maxing at 3).
  - **Combo:** Star Swarm (Firefly Swarm 5 + Brighter Wick 3).
  - **Level-ups:** each offers 3 cards; magic you already own is 3x likelier to be offered, so builds deepen.
- **Drops:** light motes (experience) and ingredients, pulled in within your pickup reach. Lanterns, sparkles
  and drops all glow and bloom; nothing is gory.
- **Pantry:** ingredients saved to `user://pantry.json` for the café step.
- **Dodge:** Space (a short dash with no damage taken).
- **Not built yet** (from the approved list): Wisp Lanterns, Sparkler Trail, Teapot Turret; Lucky Charm and
  Cinnamon Magnet; the Chandelier and Golden Lantern combos.

### Tests (what each one caught)
`tools/run_all.sh` (about 1 minute) runs:
- the lint and a parse check;
- the smoke test: the town, graphics tiers, the defence night and UI layout;
- the collision suite.

`tools/run_all.sh --long` adds:
- a 3-minute walk sweep;
- the balance bot;
- the stability run;
- the rendered perf probe;
- the readability check.

Tests were added only for features that exist; save/load and the end-to-end loop come with the café.
- **Collision and clipping** (`--collision`, 9 s):
  - **Walls hold:** about 650 runs at full speed into every solid box from 8 directions.
  - **Walk-the-town sweep:** 40 bots doing random walks (20 s by default, 180 s with --long).
  - **Crossings:** the bridge and the steps, both ways.
  - **Camera probes, seat pose** (the old man's hips are 0.23 m above the bench seat) and **NPC routes.**
  - **Hoppers stay out:** a pumpkin chasing the player through a row of houses never gets inside one.
  - **Spawn reachability.**
  - **Layout checks:** collision boxes against the visible mesh, interpenetration, and floating or sinking props.

  It **caught and I fixed:**
  - The bridge deck's collision ran along the wrong axis, so you fell into the canal.
  - Two terrace lamps, a bench and barrels were buried in the terrace (y=0 instead of 6).
  - Two corner houses I had added sat inside their neighbours.
  - Barrels were inside a lamp post.
  - The baker's and child's routes went through the market stall, a bench and the fountain.
  - The town leaked at several corners and both quay ends (bots walked out into the void).
  - Bots could walk under the overlook stairs and wedge under the sloping railing.
  - Bots could squeeze between houses and get stuck in pockets.
  - The house collision boxes were shrunk bounding boxes. They are now **measured from each mesh's vertices at
    walking height** (stray 2% trimmed), so what you bump into is what you see. The worst empty box edge is
    1.0 m (the bakery's sign corner).
  - The town is now sealed with invisible walls at its edges and gap-fillers between neighbouring houses.
- **Performance** (headless proxies in the smoke test; rendered `--perf` probe in --long). The busiest spot is the
  square in the rain with 150 creatures and all magic running:

  | Tier | Draw calls | Primitives | Shadowed lights | Particles |
  | --- | --- | --- | --- | --- |
  | High | 437 | 2.7 M | 6 | 6,200 |
  | Medium | 383 | 2.5 M | 4 | 3,900 |
  | Low | 232 | 1.8 M | 2 | 2,100 |

  All within the budgets in `data/perf.json`, and each tier is lighter than the one above. Absolute fps is
  meaningless on lavapipe (it reads 1), so it is printed for reference only.
- **Graphics setting (G):** Low, Medium and High switch volumetric fog, SSR, SSAO, the number of shadowed lamps,
  the moon's shadow splits and particle density.
- **Readability** (`tools/readability.py` on the stills):
  - **Mean luminance:** 0.17 to 0.34 against a target of 0.10 to 0.45.
  - **Clipping:** 0% crushed blacks and 0% blown whites. The fog lifts the darks: moody, never muddy.
  - **Creatures:** they cover 2.8% of the defence frame at a mean contrast of 0.15 against the town and fog
    behind them (target 0.10).
- **UI layout:** the town HUD, the night HUD (with a full bag and the boss bar) and the level-up cards, at the
  logical sizes 1280x720 (every 16:9 screen), 1280x800 (16:10) and 1707x720 (21:9). It caught:
  - The start banner ran off screen.
  - The timer overlapped the XP bar on 16:10 and 21:9.
  - The HUDs froze behind the level-up pause.
- **Stability** (4 shortened nights back to back): it caught a real leak, about 65 sparkle-burst particle
  systems piling up per night (their `finished` signal never fires on some renderers). Now nodes (1,393 to
  1,394), orphans (0), particle systems (7) and memory (200.7 to 200.8 MB) stay flat.
- **Balance bot** (it kites, dodges, relights lamps when safe, and picks by strategy): it caught orphaned light
  bolts erroring after a night reset (fixed). Results by tuning pass:
  - **First pass:** 2 of 8 nights won. Late-game deaths, level 15 at best, and the combo was unreachable.
  - **After a gentler XP curve, softer late waves and fewer boss summons:** 6 of 8 won.
  - **With owned-magic weighting and passives maxing at 3:** 5 to 7 of 8 won, depending on the run.
  - **Every build:** the passives-first build faints at about 170 to 190 s (expected).
  - **Win timing:** wins come from beating the boss at about 450 to 500 s.
  - **Star Swarm:** the combo-focused bot reaches it in 2 of 3 nights. It isn't a clear power spike yet.
  - **Outlier flags:** on 8 nights these come from small samples (for example "lantern_flare: 0% without" is the
    single passives-only night).

### Step 2 weak spots
- **The bot is not a person.** Human kiting is better, so real difficulty is probably lower than the bot's
  results; the late game (the boss plus summons) is where it dies.
- **Spirits pass through walls by design**, which can feel unfair in tight alleys.
- **Creatures have no animation rig:** the code bob, hop, flutter and a hit squash give them life.
- **Moonbeam and Firefly glows bloom strongly** near the camera.
- **Star Swarm isn't clearly stronger** than the Firefly Swarm it replaces.

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
- **Credits spent: 437 for step 1** (balance 8200 to 7763): 18 on concepts, 198 on 11 props, 90 on 5 buildings,
  131 on 4 characters. No placeholders were needed. **Step 2 added 72** (4 creatures at 18 each), so the total
  is **509 of the 700 cap** (floor 7450). That leaves 191 for the café.

### Code
Typed GDScript in feature folders; each script has one job; all numbers are in `data/*.json`. See CODE_STYLE.md.
`tools/run_all.sh` runs the lint, a parse check and a headless smoke test (town built, shadow budget, walk/run/idle
clips, townsfolk routines, rain wets the town). `tools/shoot.sh` takes the review stills.

### Weak spots (honest)
- **Performance is untested on real hardware.** The stills were rendered on a CPU rasteriser (lavapipe), so I have
  no frame times. Volumetric fog, SSR, SSAO and several dozen lights should suit a mid-range GPU (Forward+ clusters the
  lights, and only 6 cast shadows), but if it struggles, lower the volumetric fog volume size in project settings
  or turn SSAO off in `lighting.json`.
- **Collisions are boxes** measured from each mesh at walking height (see the collision suite above). The bridge
  deck is two ramps and the steps are one ramp; upper-floor overhangs have no collision (you walk under them).
- **Townsfolk walk straight lines** between hand-placed points (no navmesh), and they don't react to the player yet
  (dialogue comes with the café step).
- **The sit pose** is lifted by hand onto the bench; it may sink or float slightly as the clip breathes.
- **The cat is a still model** with code breathing and turning (no rig).
- **Some backdrop houses** at the far edges can look flat through gaps; the street ends are now closed by
  houses and town walls.
- **The window glow is colour-keyed**, so a few warm-painted non-window details (a door lamp, an orange cloth) also
  glow faintly.
- **The tree is unlit and dark** when seen from inside the square at night (silhouette framing).
