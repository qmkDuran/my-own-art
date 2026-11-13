# Credits

## Music (CC BY 4.0, attribution required)
All three tracks are by **Kevin MacLeod (incompetech.com)**, licensed under Creative Commons: By Attribution 4.0
(https://creativecommons.org/licenses/by/4.0/). Re-encoded to Ogg Vorbis and loudness-normalised for the game
(`game/assets/audio/music/`); otherwise unchanged.

| In game | Track | Source | Licence |
| --- | --- | --- | --- |
| Town theme | "The Path of the Goblin King" | https://incompetech.com/music/royalty-free/mp3-royaltyfree/The%20Path%20of%20the%20Goblin%20King.mp3 | CC BY 4.0 |
| Exploring the Gloomwood | "Pippin the Hunchback" | https://incompetech.com/music/royalty-free/mp3-royaltyfree/Pippin%20the%20Hunchback.mp3 | CC BY 4.0 |
| Combat and the boss | "Hall of the Mountain King" (Grieg, arranged/mixed by Kevin MacLeod) | https://incompetech.com/music/royalty-free/mp3-royaltyfree/Hall%20of%20the%20Mountain%20King.mp3 | CC BY 4.0 |

Attribution line for the game's credits screen:
"The Path of the Goblin King", "Pippin the Hunchback", "Hall of the Mountain King" Kevin MacLeod (incompetech.com),
licensed under Creative Commons: By Attribution 4.0 License, http://creativecommons.org/licenses/by/4.0/

## Sound effects
- **"80 CC0 RPG SFX"** by **rubberduck**, OpenGameArt.org, **CC0** (public domain):
  https://opengameart.org/content/80-cc0-rpg-sfx. Used (re-encoded, mono, loudness-normalised, in
  `game/assets/audio/sfx/`): spell_01, spell_02, spell_fire_03, spell_fire_04, spell_fire_06, item_gem_01,
  item_gem_03, item_gem_04, metal_01, creature_misc_01, creature_misc_06, creature_slime_02, creature_die_01,
  creature_roar_02, stones_03. Each ability's sound is a layered cue mixing these with code-made voices.
- **Synthesised in code** (`game/audio/sound_synth.gd`): the ambience (an occasional distant cricket, the
  fountain, the music box, rain), footsteps, and the plucks, thumps, chimes, shimmers, swells and crackles layered
  into the combat cues.

## Art
- **3D models** (town, characters, enemies, the town gate and ruins): generated for this project with the Meshy API
  (the user's account); see `game/assets/meshy/ASSETS.md` for each prompt, model and cost.
- **Effect assets** (`game/assets/vfx/`: the ember-burst and smoke-puff flipbooks, the swirl ring and spiral ribbon
  meshes): made for this project with Blender 4.2 (free, GPL; the outputs are our own) from the scripts in
  `tools/vfx/`.
- **Shaders:** all written for this project. No code was copied from godotshaders.com or elsewhere; the techniques
  used (noise dissolve with a glowing edge, scrolling-gradient trails, SDF rings, fresnel-faded flames, hexagon
  bubbles) are common public-domain ideas.

## Engine
Godot 4.7.2 (MIT).
