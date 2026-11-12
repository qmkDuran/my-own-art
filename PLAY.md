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
- **Exploring:** you are the trainer. Left click walks. Your creature follows. Wild creatures roam in the grass.
- **Battle:** right-click a wild creature (or let one notice you) and a glowing **ring** forms around the fight:
  nothing else can come in. **You control your creature.** The trainer stays back and is **never hurt**.
- **The combat model:**
  - **Right click (hold)**: a basic 3-hit combo, no cooldown. Basic hits fill the **gauge** (3 segments under the
    creature card).
  - **Q W E R** cost gauge (1-3 segments, pips on each icon). **Hold** the key: time slows right down, a ghost shows
    where the move lands; **release** to use it. Moves **commit**: a wind-up and a recovery where you cannot dodge.
  - **Space** dodges. Dodging through a red warning at the last moment is a **perfect dodge**: gauge and a flash.
  - **Stagger:** the gold bar under a foe's life fills with hits (element weaknesses fill it much faster). Full, the
    foe is **STAGGERED** for 3 s: it reels and takes 50% more. Spend your gauge then.
  - **Swaps (1-3)** cost 1 gauge in battle; the swap-in strikes as it lands. Swap just as a red warning lands for a
    **perfect swap** (the attack misses, the foe staggers).
  - Wild creatures fight in their own way: maned wolves flank and run, devils commit to big lunges (punish the
    pause after), aye-ayes keep their distance.
- The battle ends when no foe in the ring can fight (defeated or dazed), or press **X** to retreat. A Victory
  summary shows what you won. Then 4 seconds of grace.
- **Your whole team knocked out:** fade, retreat to camp, they recover there (you lose one of each material).
- **Catch:** weaken a wild creature until it is dazed (the pink mark on its life bar), then press **F**: your trainer
  walks over and calms it. Don't hit it meanwhile.
- **Learn your moves:** hover a move icon; press **I** (or click the team strip) for the creature info panel.
- **Shinies** are rare (1 in 64). **F1** (dev) spawns one next to you.

## Controls
| Key | Exploring (trainer) | Battle (your creature) |
|---|---|---|
| **Left click** | Walk (hold to keep walking) | Move your creature (hold to keep moving) |
| **Right click** | On a wild creature: start a battle | Basic combo on the creature under the cursor (hold to keep going) |
| **Q W E R / T** | Hold to aim (time slows), release to use; costs gauge (T: bond move) | same |
| **Space** | Trainer roll | Your creature's dodge |
| **1 2 3** | Swap creature | Swap (1 gauge); perfect swap on a landing attack |
| **4 / 5** | Honeyberry (heal) / Smelling Salts (revive) | same |
| **F** | Catch the nearest dazed creature (the trainer walks over) | same |
| **X** | - | Retreat |
| **I / C / Esc** | Creature info / camp panel (at camp) / close panels | same |
| **F1** | Dev: spawn a shiny | same |

