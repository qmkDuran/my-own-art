# Code style (Clean Code, SOLID, typed GDScript)

Checked by `python3 -I tools/check_code.py`, which `tools/run_all.sh` runs together with the headless smoke
test. Never commit when `tools/run_all.sh` does not print `ALL CHECKS PASS`.

## Rules

- **Meaningful names.** Say what a thing is or does: `can_see_target()`, `reach_toward()`, `known_snares`,
  `TacticalEval.best()`. No abbreviations beyond the obvious (`m` for the match in tests).
- **Small functions that do one thing.** Aim for 30 lines or fewer; the hard limit is 40. Long lines wrap at 120.
- **One responsibility per script (SOLID).** A script is about one thing: `Health` counts life, `Stealth` says if
  you are hidden, `SpitProjectile` flies and hits, `TacticalEval` scores places to stand, each bot state is its own class.
  Files stay under 400 lines.
- **Composition over deep inheritance.** A `Creature` *has* a `Health`, a `Stealth`, four `Ability` objects and a
  `CreatureModel`; the player and the bot are the same `Creature` driven by different controllers
  (`PlayerController` vs `BotBrain`). Inheritance is one level deep and only for real "is a" families
  (`Ability` -> `BiteAbility`, `BotState` -> `FightState`).
- **Dependencies are passed in.** `Main` builds everything and hands each object what it needs through `setup()`.
  The only global access is the data autoload `Tuning`, the sound autoload `NoiseBus`, and `Main.current`, which
  exists for the tests and screenshots only.
- **Data-driven tuning.** Every feel number (speeds, wind-ups, damage, ranges, cooldowns, AI timings, camera) is in
  `game/data/tuning.json`; the bot's utility curves, tactical weights, memory and difficulty levels in
  `game/data/ai.json`; the woods layout and colours in `game/data/woods.json`; the creatures' looks in
  `game/data/creatures.json`.
- **No magic numbers.** Logic never contains a bare decimal: it is a named `const` (shape, layout and drawing
  proportions that belong to one script) or a tuning value from JSON. The lint rejects bare decimals other than
  0.0, 0.5, 1.0 and 2.0.
- **No duplication (DRY).** Shared rules live once: line of sight in `Sight.clear()`, the HUD look in `HudStyle`,
  the ambush rule in `Creature.ambush_ready()`, random sides in `BotBrain.random_side()`.
- **No dead or commented-out code.** No TODOs, no `print` outside tests, no unused functions (the lint flags any
  function whose name is never used anywhere else).
- **Typed GDScript everywhere.** Every argument, return type and variable is typed; typed arrays where Godot
  allows them.
- **Comments explain why.** Every script starts with a `##` header saying what it is for; non-obvious functions
  get a `##` line.

## Folders (by feature, under `game/`)

| Folder | What lives there |
| --- | --- |
| `core/` | the match (`Main`, `MatchFlow`), autoloads (`Tuning`, `NoiseBus`), input map, physics layers |
| `creature/` | the shared creature body: `Creature`, `Stealth`, `CreatureModel`, `CreatureParts` |
| `player/` | the player's controls, view of the bot, lock-on |
| `camera/` | the third-person orbit camera |
| `bot/` | the bot's brain, legs (`BotMover`), reflexes, prediction |
| `bot/ai/states/` | one class per action the utility AI can choose |
| `bot/utility/` | facts, response curves and the utility selector |
| `bot/tactics/` | tactical position evaluation and its F3 markers |
| `bot/memory/` | the learned player model and the watcher that feeds it |
| `combat/` | health, effects, projectiles and hit effects |
| `combat/moves/` | `Move` and one class per move archetype; `MoveLibrary` reads `data/moves.json` |
| `perception/` | the shared seeing and hearing rules (`Visibility`), the bot's senses, line of sight |
| `world/` | terrain, water, cliffs, props, foliage, hiding spots, fire, ambient life, the woods builder |
| `ui/` | HUD widgets and screens |
| `data/` | JSON: tuning, moves, creatures (learnsets, loadouts), AI, woods layout |
| `tests/` | the smoke test, staging helpers and the screenshot script |

## Checks

- `tools/check_code.py`: typed signatures, function/file/line length, `##` headers, no print/TODO/commented code,
  no unused functions, no bare decimals.
- `game/tests/smoke_test.gd` (`--smoke`): the rules, played headless in the real scene.
- `tools/parse_check.sh`: every script parses (run first, so a broken script cannot hang the tests).
- `tools/moves_doc.py`: regenerates `MOVES.md` from `game/data/moves.json`.
- `tools/run_all.sh`: all of the above plus a headless duel. `tools/shoot.sh OUT_DIR`: the review stills (needs `xvfb-run`).
