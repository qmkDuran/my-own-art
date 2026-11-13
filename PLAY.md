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
| Mouse | look around (click the window to capture the mouse) |
| R | toggle rain (rain falls, puddles grow and shine, the fog thickens, rain sound fades in) |
| H | show the controls hint again |
| Esc | free the mouse |

## Where to go
- **The square:** the fountain, the big tree, the clock tower and the bakery's glowing window. The baker chats by her
  stall, the old man sits on his bench, and the child runs around the fountain and waves at the cat.
- **Lamp Street:** walk west from the square (past the signpost). There's a music box playing in an upstairs window.
- **The canal:** south of the square. Cross the stone bridge; the ginger cat sits on the canal wall beside it.
- **Lantern Alley:** east from the square, lit by wall lanterns.
- **The overlook:** from the south bank, walk east along the canal and up the long steps to the terrace for the view.

## For developers
- `tools/run_all.sh`: lint, parse check and headless smoke test (prints `ALL CHECKS PASS`).
- `tools/shoot.sh OUT_DIR [shot ...]`: review stills (needs `xvfb-run` and a Vulkan driver; lavapipe works).
