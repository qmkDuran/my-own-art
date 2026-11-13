# Cozy Night Town: notes

> **Superseded:** the game's direction is now **VISION.md** ("Zelda meets Destiny": missions out into regions,
> aimed combat, puzzles, class and skill trees, loot). The café / survivor-roguelite vision below is kept for
> history; the defence night and its auto-fire magic were replaced by the aimed combat core (next section).

## Step 1 of VISION.md: the combat core
### Where
The **Gloomwood**, east of town beyond a stone **town gate** set into the tree line (the world's edge ring is open
there). A dirt path leads from Lantern Alley over the meadow to the gate and on through the woods: the **Mushroom
Glade** (rocks and fallen logs for cover), the **Ruins** on a 1.6 m rise with ramps, broken walls and two Meshy
ruined arches, and the Gloom King's **ring of standing stones** with violet runes. The woods' edge is invisible
walls behind three rows of trees (a Meshy front row, simple dark trees behind), no visible veil. Lanterns and
braziers of each encounter stay dark until it is cleared. All of it is data in `data/mission.json`.

### Flow (`Mission`, `Encounter`, `ArenaBarrier`)
Walking through the gate starts the mission (title and objective banners). Each encounter starts at its trigger
circle, brings its first wave and, when that is down to `wave_at` enemies, the next; clearing it relights its
lanterns. The boss's ring closes (invisible walls and a curtain of violet flame across the entrance) while he is
fought. Beating him completes the mission; after 5 s a fade carries you home to the town side of the gate.
Fainting fails it the same gentle way. Everything resets for another try.

### The Lamplighter's kit (`game/combat/`, numbers in `data/combat.json`, looks in `data/vfx.json` combat)
Over-the-shoulder aim with a centred crosshair: a ray from the screen centre to the first wall or enemy (enemies
are tested as balls a little larger than their bodies, so fair-looking hits count). Any attack holds a 1.4 s
"stance": the camera tightens (2.5 m, shoulder 0.62, fov 50) and the player turns to face the crosshair. Tab locks
on (the camera follows the enemy nearest the crosshair). Palette: warm amber and gold for the player's light and
fire, teal spirit-fire for the bomb, honey gold for the ward, moonlit blue for enemy shields, magenta-violet for
everything enemy.

| Ability | Tuning | Layers (wind-up, cast, travel, impact, afterglow) |
| --- | --- | --- |
| Lantern bolt (LMB) | 9 damage every 0.15 s (60 dps), 52 m/s, 10% crits x2 | muzzle star pop, pluck sound and camera kick; a flame wisp with ribbon trail and embers; star pop, light, ring, ember flipbook and smoke on the enemy's near side; ember scorch; damage number, crosshair hit marker, hit flash and squash |
| Heavy beam (RMB) | 22 to 130 damage, 0.18 to 0.45 m wide with the charge (1.1 s full; a tap counts as 20%), pierces, knockback 7, 0.8 s cooldown | an orb, a spinning swirl ring, motes pulled in and a light growing at the lantern, a rising hum and a chime when full; a glowing tube with racing bands, rings blown out along it, embers, lights at both ends; heavy impacts on every enemy hit; kick and a small shake |
| Lantern bomb (Q) | 75 damage in 4.2 m, knockback 9, 3 to 24 m throw, 5 s cooldown | a dotted teal arc and a blast ring while held; a spinning teal flame lantern on the arc; flash, swirl ring, hex dome, star pop, sparks, rising wisps, smoke, scorch; a boom |
| Ward (E) | 3.2 s, 1.4 m bubble, stops enemy shots, 8 s cooldown | a honeycomb bubble that pops open, ripples where a shot splashes, a warm light; the near side fades so it never fills the screen |
| Blink (V) | the 0.2 s grounded dash, no hurt while it lasts, 0.9 s cooldown | a warm streak and a star pop |
| Sunrise (R) | meter = 1,400 damage dealt; rise 1.3 m (0.5 s), the sun forms (1.1 s), 4.6 s of motes (one per 0.075 s, 34 damage in 2.6 m, 60% seek enemies in 12 m), a final 90-damage burst in 9 m | invulnerable while it plays; the camera pulls back to 7.5 m, the night warms to dawn (ambient, horizon glow, saturation), a boiling lantern sun with a turning crown of rays, a corona, a swirl ring, gathering motes and a big warm light; flame-wisp motes with impacts; a flare and collapse |

The **soft glow rule** still holds: every effect's colour lives in its glow (energies capped, additive colours kept
below white), and the beam, swirl rings and bubbles fade out close to the camera.

### Enemies (`game/enemies/`)
Static Meshy models moved by code, every one **solid** (a body on the ground that slides along walls, rocks and
ruins; floaters only float their model), with a role brain:

| Enemy | Role | Behaviour and telegraph |
| --- | --- | --- |
| Mushroom imp (new), pumpkin head, sheet ghost | swarmer | rush in packs; up close a 0.35 to 0.4 s crouch and a flicker, then a lunge that bites once; back off, repeat |
| Lantern moth | shooter | keeps 10 to 17 m away, drifts side to side; every 2.6 s (when it sees you) a 0.75 s violet charge and a chime, then a 13 m/s shot at where you are (dodge it or ward it) |
| Scarecrow knight (new) | elite | a moonlit shield (170) that takes 0.3x from bolts and 2.4x from the heavy and the bomb; the body can't be hurt until it breaks (shards, a flash, "BREAK!", a hit-stop), then it staggers 1.8 s; a ground slam with a 0.85 s circle telegraph |
| Gloom King | boss | 1,500 health; keeps 6 to 12 m away; phase one: candle circles (4, 0.9 s), a gloom wave along a line (0.8 s), a fan volley of 5 shots (0.7 s glow); at half health a 1.6 s invulnerable roar and a violet flare, then faster attacks (x0.75 rest), a nova around him (0.9 s, 7.5 m) and ghost adds every 13 s (up to 6) |

