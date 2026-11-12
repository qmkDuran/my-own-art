# Creature Woods: how to play

A slow, readable third-person duel in the woods. You are **Ember**, a fox-like creature. Your opponent is
**Thornback**, a horned boar-like creature run by the computer. Win by outsmarting it: stalk, hide, ambush,
set snares and use the terrain.

## Run it on Windows

1. Install **Godot 4.7.2** (the standard build, not .NET) from godotengine.org and unzip it anywhere.
2. Get the branch:
   ```
   git clone --branch creature-3d --single-branch <this repository's URL> creature-3d
   ```
3. Start Godot, click **Import**, pick `creature-3d/game/project.godot`, then **Import & Edit**.
4. Press **F5** (Run Project). The first import takes a few seconds.

It uses the Compatibility renderer (OpenGL), so it runs on almost any graphics card.

## Controls

| Input | Action |
| --- | --- |
| W A S D | move, relative to the camera |
| Mouse | look around (orbit camera) |
| Shift (hold) | sneak: slow and quiet |
| Left click | **Bite**: a visible wind-up, a short lunge, close range |
| Right click | **Spit**: a slow glob aimed at the crosshair; trees, rocks and logs stop it |
| Space | **dodge roll** (you cannot be hurt while rolling; cooldown) |
| F | **set a snare** at your feet (takes about a second, makes noise, one at a time, long cooldown) |
| Tab | **lock on** to Thornback while you can see it (again to release) |
| Esc | pause and free the mouse (Esc or click to resume) |
| R | restart (any time after the start screen; shown on the win and lose screens) |
| 1 / 2 / 3 | difficulty Easy / Normal / Hard (on the start or pause screen) |
| F3 | show the bot's mind: its plan, scores, best tactical spots, what it has learned |
| F9 | wipe what the bot has learned about you |

## How to win

- **Hide** in bushes and tall grass: Thornback cannot see you there unless it is very close or watched you go in.
- **Ambush**: a bite or spit started while Thornback has not noticed you (you are hidden from it, or behind it)
  does 1.75x damage and staggers it, cutting off whatever it was winding up. The HUD says **AMBUSH READY** when
  your next attack would be one. From a bush, strike as it passes within lunge reach (about 4 m) but before it
  comes close enough to spot you (2.5 m). Attacking gives your hiding place away for a few seconds.
- **Sneak** (Shift): running is heard from about 10 m, sneaking from about 3 m. Attacks are loud.
- **Snares**: a snare roots Thornback for 2 s and hurts it a little. Setting one takes a second and is heard
  about 9 m away; if Thornback saw or heard you set it, it remembers and walks around it. While searching
  carefully it can also spot one from about 2 m. Lure it over one: a glob of spit that lands somewhere makes a
  noise it will come to check.
- **Cover**: trees, rocks and logs stop spit (both ways). The ridge in the north-east gives a little more spit range
  when you shoot down from it.
- **Patience**: both of you heal slowly after about 6 s without being hurt. Thornback plays by exactly the same
  rules as you (same life, speeds, moves, wind-ups and cooldowns).

## Thornback learns

Thornback only knows what it sees and hears. It remembers your habits across fights (favourite hiding spots, how
early you roll, where you set snares, which way you run when hurt) and plays around them: it checks your favourite
bush first, sets its own snare beside it, waits out early rolls. Its snares are hard to see until you are close.
Difficulty changes how fast and how well it thinks and how much it uses that memory, never its stats.
Each fight writes a log to `playtest/sessions/`; `python3 tools/analyze_session.py` summarises the newest one.

## The HUD

- bottom left: your life; bottom centre: your four moves (dark sweep = cooling down);
- bottom right: the **stealth eye**: green closed eye HIDDEN (it does not know where you are), amber HEARD (it has
  a clue and is looking), red open eye SEEN;
- top centre: Thornback's life, only while you can see it (or are locked on);
- amber chevrons around the crosshair ("rustle"): Thornback is close, moving and out of sight. Bushes and grass
  also sway when something moves through them.
- over Thornback's head: "!" when it notices something, "?" while it searches.
