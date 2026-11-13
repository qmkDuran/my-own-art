# Credits

- **3D models** (town, characters, creatures): generated for this project with the Meshy API (the user's account);
  see `game/assets/meshy/ASSETS.md` for each prompt, model and cost.
- **Effect assets** (`game/assets/vfx/`: the ember-burst and smoke-puff flipbooks, the swirl ring and spiral ribbon
  meshes): made for this project with Blender 4.2 (free, GPL; the outputs are our own) from the scripts in
  `tools/vfx/`.
- **Sound:** all synthesised in code (`game/audio/sound_synth.gd`). No audio files, no third-party sounds.
- **Shaders:** all written for this project. No code was copied from godotshaders.com or elsewhere; the techniques
  used (noise dissolve with a glowing edge, scrolling-gradient trails, SDF rings, fresnel-faded flames) are common
  public-domain ideas.
- **Engine:** Godot 4.7.2 (MIT).
