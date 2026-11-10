# New Jerusalem: one-screen Godot demo (Revelation 21-22)

You walk a glorified man (white linen robe, palm branch; Rev 7:9) around one screen of the holy city:
the jasper wall with its jewelled foundations, an open gate made of a single pearl, a street of gold,
the river of the water of life flowing out of the light of the throne (off-screen left), and trees of life on both banks.

A second scene, the throne room of heaven (Revelation 4-5), is chosen from the start menu.

## Run
    cd game
    <path>/Godot_v4.7.2-stable_linux.x86_64 --path .                      # start menu: 1 = holy city, 2 = throne room
    <path>/Godot_v4.7.2-stable_linux.x86_64 --path . -- --city            # straight into the city
    <path>/Godot_v4.7.2-stable_linux.x86_64 --path . -- --throne          # straight into the throne room
    <path>/Godot_v4.7.2-stable_linux.x86_64 --path . -- --demo            # city scripted walk (34 s), then quits
    <path>/Godot_v4.7.2-stable_linux.x86_64 --path . -- --throne --demo   # throne room scripted walk (33 s), then quits
    <path>/Godot_v4.7.2-stable_linux.x86_64 --path . -- --throne --closeup  # 20 s 3x camera tour of the wings

First time only (or after changing art): `--headless --path . --import`.

Controls: WASD or arrow keys, 8-way movement. Esc returns to the menu.
Zoom: mouse wheel or +/- (Z cycles): overview 1x (whole new earth), normal 2x, close 3x, always whole pixels.
City: cross the river on the bridge; walk north into the pearl gate to step out into the light.
Throne room: walk on the sea of glass; E kneels in worship (Rev 4:8). Every 16 s the elders cast their crowns before the throne (Rev 4:10).
Verse captions fade in at the bottom depending on where you stand.

## People (Rev 7:9)
The city now has a calm multitude of the redeemed: standing groups, a kneeling worshipper and palm-bearers near the gate light,
and two people walking slow loops. Press E near someone to hear a verse (KJV). Built by `art/build_walkers.py` and `art/build_people4.py`;
NPC logic in `game/scripts/actors/npc.gd`.

## The new earth (Isa 11, 35, 65; Rev 21:1, 24-26)
Walking into the light of the city's pearl gate now leads out onto the new earth; its pearl gate leads back in.
Also on the menu (3) or `-- --earth`; `-- --earth-demo` records the walk out of the city and a tour.
Built by `art/build_earth.py`, scene `game/scripts/scenes/earth.gd`.

## The city district (John 14:2; Rev 21:21-26)
From the garden walk south along the gold street: below lies the great street of gold running west to the light of the throne
(light only), dwellings with pearl doors on the street, people at their homes, and the nations carrying their gifts into the light.
The camera moves screen by screen so each view keeps its composition. `-- --district-demo` records a tour.

## Font
Captions use the pixel font **monogram** by datagoblin (CC0): `game/fonts/monogram.ttf`, licence note `game/fonts/LICENSE-monogram.txt`.

## Sound
All audio is original procedural audio (CC0), made by `art/audio/synth.py`; the kneel hymn arranges the public-domain
tune NICAEA (Dykes, 1861). Sources and licence: `game/audio/CREDITS.md`, `game/audio/LICENSE-CC0.txt`.
Playback goes through the small autoload `game/scripts/core/audio.gd` (music cross-fades, ambience loops, one-shots).

## Record (as used for out/)
    xvfb-run -a -s "-screen 0 1920x1080x24" <godot> --rendering-driver opengl3 --fixed-fps 60 \
        --write-movie ../art/frames/f.png --path . -- --demo
    ffmpeg -framerate 60 -i ../art/frames/f%08d.png -i ../art/frames/f.wav -c:v libx264 -pix_fmt yuv420p -crf 16 \
        -c:a aac -b:a 192k -shortest out.mp4      # the movie writer saves f.wav next to the frames

## Architecture
Thin scenes (`game/scripts/scenes/`) over shared components (core, actors, ui, talk, demo, camera, throne, earth).
Scene content (people, verses, zones, colliders, demo routes) is in `game/data/*.json`.
Full module map: `HEAVEN_NOTES.md` section 5.

## Tests
    GODOT=<godot binary> game/tests/run_smoke.sh                       # headless smoke test (all scenes)
    <godot> --headless --fixed-fps 60 --path game -- --demo --probe    # position probe log (regressions)

## Files
- `game/`: Godot 4.7 project (see Architecture).
- `game/art/`: final sprites (Resurrect 64 palette). `hero.png` rows: idle down/up/left, walk down/up/left (right = mirrored left).
- `art/common.py` + `art/build_*.py`: rebuild the final art from the PixelLab outputs in `art/raw/` (no API calls).
- `art/gen_*.py`, `art/mkchar.py`, `tools/anim.py`: the PixelLab generation scripts (paid; all routed through `tools/guard.py`).
- `spend_log.txt`: every paid call and the running total.
- `out/`: city screenshots + `new_jerusalem_walk.mp4` + `character_sheet_3x.png`; throne room `throne_screenshot_*.png` + `throne_room_walk.mp4` + `throne_sprites_3x.png`; with sound: `city_with_sound.mp4`, `throne_with_sound.mp4`, `wings_closeup.mp4`; `elder_heads_fix.png` (before/after); city district: `city_district.mp4`, `city_district_*.png`; new earth: `new_earth_v2.mp4` (larger map, zooming), `new_earth_v2_{overview_1x,normal_2x,close_3x}.png`, older `new_earth.mp4`, `new_earth_*.png`, `new_earth_sprites_3x.png`; people: `city_people.mp4`, `city_people_talk.png`, `city_people_bank.png`, `people_sheet_3x.png`, `people4_sheet_3x.png` (4-direction people).
