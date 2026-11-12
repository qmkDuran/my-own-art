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

## The bot's mind (`game/bot/`)

**Fair by construction.** The bot only knows what its senses give it: what it sees (vision cone, line of sight,
the hiding rule), what it hears (noise radii), and what it remembers. Its velocity estimate of the player comes from
successive sightings; the player's life is "as last seen"; whether the player is facing it is read from the player's
creature while visible. It never reads the player's awareness, cooldowns or hidden position.

**Utility AI** (`bot/utility/`). Every think interval (0.25 s Hard, 0.4 s Normal, 0.7 s Easy) `BotFacts` gathers
facts (distance and line of sight to the last known spot, own life, the player's life as last seen, cooldowns, being
shot at, cover and ambush quality nearby, height advantage, its own snare, learned habits) and `UtilitySelector`
scores each option: base weight x a curve per consideration, all in `game/data/ai.json`. A little noise (more on
Easy) blurs close calls; the current option gets a small inertia bonus; an option that just finished is skipped once.
A first sound or sighting while idle forces a "notice" beat of the difficulty's reaction time.

| Option (state) | What it does |
| --- | --- |
| patrol | no clue: walk quietly between patrol points |
| chase | run at the player or its last known spot |
| spit | hold ~7 m, strafe, spit with a lead on the observed movement |
| bite | close in and bite; vs players it learned roll early, it waits for the roll first |
| cover | run to the best covered point (solid cover across its body width), shelter until its spit is back |
| flank | just lost sight: go to the best flanking point around the predicted position |
| stalk | sees the player, who is not facing it: sneak in from behind, open with a bite |
| snare | player out of sight: set its own snare by the player's favourite hiding spot (or on the way) |
| ambush | player probably coming: wait concealed near the predicted path, strike when it passes |
| retreat | low life: go to the best refuge (far, covered, concealed, with exits) and heal |
| search | go to the predicted spot, look around, check hiding spots (favourites first, then along the heading) |
| bait | its snare is set and the player watches: stand beyond the snare and spit to draw the player over it |

**Tactical positions** (`bot/tactics/tactical_eval.gd`). Candidates: rings around a centre, every nearby hiding spot,
and the lee side of every nearby trunk and boulder, snapped to the navmesh. Features: solid cover from the threat,
sightline to it, concealment, high ground, escape routes (open directions), distance band, travel cost, snare risk
(known snares and learned snare areas) and cutting off the player's learned escape direction. Each purpose (cover,
flank, ambush, retreat, bait) weighs them from `ai.json`. F3 shows the best points and their scores in the world.

**Prediction** (`bot/prediction.gd`): intercept-time lead for spit, the last known spot pushed along the observed
heading for the time it has been unseen, and the hiding spots ahead along that heading. After it sees the player roll
it attacks inside the roll's cooldown.

**Memory** (`bot/memory/`). `PlayerWatcher` turns sightings into `PlayerModel` entries: hiding spots and kinds
(watched or found), bite vs spit, how soon you roll after its wind-up starts, time on high ground, snare spots, flee
direction when hurt. It persists in `user://player_model.json` (F9 wipes it) and adapts within and across fights:
favourite spots are searched first, snares go by your favourite bush, learned snare areas are avoided, ambush and
flank points lean across your usual escape route, the ridge is worth more if you like it, early rollers are waited
out. Learning shows only in the F3 overlay ("the bot is learning", barks like "It remembers you like the bushes.").

**Difficulty** (`core/difficulty.gd`, keys 1/2/3 on the start or pause screen) changes only reaction time, think
interval, decision noise, reflex delay and how much memory is used. Never stats.

**Session logs** (`core/session_log.gd`): one JSON per fight in `playtest/sessions/` (player trail, hide events,
moves and hits for both, bot states and decisions with top scores, outcome, duration). `tools/analyze_session.py`
summarises one and flags suspicious moments (long fruitless searches, flip-flopping, ambushes walked into).

Around the decisions: **senses** (`perception/perception.gd`), **reflexes** (`bot/bot_reflexes.gd`: roll out of a
visible glob or back from a visible bite wind-up, after the difficulty's reflex delay) and **legs**
(`bot/bot_mover.gd`: navmesh paths, snare detours, precise arrival for tactical points, side-steps off snags, gives up
on unreachable goals).

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
- Checks: `tools/run_all.sh` runs the lint (`tools/check_code.py`), the smoke test (`--smoke`, 50+ checks), a
  duel against a scripted player (`--duel`, fails if the bot ever stops making progress while walking) and the
  session analyzer on the duel's log.
  `tools/shoot.sh OUT_DIR` renders the review stills (`--shots`).

## Choices made without asking

- The bot sets snares too (same move and rules). Its snares are faint to the player until within 2.2 m, just as the
  player's are invisible to the bot until it is that close while searching.
- The player's view of the bot uses the bot's own vision range (24 m) and needs a clear line from both the creature
  and the camera, so the bot's life bar shows only when you really see it.
- Ambush = "the target has not noticed you", one rule for both sides, rather than "attacked from a bush".
  A bot that watched you dive into a bush is not fooled.
- Hidden creatures are only revealed within 2.5 m, so a bush ambush is a timing game: strike while it passes in
  lunge reach (~4 m) but before it is close enough to spot you.
- No audio: the "rustle" cue is visual (bush sway plus HUD chevrons).
- Windows: Compatibility renderer, physical-key bindings (WASD works on AZERTY/QWERTZ).

## Known gaps and weak spots

- No sound at all, so hearing is only shown through the stealth eye and the rustle chevrons.
- The bot knows exactly where a noise came from; there is no uncertainty in its hearing.
- Tactical evaluation is sampled (rings plus hiding spots plus lee points), not a full visibility map; logs are not
  used as cover points.
- The utility weights are first-pass and tuned against a scripted player only; the duel probe shows the bot still
  switches plans often in close fights (the analyzer flags it).
- Bait and ambush are simple: bait stands beyond its snare and spits; ambush waits up to 12 s.
- The creatures' collision is a vertical capsule, so the head pokes past it a little in melee.
- Retreat-and-heal can drag a fight out if you let the bot rest; chase it to stop its regeneration.
- Balance is first-pass: one tuning file, little playtesting. The duel probe shows fights of 1-2 minutes against a
  naive scripted player.
- Greybox only: low-poly primitives, no animation rig (legs swing, poses are rotations).
