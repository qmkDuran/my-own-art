# The Great Prince (prototype)

A small action RPG zone in Godot 4.7.2. In the time of distress (Daniel 12:1) people pray in a ruined suburb at night,
and the archangel Michael is sent in answer (Daniel 10:12-13). He fights the spiritual forces of evil (Ephesians 6:12),
protects those who pray, and is clothed in the armour of God (Ephesians 6:13-17).

## Run
    <godot> --path game                         # play
    <godot> --path game -- --demo               # plays itself for 46 s with the real controls (out/arpg_demo.mp4)
    GODOT=<godot> game/tests/run_smoke.sh       # headless smoke test
    xvfb-run -a <godot> --rendering-driver opengl3 --path game -- --demo --shots   # screenshots into out/

Controls (click-to-move):
- Hold the left button on the ground to walk; click an enemy to strike it; click an item's name to take it;
  click a crate, lockbox or waystone to use it. Hold Shift to stand and strike/cast toward the cursor.
- Right button and Q W E R: the skills on those keys (1-4 also work). Space dodge.
- I inventory, K skills (masteries, attributes, keys, respec), P stars, Alt labels, Esc pause.
- Options in game/data/settings.json: keyboard movement, camera zoom, screen shake, auto-pickup.
- Progress is saved in user:// (start with `-- --fresh` to ignore it).

## Credits
- Scripture: Scripture quotations taken from The Holy Bible, New International Version® NIV® Copyright © 1973, 1978, 1984, 2011 by Biblica, Inc.™ Used by permission. All rights reserved worldwide.
- Art: Michael, demons and item icons generated with PixelLab and finished by hand; suburb tiles, houses and props from
  Project R's exterior art (same author, Resurrect 64 palette); praying people from the heaven demo.
- Font: monogram by datagoblin (CC0), extended (see game/fonts/LICENSE-monogram.txt).
- Audio: original procedural audio (CC0), art/audio/synth.py.

Details: ARPG_NOTES.md.
