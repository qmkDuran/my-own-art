# Creature Woods: design notes

A greybox prototype answering one question: **is a slow, readable, third-person 1v1 creature fight in the woods,
where you can hide and use the environment, fun?** Everything is primitive shapes; there are no art assets, no
audio and no external services.

## Pillars (agreed with the user)

1. **Fights are creature vs creature.** The trainer is never in a fight; you play the creature.
2. **Win by outsmarting, not by reflexes.** Stalking, hiding, sensing, ambushing and using terrain matter
   more than fast hands. A fight is about positioning, patience and baiting, not mashing.

## What serves the pillars

- **Readable pace, a little quicker.** Run 4.9 m/s, sneak 2.2 m/s (about 17 % faster than the first pass), and
  every wind-up, recovery and cooldown in `moves.json` cut by the same share. Moves still have a pose and a glow,
  slow you while winding up, and cannot be spammed.
- **Moves are data** (`game/data/moves.json`, 40 moves, listed in `MOVES.md`). Seven categories: attack, movement,
  defensive, buff, debuff, sense, terrain. Each records its timing, numbers, an archetype (melee, projectile,
  area, leap, buff, sidestep, burrow, climb, submerge, sense, spawn), a minimum level (Baby or Grown), its cost and
  its tit for tat. `MoveFactory` builds the archetype class; nothing in code is move-specific beyond the archetype.
  Each species has a learnset and a default four in `creatures.json`; the loadout screen picks four (LMB, RMB, Q, E).
- **The ambush is the star.** An attack that starts while the target has not noticed the attacker does 1.75x
  damage and staggers (0.7 s, interrupting any wind-up). "Not noticed" is one rule for both sides. The HUD's stealth
  eye (HIDDEN / HEARD / SEEN) and AMBUSH READY make this readable at a glance.
- **True hiding, both ways** (`perception/visibility.gd`, one set of rules for both creatures). Concealed (bush,
  grass, smoke, a tree crown) is invisible beyond 2.5 m unless the watcher saw it go in; burrowed or submerged is
  invisible at any distance. There are no giveaways: the old rustle chevrons and movement sway are gone (foliage
  only sways in the wind), and a hidden creature shows no marker or bar. The counter is **senses**: Keen Ears
  (hearing range up), Scent Trail (recent footsteps), Echo Pulse (reveals every hidden creature nearby for a
  moment; an exposed creature carries a bright ping visible through leaves). Moving underground or underwater
  leaves a dust trail or bubbles: tracks, not a position marker.
- **The snare is gone** (the key, the class, the bot options and the memory of snare spots).
- **Noise is information.** Running is heard at 10 m, sneaking at 3 m, attacks at 16 m, a roll at 8 m, a landing
  projectile at 7 m (the bot investigates it, so you can throw a sound).
- **The woods** (`woods.json`, about 1.7x the old area: 84 m square). A plateau with a cliff face, a ramp and four
  jump spots; a stream and a pond (swim, douse fire, Submerge); soft soil patches (Burrow only works there) and
  rocky ground; hollow logs; ferns, flowers, mushrooms, moss, trees of varied sizes, a few climbable trees (marked
  with faint rings); birds, pollen and fireflies; wind sway in a shader; warm daylight with light shafts.
  Tall grass burns (Cinder Spit, Kindle), spreading, then regrows; brambles burn too.
- **Fairness.** The bot has exactly the player's stats and the same move rules (`Creature` is shared; only the
  controller differs), at the same level. Its dodge reactions are decided once per threat with a 50 % chance.

## The bot's mind (`game/bot/`)

**Fair by construction.** The bot only knows what its senses give it: what it sees (vision cone, line of sight,
the hiding rule), what it hears (noise radii), and what it remembers. Its velocity estimate of the player comes from
successive sightings; the player's life is "as last seen"; whether the player is facing it is read from the player's
creature while visible. It never reads the player's awareness, cooldowns or hidden position.

