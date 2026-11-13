# Creature Woods: how to play

A slow, readable third-person duel in the woods. You are **Ember**, a fox-like creature. Your opponent is
**Thornback**, a horned boar-like creature run by the computer. Win by outsmarting it: stalk, hide, ambush,
use your senses and use the terrain.

## Run it on Windows

1. Install **Godot 4.7.2** (the standard build, not .NET) from godotengine.org and unzip it anywhere.
2. Get the branch:
   ```
   git clone --branch creature-3d --single-branch <this repository's URL> creature-3d
   ```
3. Start Godot, click **Import**, pick `creature-3d/game/project.godot`, then **Import & Edit**.
4. Press **F5** (Run Project). The first import takes a few seconds.

It uses the Compatibility renderer (OpenGL), so it runs on almost any graphics card.

## Before the fight: the loadout screen

The game opens on the loadout screen (R after a fight brings it back):

- **Level**: Baby or Grown, for both creatures. Baby fights only allow the simpler moves; Grown unlocks all 40.
- **Difficulty**: Easy, Normal or Hard (how fast and how well Thornback thinks, never its stats).
- **Ember's four moves**: click a slot (LMB, RMB, Q, E), then a move from Ember's learnset. The line below shows
  what the move does, what it costs you and how to counter it. Defaults: Leaping Strike, Leap, Cinder Spit,
  Keen Ears. Thornback takes Ram, Burrow, Mud Lob, Scent Trail (its own Baby set at Baby level).
- **Start the fight** (button or Enter). Every move is listed in `MOVES.md`.

## Controls

| Input | Action |
| --- | --- |
| W A S D | move, relative to the camera |
| Mouse | look around (orbit camera) |
| Shift (hold) | sneak: slow and quiet |
| Left click / Right click / Q / E | your four moves, in loadout order |
| Space | **dodge roll** (you cannot be hurt while rolling; cooldown) |
| Tab | **lock on** to Thornback while you can see it (again to release) |
| Esc | pause and free the mouse (Esc or click to resume) |
| R | restart (back to the loadout screen) |
| F3 | show the bot's mind: its plan, scores, best tactical spots, what it has learned |
| F9 | wipe what the bot has learned about you |

## How to win

- **Hide** in bushes, tall grass, a tree crown (Climb), under the ground (Burrow) or under water (Submerge).
  Hiding is **true both ways**: a hidden creature gives nothing away, no sway, no rustle, no marker. Concealed in
  leaves you are invisible beyond 2.5 m unless it watched you go in; burrowed or submerged you are invisible at any
  distance (a burrow's dust trail and a swimmer's bubbles still show where it moves).
- **Senses are the counter.** Keen Ears pings every sound nearby from much further away; Scent Trail shows where
  the target walked in the last few seconds; Echo Pulse reveals every hidden creature nearby for a moment (a bright
  ping over it, even through leaves). Senses work both ways: Thornback uses them on you.
- **Ambush**: an attack started while Thornback has not noticed you (hidden from it, or behind it) does 1.75x
  damage and staggers it. The HUD says **AMBUSH READY** when your next attack would be one. Attacking gives your
  hiding place away for a few seconds.
- **Sneak** (Shift): running is heard from about 10 m, sneaking from about 3 m. Attacks are loud.
- **Use the woods**: the plateau in the south-west has a ramp and four jump spots (flat stones) where Leap reaches
  the top; high ground gives more range. Soft brown soil is diggable (Burrow works only there, not on rocky grey
  ground). The stream and the pond hide swimmers and put out fire. Cinder Spit and Kindle set tall grass alight,
  burning away hiding spots (yours too); burnt grass regrows. Hollow logs hide and block shots. Trees, rocks and
  logs stop projectiles both ways.
- **Patience**: both of you heal slowly after about 6 s without being hurt. Thornback plays by exactly the same
  rules as you (same life, speeds, moves, wind-ups and cooldowns at the same level).

## Thornback learns

Thornback only knows what it sees and hears. It remembers your habits across fights (favourite hiding spots, how
early you roll, whether you fight up close or at range, how often you hide, which way you run when hurt) and plays
around them: it checks your favourite bush first, uses its senses sooner against a hider, takes cover against a
shooter, waits out early rolls. It uses its moves like you do: leaps to high ground, burrows to ambush, climbs a
tree to hide, sniffs you out and burns grass it thinks you are in.
Each fight writes a log to `playtest/sessions/`; `python3 tools/analyze_session.py` summarises the newest one.

## The HUD

- bottom left: your life and active effects ("Exposed" when one of Thornback's senses has revealed you); bottom centre: your four moves plus roll (dark sweep = cooling down);
- bottom right: the **stealth eye**: green closed eye HIDDEN (it does not know where you are), amber HEARD (it has
  a clue and is looking), red open eye SEEN;
- top centre: Thornback's life, only while you can see it (or are locked on);
- over Thornback's head: "!" when it notices something, "?" while it searches.
