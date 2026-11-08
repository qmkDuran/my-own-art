# my-own-art

A 2D action ARPG where your starter creature is your class. Built in Godot 4.7.
See [DESIGN.md](DESIGN.md) for every design decision.

## Run it
1. Install Godot 4.7 (standard, not .NET).
2. Godot → Import → pick this folder's `project.godot`.
3. Press F5. Move Emberoo with WASD, arrow keys or a gamepad stick. Left click (or gamepad X) to jab, Space (or gamepad A) to dodge.

## Folder layout
| Folder | What lives there |
|---|---|
| `art/<creature>/` | Sprites. Sheets are named `<creature>_<view>_<action>_sheet.png` (views: front, back, side). |
| `scenes/` | Godot scenes, grouped by thing (`main/`, `creatures/emberoo/`). |
| `scripts/components/` | Small single-job pieces: input, movement, facing. |
| `scripts/animation/` | Loading sprite sheets and choosing what to play. |
| `scripts/effects/` | Visual effects: hit bursts, afterimages, speed trails. |
| `scripts/creatures/` | The creature itself, which only coordinates its components. |

## Code rules (Clean Code)
- **One job per script.** If you need "and" to describe it, split it.
- **Names say what things are.** `move_direction`, not `dir`; `top_speed`, not `spd`.
- **No magic numbers.** Name them as constants or `@export` variables.
- **Small functions** that read like sentences.
- **Comments explain why**, not what; the names explain what.
- **Composition over inheritance:** creatures are built from component nodes.
