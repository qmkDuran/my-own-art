# Creature-trainer demo: notes

> **Project stopped.** The user ended the creature-trainer ARPG. What was learned: across four combat iterations
> (cooldown spam, Shift steering, the gauge model with slow-time, and the arena skillshot model) real-time
> creature combat kept feeling confusing or spammy. Controlling a creature in real time while a trainer stands
> by never became clearly readable and fun. The balance bot also showed that AI-vs-AI fights are close to
> deterministic, so small edges (an element advantage) turn into lopsided matchups. The code and these notes stay
> as a reference.

A playable combat test for the creature-trainer action RPG in VISION.md. It answers one question: **is the combat
fun and fair?** Built on the Lanternfall foundation (Godot 4.7.2, typed GDScript, code-made art). How to play:
PLAY.md. Wider idea list: BATTLE_IDEAS.md.

## What is in
- **Gate Hall** (the start): four gates into arenas, a sign per gate with a checklist, a difficulty lever, an
  opponent switch (wild 1v1 / trainer 3v3), a team station (pick 3 of 6, level 5/15/30, 4 active moves), a Sync
  Lens stand (basic / plus) and a door to the route. The hall heals.
- **Arenas** (`data/tamer/arenas.json`): walled squares of 32 px cells (medium 22x11, large 27x13, picked in the
  hall; both fit at a crisp zoom of 1), each a list of pieces from the library (`data/tamer/pieces.json`: grass, rock,
  pillar, tree, mud, water, thicket, roots, thorns, cracked floor, river, ledge), so a new arena is a data file.
  Meadow (tall grass, cover rocks), Riverbank (shallow water, a deep channel, a breakable bridge, mud), Forest
  (trees as pillars, thickets, roots, fog), Ruins (a ledge with ramps, pillars, cracked floor, thorns, walls).
  The canopy arena was not built.
- **Equal footing**: your creatures and the AI's use the same stats, moves, wind-ups (telegraphed for both),
  gauge, lockout, swap cost and cooldown, entry strike, buff limits and bonus cap; no items in battle for either.
  AI tiers change decisions only. Bond is parked.
- **Battles**: a UV swirl transition, a fixed camera on the arena, trainers outside the walls, 1v1 at a time, back
  to the exact spot afterwards. Route health carries over; the hall and camp heal.
- **Combat**: physical (close, fills the 3-segment gauge), special (costs gauge, wind-up, true skillshot), status
  (hold to channel; strength by hold time, min 25%; no move or dodge; a hit cancels). One buff and one debuff at a
  time (`effects.json`), each with a cost: gold or purple rings at the feet, icons with timers. Advantage-only
  elements (x1.3, "Strong hit!"); element + terrain + buffs capped at +40%. Stagger. Swaps cost 1 segment plus a
  3 s cooldown. Home terrain per species. Creatures 1.5x in arenas. Terrain transforms (`TerrainChange`): grass
  burns and spreads, ash and smoke, burnt field, regrows; rock to rubble; bridge to water; cracked floor to pit;
  Gale flattens and clears smoke and fog; Bloom regrows. Wall slams, ledge falls, thorns.
- **Opponents** (`FoeBrain` + `FightStyle` + `FoeTactics`) by tier (`tamer.json` "ai_tiers"): reaction time,
  pace, dodging your wind-ups, leading shots, cover when hurt, high ground, hiding in grass, saving gauge,
  channelling; Hard also baits, pushes you toward hazards and denies your home terrain. Four movement styles in
  data (`styles.json`: brawler, kiter, tank, flanker). Trainers (`OpponentTrainer`) send the best matchup and swap
  by your rules (gauge, cooldown). Wild creatures struggle while being synced. Alphas (bigger, glowing, more life,
  their signature move, double rewards): one on the route, and the hall's switch. Quick win: 8+ levels above a
  wild one, walking into it beats it on the map.
- **Route**: Lanternfall's generated meadow with wild creatures by temperament (`RouteBrain`), the rival Ivo
  (Accept/Decline), the camp (moves, stat upgrades, Sanctuary), items outside battle.
