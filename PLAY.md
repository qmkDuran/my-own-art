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
| Key | What it does |
| --- | --- |
| W A S D / arrow keys | walk (relative to the camera) |
| Shift (hold) | run |
| Shift (quick tap) | dash: a short, quick dodge with a puff of dust (creatures can't hurt you mid-dash) |
| Space | jump |
| Mouse | look around (click the window to capture the mouse) |
| R | toggle rain (rain falls, puddles grow and shine, the fog thickens, rain sound fades in) |
| N | start a **defence night** (see below) |
| 1 / 2 / 3 or click | pick a level-up card |
| G | graphics: Low / Medium / High |
| H | show the controls hint again |
| Esc | free the mouse |

## Where to go
- **The square:** the fountain, the big tree, the clock tower and the bakery's glowing window. The baker chats by her
  stall, the old man sits on his bench, and the child runs around the fountain and waves at the cat.
- **Lamp Street:** walk west from the square (past the signpost). There's a music box playing in an upstairs window.
- **The canal:** south of the square. Cross the stone bridge; the ginger cat sits on the canal wall beside it.
- **Lantern Alley:** east from the square, lit by wall lanterns.
- **The overlook:** from the south bank, walk east along the canal and up the long steps to the terrace for the view.

## The defence night (N)
The townsfolk go indoors and the spooky-cute creatures drift in from the fog for about 9 minutes:
- **Sheet ghosts** float straight at you (through walls: they're ghosts).
- **Pumpkin heads** hop after you along the streets. They're solid and walk around houses.
- **Lantern moths** fly for the nearest lit lamp and snuff it, so that part of town goes dark. Stand next to a
  snuffed lamp for a moment to relight it (a ring fills). Standing near a lit lamp slowly heals you.
- At 7:00 the **Gloom King** arrives. He summons ghosts and snuffs every lamp he passes. Beat him, or survive
  until dawn, to win.

Your lantern magic fires on its own; you move, dodge and choose. Defeated creatures pop into sparkles and drop
light motes (experience) and ingredients (Pumpkin Goo, Moth Dust, Ghost-Pepper Wisps, Moonberries, Bat-Wing
Toffee). Walk near them to collect them. Each level-up pauses the night and offers 3 cards:
- **Attacks:** Lantern Flare (the starter: bolts at the nearest creature), Firefly Swarm (orbiting zaps), Candle
  Ring (spinning candles up close), Moonbeam (beams at random spots), Bell Chime (a knock-back-and-stun pulse).
- **Passives:** Brighter Wick (area), Warm Scarf (health), Quick Boots (speed), Steady Hands (cooldown).
- **Combo:** max Firefly Swarm and Brighter Wick to unlock **Star Swarm**.

Fainting is gentle: you wake at the café door and keep half your ingredients. Winning keeps them all. The pantry
is saved (it's what the café will cook with).

## For developers
- `tools/run_all.sh`: lint, parse check, the headless smoke test (town, graphics tiers, defence night, UI layout)
  and the collision/clipping suite, about 1 minute. Prints `ALL CHECKS PASS`.
- `tools/run_all.sh --long`: adds the 3-minute walk sweep, the balance bot (4 nights), the stability run, the
  rendered performance probe and the brightness/readability check (needs `xvfb-run` and Vulkan), about 15 minutes.
- `tools/shoot.sh OUT_DIR [shot ...]`: review stills (needs `xvfb-run` and a Vulkan driver; lavapipe works).
