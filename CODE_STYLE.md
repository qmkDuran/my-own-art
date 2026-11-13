# Code style (Clean Code, SOLID, typed GDScript)

Checked by `python3 -I tools/check_code.py`, which `tools/run_all.sh` runs together with a parse check and the
headless smoke test. Never commit unless `tools/run_all.sh` prints `ALL CHECKS PASS`.

## Rules
- **Meaningful names**, **small functions** (aim for 30 lines, hard limit 40), lines of 120 characters at most,
  files of 400 lines at most.
- **One responsibility per script.** `LampLight` is one light that flickers, `LightBudget` decides which lights cast
  shadows, `Weather` eases the rain mix, `TownBuilder` places the Meshy town, `GroundBuilder` builds the code-made
  ground, `Townsperson` lives one routine.
- **Composition over inheritance.** The player and every townsperson *have* a `CharacterModel`; the player *has* a
  `HandLantern`. Inheritance is one level deep (engine types only).
- **Dependencies are passed in.** `Main` builds everything and hands each object what it needs through `setup()`.
  The only globals are the data autoload `Tuning`, the `TestRunner` autoload and `Main.current` (tests only).
- **Data-driven.** Feel numbers in `data/tuning.json`, the whole night look in `data/lighting.json`, the town layout
  in `data/town.json`, the Meshy assets in `data/assets.json`, routines in `data/npcs.json`, sound in `data/audio.json`.
- **No magic numbers.** The lint rejects bare decimals in logic other than 0.0, 0.5, 1.0 and 2.0: name them as
  constants or move them to data.
- **No dead or commented-out code**, no TODOs, no `print` outside tests, no unused functions (the lint checks).
- **Typed GDScript everywhere**; every script starts with a `##` header saying what it is for.

## Folders (by feature, under `game/`)
| Folder | What lives there |
| --- | --- |
| `core/` | `Main`, the `Tuning` autoload, input map, physics layers |
| `world/` | the Meshy asset library, town and ground builders, box helpers, surface materials, fountain water |
| `lighting/` | the night environment, moonlight, lamp lights and the shadow budget |
| `weather/` | the rain toggle |
| `effects/` | fireflies, dust motes, rain particles and their shared parts |
| `characters/` | the rigged-character model shared by the player and townsfolk |
| `player/` | the player body, controller and hand lantern |
| `camera/` | the third-person orbit camera |
| `npc/` | townsfolk routines and the cat |
| `audio/` | the procedural sound synth and the ambience |
| `ui/` | the HUD |
| `shaders/` | stone, water, Meshy asset and sky shaders |
| `data/` | JSON |
| `assets/meshy/` | the Meshy GLBs and `ASSETS.md` |
| `tests/` | the smoke test, the stills script and the test runner |