- **The trainer** calls the swaps and shouts on big moments from the arena edge, and runs the Sync Lens (F on a
  weakened creature: a 2.5 s scan; it struggles; a hit on your creature breaks it).
- **Progression**: XP and levels, moves unlocked by level (signature move at 25), 4 active moves, the honey
  badger's evolution at 16 (Ratel Warden, bigger and stronger, a short ceremony), Sync Lens tiers by rarity,
  shinies at 1 in 4096 (F1 dev).

## Architecture (`game/scripts/tamer/`, data in `game/data/tamer/`)
| Script | Job |
|---|---|
| `tamer_game.gd` (TamerGame) | Scene root: builds the route, hall and systems; routes events (encounter, battle over, team wiped). `TamerGame.current` is the documented service locator |
| `area_switch.gd` | Which place is active (hall, route, arena): visibility, processing, the trainer, the camera bounds |
| `transition.gd` + `shaders/swirl.gdshader` | The battle swirl |
| `arena/` | `ArenaLayout` (feature grid with an origin), `ArenaView`, `ArenaPalette`, `ArenaFog`, `Arena` (build, spots, terrain changes), `TerrainRules` (speed, damage, range, hiding, hazards, home terrain), `ArenaBattle` (start, send, swap, end), `OpponentTrainer`, `GateHall`, `HallDecor` |
| `creature.gd`, `creature_combat.gd`, `creature_effects.gd`, `creature_growth.gd`, `stagger_bar.gd` | A creature on the field; damage; buffs and debuffs; XP, moves and evolution; stagger |
| `creature_record.gd`, `team.gd` | Creature and team state |
| `brains/` | `ControlledBrain` (you), `FoeBrain` + `FoeTactics` + `FightStyle` + `Telegraphs` (opponents), `RouteBrain` (temperaments), `PartnerBrain`, `CampBrain` |
| `moves/` | `MoveBook` maps a move's kind to a `MoveKind`: strike, bolt, lunge, burst, guard, status, wall |
| `team_field.gd` | Summon, swap, knock-out and step-in, items outside battle, level-up and evolution |
| `arena/terrain_change.gd` | How the ground changes: burning, spreading, ash, regrowth, rubble, pits |
| `sync_lens.gd`, `evolution_ceremony.gd`, `trainer_shout.gd`, `rival_trainer.gd`, `hall_door.gd`, `camp.gd`, `tamer_spawner.gd` | One system each |
| `tamer_input.gd`, `tamer_keys.gd`, `tamer_guide.gd`, `aim_preview.gd` | Input; key actions; tracker; move ghosts |
| `ui/` | `TamerHud`, `CreatureCard`, `TeamStrip`, `TeamStation`, `AskDialog`, `EffectIcons`, `StatusRings`, `CreatureTag`, `CampPanel`, `SanctuaryPanel`, `CreatureInfoPanel`, `MoveIcon`, `MoveText`, `CreaturePortrait` |

The hall and the arenas live in the same scene far from the route (`GateHall.HALL_ORIGIN`,
`ArenaBattle.ARENA_ORIGIN`); only the active place is visible and processing.

## Removed in the arena pass
`slow_time.gd` and its shader, `battle_ring.gd`, `battle_mode.gd`, `starter_meeting.gd` and `MeetBrain`,
`WildBrain` (became `FoeBrain`), `material_pickup.gd` (materials go straight to the bag), the perfect dodge, the
perfect swap, bond meters and bond moves (now level-25 signature moves), in-battle items, the "Resisted" path,
the X retreat, the vignette and fade, the old rival trainer flow, and the tests for all of them.

## Removed in the fix-all pass
Bond (meter, Resolve, early signature unlock, camp pet and feed): parked. The wild stat penalties, AI move
cooldowns, the AI tell multiplier and the opposing trainer's heal (equal footing). The old `paint` arena format
(now pieces) and the skirmisher style (now kiter).