**Utility AI** (`bot/utility/`). Every think interval (0.25 s Hard, 0.4 s Normal, 0.7 s Easy) `BotFacts` gathers
facts (distance and line of sight to the last known spot, own life, the player's life as last seen, cooldowns, being
shot at, cover and ambush quality nearby, height advantage, which of its moves are ready, a ledge or soft ground nearby, grass the player may be in,
learned habits) and `UtilitySelector`
scores each option: base weight x a curve per consideration, all in `game/data/ai.json`. A little noise (more on
Easy) blurs close calls; the current option gets a small inertia bonus; an option that just finished is skipped once.
A first sound or sighting while idle forces a "notice" beat of the difficulty's reaction time.

| Option (state) | What it does |
| --- | --- |
| patrol | no clue: walk quietly between patrol points |
| chase | run at the player or its last known spot |
| melee / ranged / area | use a ready move of that role at its range (ranged holds distance and leads the shot) |
| cover | run to the best covered point, shelter until its ranged move is back |
| flank | just lost sight: go to the best flanking point around the predicted position |
| stalk | sees the player, who is not facing it: sneak in from behind, open with an ambush |
| ambush | player probably coming: wait concealed near the predicted path, strike when it passes |
| retreat | low life: go to the best refuge and heal |
| search | go to the predicted spot, look around, check hiding spots (favourites first) |
| buff / debuff / defend | use a ready move of that role (defend answers a visible wind-up) |
| sense | lost the player for a while: use a sense move (sooner against a player it learned hides a lot) |
| high_ground | leap up a jump spot onto the plateau and fight from there |
| burrow_ambush | dig in on nearby soft soil, tunnel under the player's path, pop up with a hit |
| climb_hide | climb a marked tree near the player's path and wait hidden in the crown |
| burn_grass | set alight tall grass the player is probably hiding in |

Movement plans (high ground, burrow, climb) are committed until done, so the utility does not abandon them halfway.

**Tactical positions** (`bot/tactics/tactical_eval.gd`). Candidates: rings around a centre, every nearby hiding spot,
and the lee side of every nearby trunk and boulder, snapped to the navmesh. Features: solid cover from the threat,
sightline to it, concealment, high ground, escape routes (open directions), distance band, travel cost and cutting off the player's learned escape direction. Each purpose (cover,
flank, ambush, retreat) weighs them from `ai.json`. F3 shows the best points and their scores in the world.

**Prediction** (`bot/prediction.gd`): intercept-time lead for spit, the last known spot pushed along the observed
heading for the time it has been unseen, and the hiding spots ahead along that heading. After it sees the player roll
it attacks inside the roll's cooldown.

**Memory** (`bot/memory/`). `PlayerWatcher` turns sightings into `PlayerModel` entries: hiding spots and kinds
(watched or found), which roles you use (melee, ranged, sense ...), how soon you roll after its wind-up starts,
time on high ground, flee direction when hurt. It persists in `user://player_model.json` (F9 wipes it) and adapts within and across fights:
favourite spots are searched first, a hider gets sensed sooner, a ranged player makes cover worth more, a melee
player makes it wait for a punish window, ambush and flank points lean across your usual escape route, the
plateau is worth more if you like high ground, early rollers are waited
out. Learning shows only in the F3 overlay ("the bot is learning", barks like "It remembers you like the bushes.").

**Difficulty** (`core/difficulty.gd`, chosen on the loadout screen) changes only reaction time, think
interval, decision noise, reflex delay and how much memory is used. Never stats.

**Session logs** (`core/session_log.gd`): one JSON per fight in `playtest/sessions/` (player trail, hide events,
moves and hits for both, bot states and decisions with top scores, outcome, duration). `tools/analyze_session.py`
summarises one and flags suspicious moments (long fruitless searches, flip-flopping, ambushes walked into).

