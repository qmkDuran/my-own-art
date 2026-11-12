# Creature Woods: design notes

A greybox prototype answering one question: **is a slow, readable, third-person 1v1 creature fight in the woods,
where you can hide and use the environment, fun?** Everything is primitive shapes; there are no art assets, no
audio and no external services.

## Pillars (agreed with the user)

1. **Fights are creature vs creature.** The trainer is never in a fight; you play the creature.
2. **Win by outsmarting, not by reflexes.** Stalking, hiding, ambushing, setting snares and using terrain matter
   more than fast hands. A fight is about positioning, patience and baiting, not mashing.

## What serves the pillars

- **Slow pace.** Moderate movement (4.2 m/s, sneak 1.9 m/s), slow spit (10 m/s), 0.6-1.0 s wind-ups with a pose
  and a glow, cooldowns of 1.6-14 s. Attacks slow you to a third while winding up (a snare roots you), so every
  move is a commitment. Nothing can be spammed.
- **The ambush is the star.** An attack that starts while the target has not noticed the attacker does 1.75x
  damage and staggers (0.7 s, interrupting any wind-up). "Not noticed" is one rule for both sides: the target has
  not seen the attacker for 1.5 s. Hiding keeps you unnoticed; coming from behind works too. The HUD's stealth
  eye (HIDDEN / HEARD / SEEN) and AMBUSH READY make this readable at a glance; "AMBUSH!" pops when it lands.
- **Hiding.** Bushes and tall grass are `Area3D` hiding spots. Inside one you are invisible beyond 2.5 m, unless
  the watcher saw you go in. Attacking or setting a snare reveals you for 3 s. While the player hides, the bush
  turns see-through for the player only.
- **The snare (F)** is the one trap: one at a time, 14 s cooldown, about 1 s to set (standing still, noisy:
  heard within 9 m). It roots for 2 s and deals 8. Tit for tat: if the bot saw or heard it being set, it
  remembers the spot and walks around it; while searching carefully it can spot one from 2.2 m.
- **Noise is information.** Running is heard at 10 m, sneaking at 3 m, attacks at 16 m, a roll at 8 m, a snare
  being set at 9 m, a snare snapping at 12 m. A glob of spit landing makes a 7 m noise where it lands, which the
  bot investigates: you can throw a sound to pull it over a snare or past your bush.
- **Terrain.** Trees, rocks and logs block spit and sight (logs are low: they stop a glob but you can see over
  them). The ridge in the north-east gives 1.2x spit range when shooting down at least 1.5 m. The ravine and
  rim shape the routes.
- **Fairness.** The bot has exactly the player's stats and moves (`Creature` is shared; only the controller
  differs). Its dodge reactions are decided once per threat with a 50 % chance. An unseen bot moving within 7 m
  always gives itself away: bushes sway, and amber "rustle" chevrons around the crosshair point at it.

## The bot's mind (state machine, `game/bot/`)

| State | What it does | Leaves for |
| --- | --- | --- |
| patrol | walks quietly between patrol points, pausing at each | notice (sees you, hears you, gets hit) |
| notice | stops and turns toward the clue for 0.8 s, "!" overhead | stalk (saw you, you have not seen it), hunt (saw you), search (only heard) |
| stalk | sneaks in, aiming to come from behind you, opens with an ambush bite | fight (you notice it or it struck), hunt (too far), search (lost you) |
| hunt | runs at you; when you break line of sight it swings wide around your last spot (a flank) | fight (in range and seen), search (lost) |
| fight | faces you, holds ~7 m, strafes and switches side, spits when it has a clear shot, rushes in to bite when it plans to | cover (being shot at), hunt (lost you or too far) |
| cover | runs behind the nearest trunk or boulder that blocks your line of fire, waits until its spit is ready | fight (sees you), hunt (to flank), fight if you close in |
| search | goes to the last known spot, looks around, then checks the 3 nearest hiding spots (nearest to where you were heading first), sneaking and listening; a new sound moves the search; "?" overhead | fight/hunt (finds you), patrol (gives up after 24 s) |
| retreat | at 35 % life: slips away to the refuge farthest from you that you cannot see (often a bush) and heals | patrol (healed to 80 %), fight (cornered within 5 m) |

