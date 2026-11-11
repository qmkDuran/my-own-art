# How to play the trainer prototype

This is a quick feel prototype for one question: **does fighting as a trainer beside a creature partner, with hybrid
control, feel good?** It takes about 10 minutes to try everything.

## Run it (Windows)
1. Clone the repository and check out the `tamer-arpg` branch.
2. Open Godot 4.7.2, choose **Import**, and pick `game/project.godot`.
3. Press **F5** (Run Project). The prototype starts straight away (no title screen).

The first import takes a minute while Godot builds its cache. Errors about fonts on the very first import go away on
their own.

## What happens
1. **Meet your starter.** Three young creatures wait in the meadow: the **Honey Badger** (Ember, a brave fighter),
   the **Cuttlefish** (Glass, a quick ranged trickster) and the **Pangolin** (Bloom, a sturdy protector). Walk up to
   each one to see how it reacts, then **click** the one you want.
2. **Fight wild packs** of maned wolves (Gale), aye-ayes (Echo) and Tasmanian devils (Rot). Tougher ones live further
   from the start.
3. **Befriend:** weaken a wild creature until its life bar passes the pink notch. It gets dazed (gold stars). Stand
   next to it and **hold F** for a second. Getting hit or moving cancels it. You can have up to 3 creatures.
4. **Find the shiny:** one maned wolf in the meadow is always shiny (pale coat, violet mane, gold name, sparkles).
5. **Rest at camp:** follow the path to the campfire. Everyone is healed, the wild packs come back, your team sits
   around the fire, and the camp panel opens.
6. **Grow:** fights fill each creature's bond meter. At the mark, it unlocks a **bond move** on **T**. At camp, pet
   and feed for more bond, and spend materials to raise Life, Power or Speed.

The box at the top left always tells you what to try next.

## Controls
| Key | What it does |
|---|---|
| **Left click** (ground) | Walk there (hold to keep walking toward the cursor) |
| **Left click** (wild creature) | Your creature attacks it |
| **Q W E R** | Your creature's 4 moves, aimed at the cursor |
| **T** | Bond move (unlocks when the bond meter reaches the mark) |
| **Hold Shift** | **Steer your creature directly.** The camera moves over to it and it gets a gold outline. Click to move it or attack, or use the **arrow keys**. Let go to hand back to the trainer |
| **Space** | Dodge-roll (trainer). While steering: the creature's own dodge |
| **1 2 3** | Swap creature. The one coming in strikes as it lands |
| **4** | Honeyberry: heal your creature by half (4 of them) |
| **5** | Smelling Salts: wake a knocked-out creature (2 of them) |
| **Hold F** | Befriend a dazed wild creature next to you |
| **C** | Open or close the camp panel (at camp) |
| **Esc** | Close the camp panel |

## Rules worth knowing
- **Elements:** each element is strong against 2 and weak against 2. You see "Super effective!" or "Resisted" over
  the target. Ember beats Glass and Rot; Gale beats Ember. The full chart is in VISION.md.
- **Your creature fights on its own:** it goes for what you clicked, or for anything that attacks you or comes close.
  It leaves dazed creatures alone, so you can befriend them (click one if you want it finished off).
- **Knock-outs:** a knocked-out creature fades away and comes back after about 20 seconds, or at camp. The next
  creature steps in by itself. If all of them are out, you're on your own: roll away and get to camp.
- **If you fall,** you wake up at camp. Nothing is lost.
- **Materials:** devils drop Rot Fangs (Life), wolves drop Wind Tufts (Power), aye-ayes drop Night Whiskers (Speed).
  Walk near a drop to pick it up.