Around the decisions: **senses** (`perception/perception.gd`), **reflexes** (`bot/bot_reflexes.gd`: roll out of a
visible projectile or back from a visible melee wind-up, after the difficulty's reflex delay) and **legs**
(`bot/bot_mover.gd`: navmesh paths, precise arrival for tactical points, side-steps off snags, gives up
on unreachable goals).

## Tuning

Moves are in `game/data/moves.json`; the AI's options and curves in `game/data/ai.json`; everything else in
`game/data/tuning.json` (speeds, roll, noise radii, perception, fire, camera, lock-on).
The woods (layout, colours, light) are in `game/data/woods.json`; the two creatures' looks, learnsets and default
loadouts in `game/data/creatures.json`. The arena is seeded, so the woods are the same every run.

## Architecture

- `core/`: `Main` builds the match and wires everything through `setup()` calls; `MatchFlow` (loadout, play,
  pause, win/lose, restart); `Loadouts` (the four moves and the level); autoloads `Tuning` (data) and `NoiseBus` (sounds); `InputSetup` (physical-key map).
- `creature/`: `Creature` (CharacterBody3D) owns movement, facing, `Health`, `Stealth`, its four `Move`s and the
  roll, `Effects`, `Traversal` (ground, underground, perched, submerged) and the `CreatureModel`. Controllers only write intent (`move_intent`, `sneaking`, `aim_point`,
  `look_target`, `try_move(slot)` ...).
- `combat/`: `Ability` (wind-up, active, recovery, cooldown), `moves/` (`Move`, one class per archetype,
  `MoveLibrary`, `MoveFactory`), `Projectile` (sphere sweep every step, so it never tunnels), `Effects`, `Health`.
- `player/`, `camera/`: input, the orbit camera with a spring arm (never clips through trees), `PlayerSight` (the
  same visibility rules, plus on-screen), `LockOn`.
- `world/`: `TerrainShape` (pure height function: plateau, basins), `TerrainBuilder`, `ForestArt` (MultiMesh
  trees and undergrowth with a wind shader), `Water`, `CliffFaces`, `Props`, `HidingSpot`, `GrassFire`,
  `AmbientLife`, `Woods` (builds it all and bakes the navmesh).
- `ui/`: small `_draw()` widgets sharing `HudStyle`.
- Checks: `tools/run_all.sh` runs the lint (`tools/check_code.py`), a parse check, the smoke test (`--smoke`, now including
  snare gone, true hiding both ways, a sense revealing a hider, burrow only on soft ground, a leap reaching the
  ledge, the loadout applying, the bot using a movement move), a
  duel against a scripted player (`--duel`, fails if the bot ever stops making progress while walking) and the
  session analyzer on the duel's log.
  `tools/shoot.sh OUT_DIR` renders the review stills (`--shots`).

## Choices made without asking

- Ambush = "the target has not noticed you", one rule for both sides. A bot that watched you dive into a bush is
  not fooled. Hidden creatures are only revealed within 2.5 m, or by a sense move.
- True hiding means no rustle chevrons and no movement sway at all; tracks (burrow dust, bubbles, scent) remain,
  because they show where something went, not where it is now, and they are the senses' counterplay.
- Move names are original. Both creatures share one library; learnsets differ (Ember 30 moves, Thornback 27).
  Level is one setting for both creatures, so a Baby fight is fair.
- The bot's four are fixed per species and level (Ram, Burrow, Mud Lob, Scent Trail when Grown); its memory
  counters how you play, not which moves you picked.
- Climbable trees are a few marked trunks (faint rings), not every tree, so climb spots are learnable.
- The player's view of the bot uses the bot's own vision range (24 m) and needs a clear line from both the creature
  and the camera, so the bot's life bar shows only when you really see it.
- No audio: hearing shows through the stealth eye and the Keen Ears pings.
- Windows: Compatibility renderer, physical-key bindings (WASD works on AZERTY/QWERTZ).

## Known gaps and weak spots

- No sound at all; with true hiding a hidden bot is genuinely silent. Senses are the only answer.
- 40 moves are first-pass balance; many are checked only in the smoke test, not in long play.
- The bot uses its movement moves on simple triggers (a ledge or soft soil nearby, a clue, grass it suspects);
  it does not plan multi-step routes with them. Climb and submerge are rarer for it than leap and burrow.
- The duel probe (scripted player) still shows some plan flip-flopping in close fights.
- The cliff faces are lumpy boxes, readable but blocky; leaping onto the plateau works only at the jump spots, or
  walk up the ramp.
- An Echo Pulse reveal shows a ping over the hider; the creature itself can still be mostly behind leaves.
- Performance: MultiMesh trees and undergrowth keep draw calls low, but the bigger woods are heavier than before;
  untested on a weak GPU.
- The creatures' collision is a vertical capsule, so the head pokes past it a little in melee.
- Greybox only: low-poly primitives, no animation rig (legs swing, poses are rotations).