Around the states: **senses** (`perception/perception.gd`: vision cone 120 deg, 24 m, line-of-sight ray, close
awareness 2.2 m, hidden rule, hearing, memory of last position/heading and of snares), **reflexes**
(`bot/bot_reflexes.gd`: roll out of an incoming glob or back from a visible bite wind-up), and **legs**
(`bot/bot_mover.gd`: a NavigationAgent3D on a navmesh baked at start from the terrain, trunks, rocks, logs and the
arena edge; snare detours; eases into goals; progress is measured by distance, it side-steps off snags and gives
up on unreachable goals, so it never stays stuck).

## Tuning

All numbers are in `game/data/tuning.json` (moves, noise radii, perception, every AI timing, camera, lock-on).
The woods (layout, colours, light) are in `game/data/woods.json`; the two creatures' looks in
`game/data/creatures.json`. The arena is seeded, so the woods are the same every run.

## Architecture

- `core/`: `Main` builds the match and wires everything through `setup()` calls; `MatchFlow` (intro, play,
  pause, win/lose, restart); autoloads `Tuning` (data) and `NoiseBus` (sounds); `InputSetup` (physical-key map).
- `creature/`: `Creature` (CharacterBody3D) owns movement, facing, `Health`, `Stealth`, the four `Ability`
  objects and the `CreatureModel`. Controllers only write intent (`move_intent`, `sneaking`, `aim_point`,
  `look_target`, `try_bite()` ...).
- `combat/`: `Ability` (wind-up, active, recovery, cooldown) and its four moves, `SpitProjectile` (sphere sweep
  every step, so it never tunnels), `SnareTrap`, `SplatFx`, `Health`.
- `player/`, `camera/`: input, the orbit camera with a spring arm (never clips through trees), `PlayerSight` (the
  same visibility rules, plus on-screen), `LockOn`.
- `world/`: `TerrainShape` (pure height function), `TerrainBuilder`, `ForestScatter`, `Props`, `Foliage` /
  `HidingSpot`, `Atmosphere`, `Woods` (builds it all and bakes the navmesh).
- `ui/`: small `_draw()` widgets sharing `HudStyle`.
- Checks: `tools/run_all.sh` runs the lint (`tools/check_code.py`), the smoke test (`--smoke`, 40+ checks) and a
  150 s duel against a scripted player (`--duel`, fails if the bot ever stops making progress while walking).
  `tools/shoot.sh OUT_DIR` renders the review stills (`--shots`).

## Choices made without asking

- The bot does not set snares itself (the trap is the player's outsmarting tool); everything else is shared.
- Ambush = "the target has not noticed you", one rule for both sides, rather than "attacked from a bush".
  A bot that watched you dive into a bush is not fooled.
- Hidden creatures are only revealed within 2.5 m, so a bush ambush is a timing game: strike while it passes in
  lunge reach (~4 m) but before it is close enough to spot you.
- No audio: the "rustle" cue is visual (bush sway plus HUD chevrons).
- Windows: Compatibility renderer, physical-key bindings (WASD works on AZERTY/QWERTZ).

## Known gaps and weak spots

- No sound at all, so hearing is only shown through the stealth eye and the rustle chevrons.
- The bot's stalk only triggers when it spots you first while you are not looking; against an attentive player
  it mostly hunts and fights in the open.
- The bot reads the player's exact position while it can see them and knows exactly where a noise came from;
  there is no uncertainty in its hearing.
- Cover picking uses tree trunks and boulders only (not logs) and checks one line of sight; a player who moves
  fast around the cover can still get a shot.
- The creatures' collision is a vertical capsule, so the head pokes past it a little in melee.
- Retreat-and-heal can drag a fight out if you let the bot rest; chase it to stop its regeneration.
- Balance is first-pass: one tuning file, little playtesting. The duel probe shows fights of 1-2 minutes against a
  naive scripted player.
- Greybox only: low-poly primitives, no animation rig (legs swing, poses are rotations).
