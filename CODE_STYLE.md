# LANTERNFALL — code style (Clean Code / SOLID, typed GDScript)

Checked by `python3 -I tools/check_code.py` (part of `tools/run_all.sh`).

- **Names say what things are**: `light_radius()`, `free_spots()`, `spec_block()`. No abbreviations beyond the
  obvious (`p` for the player in short scopes, `g` for the game, `z` for the zone layout).
- **Small functions that do one thing**: aim ≤ 30 lines, hard limit 40. **Files focused**: ≤ 400 lines; split by
  responsibility (the generator is five steps, each a class).
- **Everything typed**: every argument and return type; typed arrays where Godot allows.
- **Data, not code, for content**: names, numbers, trees, items, enemies, biome rules and words live in
  `game/data/*.json`. Code holds only named constants for feel/layout (`const NAME: type = value`), never bare
  magic numbers in logic.
- **Open/closed through composition**: a new enemy behaviour is a new `EnemyBrain`; a new skill a new `Skill`
  subclass registered in `SkillSystem`; a new interactable a subclass of `Interactable`; a new zone a biome JSON.
- **Dependencies point inward**: systems talk through signals (`Progression.leveled`, `Spawner.killed`,
  `Waylamp.lit_up`) and small interfaces (`light_pos()/light_radius()` for light sources). The only global access
  is `Game.current` (documented service locator) and the autoloads `Audio` and `TestRunner`.
- **Comments explain why** (`##` doc comments on every script and on non-obvious functions); no commented-out code,
  no TODOs, no `print` outside tests.
- **Tests for the rules**: stats math, damage and Shrouded, the Light, skills and tree effects, loot rolls,
  equipment, drop placement and label stacking, save/load (`--smoke`); layout rules (`--layout`); UI layout
  (`--ui`); art rules (`check_art.py`).
- Folders by feature: `core/ world/ actors/ combat/ skills/ items/ ui/ story/ demo/`, tests in `game/tests/`,
  tools in `tools/`, art and audio generators in `art/`.