## Checks and stills
- `bash tools/run_all.sh`: Lanternfall's checks plus `-- --tamer-smoke` (`tests/tamer_smoke.gd`,
  `tamer_smoke_combat.gd`, `tamer_smoke_world.gd`, about 110 checks): the hall and station, a gate (transition in and
  out, walls hold, trainer outside, back to the exact spot, hall heals), route health carrying over, a skillshot
  that misses and one that hits, channelling (no move or dodge, a hit cancels, longer is stronger), buffs and
  debuffs with costs, advantage only, home terrain, terrain changes, swap cost and cooldown, each AI tier fighting,
  a 3v3 trainer win, Sync Lens tiers, evolution, XP, F1 shiny, the rival's Accept/Decline, temperaments, losing.
- `tools/tamer_shots.sh OUT_DIR [shot ...]`: hall, station, transition, meadow, riverbank, forest, ruins, channel,
  effects, burn, catch, large, trainer, route, evolution, alpha, quick_win. Stills only.
- `-- --tamer-balance` (headless, `--fixed-fps 30`): every creature x arena x tier, bot vs AI; writes the table
  below.

## Known gaps (honest)
- **Not played by a person yet.** Feel numbers (speeds, wind-ups, gauge fill, AI tiers) live in `data/tamer/*.json`.
- Hard's bait is honest (it stands in your range and dodges), not a fake wind-up, which equal footing rules out.
  Its push picks a spot but its knockback is the move's own, so slams are not guaranteed.
- A weakened wild creature stops fighting (the catch window): the one deliberate asymmetry, for syncing.
- The balance bot plays both sides with the same AI, so fights are close to deterministic: any small edge (an
  element advantage) shows up as a lopsided matchup. A person will vary far more.
- No Tide creature in the six, so no flooding move; no crystals (Echo breaks rock instead).
- The evolved Ratel Warden reuses the honey badger's sprite (bigger, renamed, stronger).
- Elements with no creature yet (Tide, Shade) only exist in the chart.
- No music; nothing is saved; the HUD was checked at 1920x1080 only.

## Balance (`--tamer-balance`)
Targets: each creature wins 40-60% at Normal and 25-45% on Hard; no single matchup or arena over 70% or under 30% at Normal. `tools/tamer_balance.sh LABEL` reruns it (four headless processes).

<!-- balance:before:start -->

**before** (240 fights; bot at Normal vs the AI at each tier, level 10, 1v1, 40 s cap, every ordered pair in every arena).

| Creature | Normal (win / avg s) | Hard (win / avg s) | Forest | Meadow | Riverbank | Ruins |
|---|---|---|---|---|---|---|
| Aye-aye | 0% / 26 | 0% / 25 | 0% | 0% | 0% | 0% |
| Cuttlefish | 20% / 26 | 10% / 29 | 20% | 20% | 20% | 20% |
| Honey Badger | 80% / 17 | 80% / 22 | 80% | 80% | 80% | 80% |
| Maned Wolf | 10% / 25 | 0% / 25 | 0% | 0% | 20% | 20% |
| Pangolin | 60% / 27 | 30% / 34 | 20% | 80% | 60% | 80% |
| Tasmanian Devil | 80% / 18 | 50% / 29 | 80% | 80% | 80% | 80% |

