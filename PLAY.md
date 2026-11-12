# How to play the trainer prototype

This is a quick feel prototype for one question: **does exploring as a trainer and battling as your creature,
with the trainer helping from behind, feel good?** It takes about 10 minutes to try everything.

## Run it (Windows)
1. Clone the repository and check out the `tamer-arpg` branch.
2. Open Godot 4.7.2, choose **Import**, and pick `game/project.godot`.
3. Press **F5** (Run Project). The prototype starts straight away (no title screen).

The first import takes a minute while Godot builds its cache. Errors about fonts on the very first import go away on
their own.

## How it plays
- **Exploring:** you are the trainer. Left click walks. Your creature follows.
- **Battle:** right-click a wild creature (or walk too close to one) and a battle starts: "Go, <name>!", your
  creature leaps in and **you control your creature**. The trainer stays back on their own and is **never hurt**.
  The battle ends when no awake wild creature is left nearby (or you run away), with a **Victory** summary.
- **Your whole team knocked out:** the screen fades and you retreat to camp, where they recover (you lose one of
  each material).
- **Befriend:** weaken a wild creature until it is dazed (gold stars, the pink mark on its life bar), then press
  **F**: your trainer walks over and calms it. Don't hit it meanwhile.
- **Learn your moves:** hover a move icon for what it does; press **I** (or click the team strip) for the creature
  info panel. Each move's name pops up the first time you use it.
- **Wild attacks are telegraphed:** a red warning shows where they will land. Dodge (Space) or step out.
- **Camp:** heal, pet, feed, and spend materials on stats. **Shiny:** one maned wolf is always shiny.

## Controls
| Key | Exploring (trainer) | Battle (your creature) |
|---|---|---|
| **Left click** | Walk (hold to keep walking) | Move your creature (hold to keep moving) |
| **Right click** | On a wild creature: start a battle | Attack the creature under the cursor (or swing toward the cursor) |
| **Q W E R** | Hold to aim (a ghost of the move shows), release to use | same |
| **T** | Bond move (after the bond meter reaches its mark) | same |
| **Space** | Trainer roll | Your creature's dodge |
| **A S D G** | Trainer commands: Cheer (hits harder), Focus (next move crits), Rally (heal over time), Mark (the creature under the cursor takes more) | same |
| **1 2 3** | Swap creature (the one coming in strikes; swap just before a red warning lands for a **perfect swap**) | same |
| **4 / 5** | Honeyberry (heal) / Smelling Salts (revive) | same |
| **F** | Befriend the nearest dazed creature (the trainer walks over) | same |
| **I** | Creature info | same |
| **C / Esc** | Camp panel (at camp) / close panels | same |

Your creature hits harder inside the faint ring around the trainer (the bond aura), so stay close.
