# Creature-trainer demo: notes

A playable combat test for the creature-trainer action RPG in VISION.md. It answers one question: **is the combat
fun and fair?** Built on the Lanternfall foundation (Godot 4.7.2, typed GDScript, code-made art). How to play:
PLAY.md. Wider idea list: BATTLE_IDEAS.md.

## What is in
- **Gate Hall** (the start): four gates into arenas, a sign per gate with a checklist, a difficulty lever, an
  opponent switch (wild 1v1 / trainer 3v3), a team station (pick 3 of 6, level 5/15/30, 4 active moves), a Sync
  Lens stand (basic / plus) and a door to the route. The hall heals.
- **Arenas** (`data/tamer/arenas.json`): 24x12 walled squares of 32 px cells, each a list of painted features.
  Meadow (tall grass, cover rocks), Riverbank (shallow water, a deep channel, a breakable bridge, mud), Forest
  (trees as pillars, thickets, roots, fog), Ruins (a ledge with ramps, pillars, cracked floor, thorns, walls).
  The canopy arena was not built.
- **Battles**: a UV swirl transition, a fixed camera on the arena, trainers outside the walls, 1v1 at a time, back
  to the exact spot afterwards. Route health carries over; the hall and camp heal.
- **Combat**: physical (close, fills the 3-segment gauge), special (costs gauge, wind-up, true skillshot), status
  (hold to channel; strength by hold time, min 25%; no move or dodge; a hit cancels). Buffs and debuffs
  (`effects.json`) each with a cost, icons with timers on both creatures and the card. Advantage-only elements
  (x1.3, "Strong hit!"). Stagger. Swaps cost 1 segment plus a 3 s cooldown. Home terrain per species. Terrain
  that moves change (burn, flatten, clear fog, break rock/bridge/floor, vine walls). Wall slams, ledge falls, thorns.
- **Opponents** (`FoeBrain` + `FightStyle` + `FoeTactics`) by tier (`tamer.json` "ai_tiers"): reaction time,
  dodging your wind-ups, leading shots, cover when hurt, high ground, hiding in grass, saving gauge, channelling,
  tell length. Trainers (`OpponentTrainer`) send the best matchup, heal once, swap out when low or (Hard) to counter.
- **Route**: Lanternfall's generated meadow with wild creatures by temperament (`RouteBrain`), the rival Ivo
  (Accept/Decline), the camp (moves, stat upgrades, Sanctuary), items outside battle.
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
| `sync_lens.gd`, `evolution_ceremony.gd`, `rival_trainer.gd`, `hall_door.gd`, `camp.gd`, `tamer_spawner.gd` | One system each |
| `tamer_input.gd`, `tamer_keys.gd`, `tamer_guide.gd`, `aim_preview.gd` | Input; key actions; tracker; move ghosts |
| `ui/` | `TamerHud`, `CreatureCard`, `TeamStrip`, `TeamStation`, `AskDialog`, `EffectIcons`, `CreatureTag`, `CampPanel`, `SanctuaryPanel`, `CreatureInfoPanel`, `MoveIcon`, `MoveText`, `CreaturePortrait` |

The hall and the arenas live in the same scene far from the route (`GateHall.HALL_ORIGIN`,
`ArenaBattle.ARENA_ORIGIN`); only the active place is visible and processing.

## Removed in the arena pass
`slow_time.gd` and its shader, `battle_ring.gd`, `battle_mode.gd`, `starter_meeting.gd` and `MeetBrain`,
`WildBrain` (became `FoeBrain`), `material_pickup.gd` (materials go straight to the bag), the perfect dodge, the
perfect swap, bond meters and bond moves (now level-25 signature moves), in-battle items, the "Resisted" path,
the X retreat, the vignette and fade, the old rival trainer flow, and the tests for all of them.

## Checks and stills
- `bash tools/run_all.sh`: Lanternfall's checks plus `-- --tamer-smoke` (`tests/tamer_smoke.gd`,
  `tamer_smoke_combat.gd`, `tamer_smoke_world.gd`, about 90 checks): the hall and station, a gate (transition in and
  out, walls hold, trainer outside, back to the exact spot, hall heals), route health carrying over, a skillshot
  that misses and one that hits, channelling (no move or dodge, a hit cancels, longer is stronger), buffs and
  debuffs with costs, advantage only, home terrain, terrain changes, swap cost and cooldown, each AI tier fighting,
  a 3v3 trainer win, Sync Lens tiers, evolution, XP, F1 shiny, the rival's Accept/Decline, temperaments, losing.
- `tools/tamer_shots.sh OUT_DIR [shot ...]`: hall, station, transition, meadow, riverbank, forest, ruins, channel,
  effects, trainer, route, evolution. Stills only.

## Known gaps (honest)
- **Not played by a person yet.** Feel numbers (speeds, wind-ups, gauge fill, AI tiers) live in `data/tamer/*.json`.
- Hard AI does not bait, push you into hazards or use walls on purpose; it leads shots, dodges wind-ups, takes
  cover and high ground, hides in grass, saves gauge and counter-swaps.
- No Tide creature in the six, so no flooding move; no crystals (Echo breaks rock instead).
- The evolved Ratel Warden reuses the honey badger's sprite (bigger, renamed, stronger).
- Elements with no creature yet (Tide, Shade) only exist in the chart.
- No music; nothing is saved; the HUD was checked at 1920x1080 only.