Normal matchups (row's win rate against the column, both directions pooled):

| vs | Aye-aye | Cuttlefish | Honey Badger | Maned Wolf | Pangolin | Tasmanian Devil |
|---|---|---|---|---|---|---|
| Aye-aye | - | 0% | 0% | 0% | 0% | 0% |
| Cuttlefish | 12% | - | 0% | 100% | 0% | 0% |
| Honey Badger | 100% | 100% | - | 100% | 25% | 100% |
| Maned Wolf | 50% | 0% | 0% | - | 0% | 0% |
| Pangolin | 88% | 75% | 50% | 100% | - | 12% |
| Tasmanian Devil | 100% | 100% | 0% | 100% | 88% | - |

Outside the targets: Aye-aye 0% at Normal; Aye-aye 0% at Hard; Aye-aye 0% in the forest; Aye-aye 0% in the meadow; Aye-aye 0% in the riverbank; Aye-aye 0% in the ruins; Cuttlefish 20% at Normal; Cuttlefish 10% at Hard; Cuttlefish 20% in the forest; Cuttlefish 20% in the meadow; Cuttlefish 20% in the riverbank; Cuttlefish 20% in the ruins; Honey Badger 80% at Normal; Honey Badger 80% at Hard; Honey Badger 80% in the forest; Honey Badger 80% in the meadow; Honey Badger 80% in the riverbank; Honey Badger 80% in the ruins; Maned Wolf 10% at Normal; Maned Wolf 0% at Hard; Maned Wolf 0% in the forest; Maned Wolf 0% in the meadow; Maned Wolf 20% in the riverbank; Maned Wolf 20% in the ruins; Pangolin 20% in the forest; Pangolin 80% in the meadow; Pangolin 80% in the ruins; Tasmanian Devil 80% at Normal; Tasmanian Devil 50% at Hard; Tasmanian Devil 80% in the forest; Tasmanian Devil 80% in the meadow; Tasmanian Devil 80% in the riverbank; Tasmanian Devil 80% in the ruins; Aye-aye vs Cuttlefish 0%; Aye-aye vs Honey Badger 0%; Aye-aye vs Maned Wolf 0%; Aye-aye vs Pangolin 0%; Aye-aye vs Tasmanian Devil 0%; Cuttlefish vs Honey Badger 0%; Cuttlefish vs Maned Wolf 100%; Cuttlefish vs Pangolin 0%; Cuttlefish vs Tasmanian Devil 0%; Honey Badger vs Maned Wolf 100%; Honey Badger vs Pangolin 25%; Honey Badger vs Tasmanian Devil 100%; Maned Wolf vs Pangolin 0%; Maned Wolf vs Tasmanian Devil 0%; Pangolin vs Tasmanian Devil 12%.

<!-- balance:before:end -->


<!-- balance:after:start -->

**after** (480 fights; bot at Normal vs the AI at each tier, level 10, 1v1, 40 s cap, every ordered pair in every arena).

| Creature | Normal (win / avg s) | Hard (win / avg s) | Forest | Meadow | Riverbank | Ruins |
|---|---|---|---|---|---|---|
| Aye-aye | 45% / 24 | 30% / 28 | 20% | 50% | 50% | 60% |
| Cuttlefish | 42% / 24 | 18% / 26 | 40% | 30% | 60% | 40% |
| Honey Badger | 55% / 27 | 48% / 32 | 30% | 40% | 90% | 60% |
| Maned Wolf | 42% / 30 | 35% / 33 | 40% | 40% | 60% | 30% |
| Pangolin | 50% / 31 | 30% / 35 | 20% | 30% | 60% | 90% |
| Tasmanian Devil | 55% / 26 | 62% / 28 | 30% | 60% | 60% | 70% |

Normal matchups (row's win rate against the column, both directions pooled):

| vs | Aye-aye | Cuttlefish | Honey Badger | Maned Wolf | Pangolin | Tasmanian Devil |
|---|---|---|---|---|---|---|
| Aye-aye | - | 44% | 31% | 44% | 31% | 31% |
| Cuttlefish | 44% | - | 25% | 50% | 50% | 25% |
| Honey Badger | 62% | 62% | - | 31% | 12% | 38% |
| Maned Wolf | 50% | 38% | 56% | - | 0% | 38% |
| Pangolin | 62% | 44% | 44% | 75% | - | 12% |
| Tasmanian Devil | 69% | 69% | 31% | 44% | 62% | - |

Outside the targets: Aye-aye 20% in the forest; Cuttlefish 18% at Hard; Honey Badger 48% at Hard; Honey Badger 90% in the riverbank; Pangolin 20% in the forest; Pangolin 90% in the ruins; Tasmanian Devil 62% at Hard; Cuttlefish vs Honey Badger 25%; Cuttlefish vs Tasmanian Devil 25%; Honey Badger vs Pangolin 12%; Maned Wolf vs Pangolin 0%; Pangolin vs Tasmanian Devil 12%.

<!-- balance:after:end -->
