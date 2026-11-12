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
| R | restart (on the pause, win or lose screen) |

## How to win

- **Hide** in bushes and tall grass: Thornback cannot see you there unless it is very close or watched you go in.
- **Ambush**: a bite or spit started from hiding, or while Thornback has not noticed you, does 1.75x damage and
  staggers it. The HUD says **AMBUSH READY** when your next attack would be one.
- **Sneak** (Shift): running is heard from about 10 m, sneaking from about 3 m. Attacks are loud.
- **Snares**: a snare roots Thornback for 2 s and hurts it a little. If it saw or heard you set it, it remembers
  and walks around it.
- **Cover**: trees, rocks and logs stop spit (both ways). The ridge in the north-east gives a little more spit range
  when you shoot down from it.
- **Patience**: both of you heal slowly when left alone for a few seconds.

## The HUD

- bottom left: your life; bottom centre: your four moves (dark sweep = cooling down);
- bottom right: the **stealth eye**: green closed eye HIDDEN (it does not know where you are), amber HEARD (it has
  a clue and is looking), red open eye SEEN;
- top centre: Thornback's life, only while you can see it (or are locked on);
- amber chevrons around the crosshair ("rustle"): Thornback is close, moving and out of sight.