Telegraphs are ground shapes (vfx_telegraph shader): a soft magenta rim, a violet fill growing over the wind-up,
racing stripes, and a flash and violet flame burst when it lands; the player is hurt only if still inside.

### Music and sound
Music by state, crossfaded over 2.2 s in linear amplitude (`MusicDirector`, `data/music.json`): Kevin MacLeod's
"The Path of the Goblin King" in town, "Pippin the Hunchback" in the woods, "Hall of the Mountain King" while
enemies are engaged (2 dB louder for the boss). Every ability is a layered cue (`data/audio.json` cues): CC0
one-shots from rubberduck's "80 CC0 RPG SFX" mixed with code-made plucks, thumps, chimes, shimmers and swells,
with random pitch. Enemies get a warning chime on every wind-up, hurt and defeat squeaks, a roar on the phase
change. See CREDITS.md.

### Tests
`tools/run_all.sh` (about 2 minutes) now also runs:
- **SmokeCombat:** the primary fires, hits and keeps its fire rate; the meter fills from damage; the heavy's damage
  grows with its charge (a quick release 50, a full charge 130) and respects its cooldown; the bomb bursts exactly
  where its arc was previewed (0.000 m) and hurts what is there; the ward stops a shot (and the shot hurts without
  it); the blink dashes, can't be hurt and cools down; the Sunrise needs a full meter, fires, rains about 60
  motes that hurt, keeps the player safe and lands them again.
- **SmokeEnemies:** the shooter keeps its distance and every shot leaves 0.75 s after its warning; the boss's
  ground attacks resolve 0.8 to 0.9 s after they appear and his volley 0.7 s after its glow (all within 0.6 to
  0.95 s); the elite's shield shrugs off a bolt (170 to 167), breaks under a full heavy, then the body can be hurt;
  the boss turns to phase two at half health, can't be hurt while roaring and summons 4 ghosts.
- **SmokeMission:** the gate starts the mission, every encounter starts at its trigger and brings all its waves,
  clearing relights the lanterns, the ring closes for the boss and opens after, beating him completes the
  mission, the fade carries the player home and the woods reset; the music is town, explore, combat and boss in
  turn and crossfades cleanly; every music level and sound cue sits in a sane range and every sound file loads.
- **Collision:** the walk grid now covers the woods (119,000 cells); the sweep, the gate and both ruins ramps are
  crossed; enemies chasing the player through the cover never end up inside geometry; every mission spawn point is
  reachable.
- **UI layout:** the combat HUD and the performance overlay fit and don't overlap at 16:9, 16:10 and 21:9.
- `--long` adds the rendered perf probe in the busiest fight (the 60 fps cap on) and readability on combat stills.

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
- **Posture:** the old Meshy "Idle" (action 0) stood with bent knees and splayed legs; the player now uses
  library "Idle 9" (249) and "Casual Walk" (30) (9 credits). That alone wasn't enough: measured on the skeleton,
  the Meshy rigs have a lean baked into their bind pose (the player's spine 6 degrees back in the rest pose), so
  every clip played on them leaned back with the hips pushed forward. `PostureFix` (a SkeletonModifier3D) measures
  each standing clip at load (hips ahead of the mid-ankles, spine lean) and, every frame after the animation, moves
  the hips back over the ankles (the upper legs turned so the feet stay planted) and pitches the lowest spine bone
  upright. The old man's dozing idle is a stoop on purpose and is left alone. The smoke test measures the drawn
  skeleton (read as it finishes updating) for the player and every townsperson, in idle (cycle average) and at
  walk mid-stance:

  | Character, clip | Before: head / hips from mid-ankles, spine lean | After |
  | --- | --- | --- |
  | Player idle | 0.5 cm / 6 cm, -7.8 deg | 2.5 cm / 0.6 cm, -2.2 deg |
  | Player walk | 0.2 cm, -7.2 deg | 2.2 cm / 0.8 cm, -1.6 deg |
  | Baker idle | 8.0 cm, -7.6 deg | 1.4 cm / 0.1 cm, -2.0 deg |
  | Child idle | 6.9 cm, -9.5 deg | 2.3 cm / 0.0 cm, -2.8 deg |
  | Walks (baker, old man, child) | up to 4 cm, up to 2.8 deg | under 2.1 cm, under 2.3 deg |

  Limits: head and hips within 5 and 4 cm of the ankles, spine within 5 degrees.
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

## The defence night (removed)
The auto-fire defence night (step 2 of the old plan) was removed once the aimed combat core replaced it: its
creatures, lantern magic, level-up cards, HUD, data, smoke checks and the balance bot are gone. The Lantern Flare
effect pieces (FlameWisp, ImpactBurst, StarPop, EmberMark, Dissolve, HitFeel) live on in the new kit.

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
