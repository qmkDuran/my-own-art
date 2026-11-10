# The Great Prince (prototype)

A small action RPG zone in Godot 4.7.2. In the time of distress (Daniel 12:1) people pray in a ruined suburb at night,
and the archangel Michael is sent in answer (Daniel 10:12-13). He fights the spiritual forces of evil (Ephesians 6:12),
protects those who pray, and is clothed in the armour of God (Ephesians 6:13-17).

## Run
    <godot> --path game                         # play
    <godot> --path game -- --demo               # plays itself for 32 s with the real controls (out/arpg_controls.mp4)
    GODOT=<godot> game/tests/run_smoke.sh       # headless smoke test
    xvfb-run -a <godot> --rendering-driver opengl3 --path game -- --demo --shots   # screenshots into out/

Controls (click-to-move):
- Hold the left button on the ground to walk toward the cursor; click an enemy to go to it and strike.
- Hold Shift to stand still and strike (left button) or cast toward the cursor.
- Right button: Descent. Q W E R: Rebuke, Shield of Faith, Trumpet Call, Radiance (1-4 also work).
- Space dodge. I inventory, K skills, P stars, Esc pause. Items: walk over them or click their names.
- Keyboard movement (WASD/arrows) is an option in game/data/settings.json (off by default).

## Credits
- Scripture: Scripture quotations taken from The Holy Bible, New International Version® NIV® Copyright © 1973, 1978, 1984, 2011 by Biblica, Inc.™ Used by permission. All rights reserved worldwide.
- Art: Michael, demons and item icons generated with PixelLab and finished by hand; suburb tiles, houses and props from
  Project R's exterior art (same author, Resurrect 64 palette); praying people from the heaven demo.
- Font: monogram by datagoblin (CC0), extended (see game/fonts/LICENSE-monogram.txt).
- Audio: original procedural audio (CC0), art/audio/synth.py.

Details: ARPG_NOTES.md.
