# MONSTER TAMER — code style (Clean Code / SOLID, typed GDScript)

Checked by `python3 -I tools/check_code.py` (part of `tools/run_all.sh`).

- **Names say what things are**: `region_stage()`, `pick_forced_switch()`, `befriend_reward()`. No cryptic
  abbreviations (short loop names like `c` for a creature or `b` for the battle scene are fine in small scopes).
- **Small functions that do one thing**: aim for 30 lines or fewer, hard limit 40. **Files focused**: 400 lines max;
  split by responsibility (the battle is a scene, a round, a move runner, menus, a view, cards and pure rules).
- **Everything typed**: every argument and return type, typed arrays where Godot allows.
- **Data, not code, for content**: creatures, moves, elements, items, trainers, dialogue, people, the terrain
  legend, maps and restoration stages live in `game/data/*.json`. Code holds only named constants for feel and
  layout (`const NAME: type = value`), never bare numbers in rules.
- **One palette**: colours come from `data/palette.json` (written by `art/build_art.py` from `art/palette.py`)
  through `UiKit.c("name")` / `Db.color()`. Colour literals are refused by the lint; no alpha blends in the UI.
- **Pure rules are separate from nodes**: `BattleRules`, `TrustRules`, `Growth`, `Bond`, `Stats`, `Restoration`
  and `MapGrid` hold no nodes and do not wait, so tests call them directly.
- **Open/closed through data and small classes**: a new creature or move is JSON; a new story event is one
  function in `StoryEvents`; a new screen subclasses `ScreenPanel`; a new map is a JSON grid plus objects.
- **Dependencies point inward**: autoloads are only `Db` (content), `Game` (state), `Audio` and `TestRunner`.
  Systems talk through signals (`Game.heal_stage_changed`, `MenuList.resolved`, `TimingRing.graded`) and small
  helpers that get the overworld passed in (`WorldInteractions`, `BattleLauncher`, `HealSequence`).
- **Comments explain why** (`##` doc comment at the top of every script and on non-obvious functions); no
  commented-out code, no TODOs, no `print` outside tests.
- **Folders by feature**: `scripts/core` (data, state, save, audio, input), `creatures`, `battle`, `world`, `story`,
  `ui`; tests in `game/tests`; tools in `tools/`; art and audio generators in `art/`.
