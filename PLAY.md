# Cozy Night Town: how to play

## Run it on Windows
1. Clone the branch: `git clone -b cozy-night-town <repo url>` (or `git fetch` and `git checkout cozy-night-town`).
2. Install **Godot 4.7.2** (the standard build; .NET is not needed) from godotengine.org.
3. Open Godot, choose **Import**, and pick `game/project.godot`. The first import of the Meshy models takes a minute.
4. Press **F5** (or the Play button).

The project uses the **Forward+** renderer (volumetric fog, glow and screen-space reflections), which needs a
Vulkan or Direct3D 12 GPU. Any GPU from the last 8 years or so is fine. If your PC can't run Forward+, Godot falls back
to Compatibility on its own: it still runs, but without volumetric fog or screen-space reflections.

## Controls
### Moving about
| Key | What it does |
| --- | --- |
| W A S D / arrow keys | walk (relative to the camera) |
| Shift (hold) | run |
| Space | jump |
| Mouse | look around (click the window to capture the mouse) |
| T | toggle rain (rain falls, puddles grow and shine, the fog thickens, rain sound fades in) |
| G | graphics: Low / Medium / High (saved) |
| F | frame-rate cap: 30 / 60 / 120 / uncapped (default 60, saved) |
| F9 | VSync on/off (default on, saved) |
| F1 | fly mode: a free camera (WASD flies where you look, Space up, Ctrl or C down, Shift faster, no collision, HUD hidden); F1 again puts you back with the player where you left them |
| F3 | performance overlay: fps, frame time with a small graph, CPU/GPU frame time, draw calls, graphics tier, fps cap and resolution |
| F10 | Windows renderer: Vulkan (default) or Direct3D 12, used from the next start (some GPU overlays, like NVIDIA's, hook Direct3D 12 more reliably) |
| F11 | fullscreen / windowed (starts fullscreen at your display's resolution) |
| H | show the controls hint again |
| Esc | free the mouse |

### The Lamplighter's kit (fighting)
Aim with the centred crosshair; the camera tightens over your shoulder while you fight and you turn to face where
you aim.

| Key | Ability | What it does |
| --- | --- | --- |
| Left mouse (hold) | **Lantern bolt** (primary) | a rapid aimed flame bolt; hits pop with a star, a number and a tick on the crosshair |
| Right mouse (hold, release) | **Heavy beam** | hold to charge (a glow builds at your lantern, a chime when full), let go to fire a beam that pierces everything in line; a full charge hits about 3x harder than a quick tap. Short cooldown |
| Q (hold, release) | **Lantern bomb** | hold to see the arc and the blast ring, let go to throw; a burst of teal spirit-fire. 5 s cooldown |
| E | **Ward** | a honeycomb bubble for about 3 s that stops enemy shots (not ground attacks: step out of those). 8 s cooldown |
| V | **Blink** | a quick dash; nothing can hurt you mid-blink |
| R | **Sunrise** (super) | when the sun icon's ring is full (it fills as you deal damage): you rise, a giant lantern sun forms overhead and rains fire over the area |
| Tab | lock on | the camera follows the enemy nearest the crosshair; Tab again lets go |

The HUD shows your health (top left), the objective, the boss's health (top centre) and your abilities (bottom
right: a dark sweep while one cools down, a ring for the heavy's charge and the Sunrise meter).

## Keeping the GPU cool
The game caps itself at 60 fps with VSync on by default, so a strong GPU doesn't run flat out. If your GPU still
runs hot, press G for Low: no volumetric fog, reflections or ambient occlusion, smaller shadow maps, one
shadowed lamp, fewer particles, and rendering at 77% with FSR upscaling.

## Where to go
The town is open: walk between the houses and out onto the meadow, all the way to the dense trees at the edge of
the world. Only the canal (and the trees at the far edge) stop you; cross the canal by the bridge.

- **The square:** the fountain, the big tree, the clock tower and the bakery's glowing window. The baker chats by her
  stall, the old man sits on his bench, and the child runs around the fountain and waves at the cat.
- **Lamp Street:** walk west from the square (past the signpost). There's a music box playing in an upstairs window.
- **The canal:** south of the square. Cross the stone bridge; the ginger cat sits on the canal wall beside it.
- **Lantern Alley:** east from the square, lit by wall lanterns.
- **The overlook:** from the south bank, walk east along the canal and up the long steps to the terrace for the view.

## The Gloomwood (the first mission)
Walk east out of town across the meadow to the **stone gate in the tree line** (follow the dirt path from Lantern
Alley). Walking through the gate starts the mission: clear the Gloomwood and break the Gloom King's spell. The
music turns from the town theme to an exploring tune, and to the fight music whenever enemies are on you.

1. **The Mushroom Glade:** a pack of mushroom imps and pumpkin heads rushes you (they crouch for a moment before
   they lunge), with a lantern moth shooting from behind. Beat them and a second pack comes. Clearing the glade
   relights its lanterns.
2. **The Ruins** on the rise: lantern moths keep their distance and charge glowing shots (a violet glow and a
   chime warn you about 0.75 s ahead: blink sideways or raise your ward). The **scarecrow knight** guards the
   ruins behind a moonlit shield: bolts barely scratch it, the heavy beam and the bomb crack it fast. When it
   breaks he staggers and can be hurt. Watch for his ground slam (a circle on the ground fills up first).
3. **The Gloom King** in his ring of standing stones (the ring closes behind you): candle circles under your feet,
   a gloom wave along a line, a fan of shots, and at half health he roars, his attacks quicken, a nova bursts
   around him and he keeps summoning ghosts. Every attack is drawn on the ground (or glows) for about 0.8 s
   before it lands.

Beat him and the mission is complete; after a moment your lantern carries you home to the town side of the gate.
If you faint, you wake there too, and the woods reset for another try. Your health comes back on its own a few
seconds after you were last hit.

## For developers
- `tools/run_all.sh`: lint, parse check, the headless smoke test (town, posture, tools, UI layout, the combat kit,
  the enemies and their telegraphs, the mission flow and music) and the collision/clipping suite, about 2 minutes.
  Prints `ALL CHECKS PASS`.
- `tools/run_all.sh --long`: adds the 3-minute walk sweep, the rendered performance probe in the busiest fight and
  the brightness/readability check on town and combat stills (needs `xvfb-run` and Vulkan), about 25 minutes.
- `tools/shoot.sh OUT_DIR [name ...]`: review stills, town shots or combat stages (overview, primary, heavy, bomb,
  ward, swarm, elite_break, boss_telegraph, super, busy, contrast); needs `xvfb-run` and a Vulkan driver.
