# Project R (Project Revelation)

A grounded, cinematic top-down pixel-art survival-action story inspired by the Book of Revelation.
Summer 2030, Halvern Ridge (a made-up suburb outside New York City). Godot 4.7.2.

Work of fiction. No real people, companies or products are depicted.

This branch holds the **foundation**: every core system, data-driven, with placeholder art, and a
playable greybox of Chapter 1 ("Night One") wired to the story script in `docs/` and the sounds in `audio/`.

---

## Run it

```bash
godot --path .                                   # play (disclaimer -> main menu)
godot --headless --path . --import               # (re)import assets, e.g. after adding art or audio
godot --headless --path . res://tests/smoke_test.tscn      # opens every scene and zone state
godot --headless --path . res://tests/chapter1_driver.tscn # plays Chapter 1 automatically
godot --path . res://tests/chapter1_driver.tscn -- --shots=/some/dir   # same, saving PNGs
python3 tests/layout_check.py                    # layout logic of every zone (see "Layout check")
python3 tests/layout_check.py --self-test        # proves the check catches deliberately broken layouts
xvfb-run -a godot --rendering-driver opengl3 --path . res://tests/zone_shots.tscn -- --out=/some/dir
                                                 # 1920x1080 screenshots of every zone/story state
```

The driver prints `DRIVER PASS` / `DRIVER FAIL: ...` and exits with 0 / 1. Both tests should print
no `ERROR` or `WARNING` lines. Saves go to `user://save_slot1.json`.

Display: 960x540 view, integer scaling (2x at 1080p), `canvas_items` stretch, nearest filtering,
pixel snapping, GL Compatibility renderer. Tiles are 32 px, characters about 64 px, portraits 128 px.

## Controls

| Action | Keyboard / mouse | Gamepad |
|---|---|---|
| Move (8 directions) | WASD / arrows | Left stick / d-pad |
| Run | Shift (hold) | LB / LT |
| Interact, advance dialogue | E (also Enter in dialogue) | A |
| Attack (melee swing) | J / left mouse | X |
| Dodge roll (i-frames) | Space | B |
| Inventory | I / Tab | Y |
| Choices | Up / down + E | Stick + A |

Bindings live in code in `src/autoload/controls.gd`.

## What is in the foundation

- **Player**: 8-direction movement with acceleration, run, dodge roll with invulnerability, melee
  swing (hitbox from the equipped weapon's data), interaction prompt, smooth follow camera with
  screen shake, y-sorting, footsteps by surface.
- **Hero picker** (New Game): male/female, 6 skin tones, 3 hairstyles per body. Skin is a palette
  swap (shader) applied to the hero **and to Mom's sprite and portrait** so the family matches. Hair
  is its own sprite layer drawn over the body for every frame. Choices are saved in the game state.
  The hero has **no dialogue portrait**: hero lines show only the name; everyone else has a 128 px portrait.
- **Interaction**: examine (text or a dialogue node), pick up items, talk to NPCs, doors between
  zones with a fade, locked doors with a reason, walk-in triggers.
- **Dialogue**: box with portrait, speaker name, typed text, choices that set flags, conditional
  lines, and cinematic commands. Scripts are plain-text `.dlg` files (format below).
- **Inventory**: 12-slot grid; items are data (food, water, medicine, bat, mop handle, keys,
  Mom's card, battery, Bible, letter, ...). Use heals, equips or reads.
- **Combat**: hitbox / hurtbox components, hit-stop, knockback, hit flash, screen shake. One
  data-driven `Enemy` class (approach, wind-up telegraph with a red "!", lunge attack, recover,
  flee at low health). Types: `looter`, `wade` (the store looter), `dog` (the stray). Player
  health, death, and retry at the last checkpoint.
- **Lighting**: `CanvasModulate` ambient per zone and story state, additive `PointLight2D` pools
  (porch, street, window, lamp, ceiling, fluorescent, TV, fire, hazard, emergency) with flicker and
  pulse, light groups that scripts switch off ("the lights cut"), and a vignette shader.
- **Game state**: flags (bool or values), inventory, hero choices, chapter, checkpoint and
  save/load (JSON in `user://`), Continue from the menu, chapter title cards and time-skip cards.
- **AudioManager**: music crossfade, ambience layers, SFX by name with random numbered variants;
  reads whatever is in `res://audio/`; a missing name is logged once and ignored.
- **Chapter 1 greybox**: the house (bedroom, kitchen, living room), Linden Court / Ridge Road, and
  Ridge Corner Market, all built from data, with the story beats wired (see below).
- **Menus**: "work of fiction" disclaimer, main menu (New Game with picker, Continue, Quit).

### Chapter 1 flow in the greybox

Bedroom (cold open, phone, examine objects) -> kitchen: set the table (cupboard, drawer, fridge)
-> dinner with Mom (grace and faith choices) -> card from the hook -> goodbye at the door (last-words
choice) -> Linden Court at dusk (Walt, the Okoros, Noah, Mrs. Albright and Biscuit) -> Ridge Corner
Market: milk, bread, 9-volt -> checkout: Hollis stops mid-word and is gone, four seconds of total
silence, crash, power cut, alarms -> Wade (fight / give the bag / talk him down) -> the street in
chaos (Biscuit the panicked dog, Dana in the wrecked SUV, a looter fight) -> home: Mom's empty chair,
her Bible and letter -> "6:02 AM" card, dawn -> the radio broadcast -> end cards -> "Chapter 2:
Three months later..." -> back to the menu (Continue keeps the saved progress).

## Project structure

```
project.godot            settings, autoloads, layer names
scenes/                  boot/disclaimer, menu/main_menu, game/game (tiny .tscn shells)
src/autoload/            Events (signal bus), DB (data), Art, GameState, Controls,
                         AudioManager, Router (scene flow, fades, cards), Dialogue
src/core/                Condition, FlagStore, Inventory, HitStop, Layers, Tiles
src/art/                 PlaceholderPainter (placeholder pixel art), SkinPalette
src/actors/              Player, Enemy, components (CharacterVisual, Health, Hitbox, Hurtbox, ShakeCamera)
src/world/               Zone, GroundBuilder (tiles), EntityFactory, LightSource, TriggerArea,
                         ZoneEntityLink, interactables/ (examine, talk, pickup, door)
src/dialogue/            DialogueParser, DialogueScript, ScriptCommands
src/ui/                  DialogueBox, Hud, InventoryPanel, MainMenu (+ hero picker), Disclaimer, UiStyle
src/game/game.gd         the in-game scene (zone host + UI layers)
shaders/                 vignette, skin_palette
data/                    art, tiles, items, enemies, speakers, heroes, lights (.json)
data/zones/              house, street, store (.json)
data/dialogue/           ch1.dlg (game-flow glue), c1_script.dlg (GENERATED from docs/)
tools/script_to_dlg.py   converts docs/CHAPTER_1_SCRIPT.md into c1_script.dlg
tests/                   smoke_test, chapter1_driver, layout_check.py, zone_shots
tools/pixel_ops.py,      hand fixes to the delivered art (rescaling, recolours, redrawn fire,
  art_handfix.py         store floor, character fixes); re-runnable, reads the originals from git
art/                     drop real PNGs here (see "Art")
docs/                    story (written by the story team)
audio/                   sound and music (written by the audio team)
```

Scenes are thin: almost everything is composed in code from data, so content changes are data changes.

## Writing dialogue (`.dlg`)

Files live in `data/dialogue/<file>.dlg` and are referenced as `"file#node"`, e.g. `"ch1#dinner"`.

```
# comment (also //)
== node_name
mom: A line. Speaker ids come from data/speakers.json.
mom(happy): Same, with the portrait variant portrait_mom_happy (falls back to portrait_mom).
examine[Laptop]: Same, but the box shows "Laptop" as the name.
{C1_GRACE != ate} mom: Only shown when the condition holds.
hollis: And you tell her that I think it's going to be— >>
A line with no speaker is narration.
* Bow your head. -> after_grace +C1_GRACE=bowed      (a choice: jump + set flags)
* {has:bat} Swing first. -> fight +chose_violence    (a choice shown only if the condition holds)
-> another_node                                      (jump)
~ command arg "quoted arg"                           (a command)
```

`>>` at the end of a line continues without waiting (an interrupted line stays on screen).
Text variables: `{HERO}`, `{KID}`, `{THEY}`, `{THEM}`, `{THEIR}`, `{THEIRS}`, `{THEMSELF}`
(values from `data/heroes.json`). `\n` makes a line break.

**Conditions** (also used in zone data): `flag`, `!flag`, `has:item`, `flag == value`,
`flag != value`, combined with `&` (and) and `|` (or, binds looser).

**Commands**

| Command | Effect |
|---|---|
| `set flag [value]`, `unset flag` | story flags (value defaults to true) |
| `if <condition> -> node` / `if <condition> end` | branch |
| `goto node`, `end`, `call file#node` | flow (`call` runs another node, then returns) |
| `give item [n]`, `take item [n]`, `equip item`, `heal n` | inventory and health |
| `sfx name [db]`, `music name [fade]`, `music_stop [fade]` | audio |
| `ambience name [db] [fade]`, `ambience_stop name`, `ambience_clear [fade]` | ambience layers |
| `mute_all`, `unmute_all` | total silence (master bus) |
| `wait seconds`, `close_box` | pacing |
| `ambient #rrggbb [secs]`, `vignette strength [secs]` | time of day / mood |
| `lights group on/off/dim [secs]` | light groups ("off" stutters out like failing power) |
| `shake strength secs` | camera shake |
| `vanish entity_id` | the character is gone; their clothes (`leaves`) remain |
| `hide entity_id`, `show entity_id` | remove / restore any zone entity |
| `card chapter "Title" "Subtitle"`, `card timeskip "Three months later..."` | full-screen cards |
| `zone zone_id spawn_id` | go to another zone |
| `checkpoint` | save progress here (retry point) |
| `toast text`, `event name` | HUD message; signal for code (`Events.story_event`) |
| `end_chapter [n]` | save, set the chapter, return to the menu |

New commands are one method in `src/dialogue/script_commands.gd`.

### The story script

`docs/CHAPTER_1_SCRIPT.md` (YAML blocks) is converted with:

```bash
python3 tools/script_to_dlg.py     # writes data/dialogue/c1_script.dlg (needs PyYAML)
```

Every list in a scene becomes a node `SCENE.key` (e.g. `C1_S03.dialogue`, `C1_S03.choices`), every
object a node by its id (`C1_OBJ_LAPTOP`), jump targets start their own nodes, bark lines are
also single nodes (`C1_S07_L010.single`), and a jump to something that is not dialogue (a fight, a
minigame, the next scene) sets the flag `C1_NEXT` and ends. Script ids map to engine names in the
tool (`SFX_SCANNER_BEEP` -> `register_beep`, emotes -> portrait moods). `data/dialogue/ch1.dlg`
is the hand-written glue that calls those nodes in order and adds the cinematic beats; lines marked
`# PLACEHOLDER` there are stand-ins the script does not cover yet. Not greyboxed yet: S02 upstairs,
S06 shove, S07a calm minigame (meeting Mrs. Albright decides it), S07b rescue sequence (plays as
a short beat), S10 basement, S11 stranger, S12 before dawn, choice timers.

## Zone data (`data/zones/<id>.json`)

```jsonc
{
  "map": ["####", "#..#"], "legend": {"#": "wall", ".": "floor_wood"},   // tiles from tiles.json
  "ambient": "#d8b49c", "vignette": 0.4, "music": "home_evening", "ambience": ["fridge_hum_loop"],
  "variants": [{"if": "vanished", "ambient": "#4a5070", "music": "aftermath"}],   // first match wins
  "on_enter": [{"id": "house_empty", "if": "vanished", "run": "ch1#home_empty"}], // once each
  "entities": [
    {"kind": "spawn", "id": "bed", "pos": [3, 5]},
    {"id": "fridge", "art": "fridge", "pos": [25, 1], "solid": [30, 14],
     "interact": {"type": "examine", "dialogue": "ch1#fridge", "verb": "Open fridge"}},
    {"id": "mom", "kind": "npc", "art": "mom", "pos": [14, 3], "if": "!vanished",
     "interact": {"type": "talk", "dialogue": "ch1#mom"}},
    {"id": "front_door", "pos": [13, 15], "interact": {"type": "door", "to": "street", "spawn": "house_front",
     "requires": "C1_LAST_WORDS", "locked_dialogue": "ch1#front_door_locked"}},
    {"id": "milk", "art": "icon_milk", "pos": [15, 2], "interact": {"type": "pickup", "item": "milk"}},
    {"id": "lamp", "kind": "light", "pos": [17, 3], "light": {"type": "ceiling", "group": "house"}},
    {"id": "looter", "kind": "enemy", "enemy": "looter", "pos": [27, 9], "if": "vanished",
     "defeat_flag": "street_looter_defeated", "on_defeat": "ch1#street_looter_beaten"},
    {"id": "trg", "kind": "trigger", "rect": [9, 1, 18, 6], "run": "ch1#kitchen_enter"},
    {"id": "hollis", "kind": "npc", "art": "hollis", "pos": [4, 8], "leaves": "clothes_hollis"}
  ]
}
```

`pos` is in tiles (fractions allowed), `offset` in pixels. Every entity may have `if`; entities
appear and disappear by themselves as flags change. Pickups and one-shot triggers remember
themselves (`taken:<id>`, `done:<id>`). Entity ids should be unique across the game.
Enemy stats are in `data/enemies.json`, items in `data/items.json`, light types in `data/lights.json`.

More entity and zone fields (all optional):

| field | meaning |
|---|---|
| `"solid": "art"` | collision = the art entry's `footprint` (+ `solid_extra`), `[x, y, w, h]` in the image's own pixels (buildings) |
| `"solid_rects": [[x, y, w, h], ...]` | extra solid rectangles in image pixels |
| `"solid_offset": [x, y]` | moves a `[w, h]` solid (e.g. onto a lamp post's foot) |
| `"flip": true` | mirrors the sprite (and its image-space solids) |
| `"above": true` | drawn over everything (ceiling/side-wall fixtures) |
| `"floor": true` | floor decal (rug, mat, spill): drawn on the floor under everything |
| `"on"` | what a non-solid prop rests on: a host entity id (`"k_table"`), `"wall"` (wall face), `"floor"` (decals), `"ground"` (outdoors), `"above"` (ceiling). Checked by the layout check |
| `"story": "..."` | why a loose object lies on the floor/ground (required for loose clutter and pickups there) |
| `"building": true` | a building sprite; a `door` interaction on it sits at its front wall |
| `"fence": true` | fence/hedge module; runs must end against something solid |
| `"vehicle": true` | must stand on road/driveway tiles |
| `"door_kind": "view"` | a door you only look through (the kitchen screen door); must sit on a wall face |
| zone `"interior": true` | rooms enclosed by walls; checked for leaks, doorways and reachability |
| zone `"open_edges": [{"rect": [x, y, w, h], "why": "..."}]` | map edges (tiles) where open ground may run off the map |

Tiles (`data/tiles.json`): `variants` (`[[art, weight], ...]`, picked per cell by hash) break up
repetition; walls take `face_art`, `face_tall` (two-row faces: `[upper, lower]`) and `face_end`
(shaded end pieces where a face row stops); flags `wall`, `door` (solid door tile in a wall),
`doorway` (walkable opening between rooms), `paved`, `sidewalk`, `road`, `driveway`, `vehicle_ok`
are used by the layout check.

### Layout check

`python3 tests/layout_check.py` rebuilds every zone's collision exactly as the engine does
(solid tiles, entity solids, building footprints) in each story state, moves a player-sized box
(18x10 px) through it on a 4 px grid and fails on: interiors reachable from outside without a
door (gaps), doorways you can walk around (blocking a doorway must separate two rooms), door
tiles not set into a wall, door interactions not on a door tile / building front, wall segments
not connected to the other walls, floor areas nobody can reach, spawn points cut off from each
other, overlapping solids, furniture sunk into walls or not standing on floor, interactions that
cannot be reached, props without a support (`on`) or loose on the floor without a `story`, fence
runs ending in mid-air, vehicles off the road/driveway, driveways that do not reach the road,
building doors without a paved path to the sidewalk, and walkable map edges not declared in
`open_edges`. `--self-test` breaks the house on purpose (a wall gap, a bypassable doorway, a
floating door, overlapping furniture, a loose pickup, a wall stub, a blocked doorway) and checks
each is caught. `-v` lists every door, doorway and room count.

## Art

All art is referenced by id through `data/art.json`; nothing is hard-coded. Each entry has a
`path` and a `placeholder`. **To swap in real art, save a PNG at the entry's `path`** (e.g.
`res://art/props/fridge.png`) and run `--import`; the placeholder is used only while the file is missing.
Placeholders are painted in code at run time (`src/art/placeholder_painter.gd`), so no placeholder
files exist anywhere and `art/` belongs to the art team. If delivered files use other names or
folders (see `art/ART_MANIFEST.md`), point the `path` fields in `data/art.json` at them.

- Characters: engine sheets of 64x64 frames, 4 walk frames (columns) x 3 directions (rows: down,
  up, side; side faces right and is mirrored). Layout in the entry's `sheet`
  (`hframes`, `vframes`, `rows`, `fps`), so other layouts work too. Origin = feet.
  An entry with `"full": "<id>_full"` uses the full animation sheet instead (80x80 frames, one row
  per animation and direction, layout JSON in `sheet.layout`): idle, walk, run (when running),
  swing (bat / mop), roll (dodge), hurt, down (knocked out), windup/attack (looters), growl/lunge/
  yelp (the dog). Hair layers follow the body's frame in lockstep; the skin swap still applies.
- Hero: a body sheet per gender (`hero_male_body`, `hero_female_body`) plus hair sheets
  (`hair_short`, `hair_buzz`, `hair_curly`, `hair_long`, `hair_bun`, `hair_bob`) with the **same
  frame layout**, drawn on top. Styles per gender are listed in `data/heroes.json`.
- **Skin palette swap**: art marked `"skin_swap": true` (hero bodies, `mom`, `portrait_mom*`)
  must paint skin with the key ramp: the key colour `#c89070` darkened by 0, 10, 12, 15, 20, 30
  and 45 percent (`SkinPalette.FACTORS`). The shader replaces each with the same shade of the chosen
  tone (`skin_tones` in `data/heroes.json`).
- Portraits: 128x128 (`portrait_<speaker>`, moods as `portrait_<speaker>_<mood>`); the hero has none.
- Tiles: 32x32, one PNG per tile id (`data/tiles.json` maps tile ids to art; `face_art` gives
  walls a front face where the tile below is floor). Props: any size, anchored at the bottom centre.
- Effects: entries with `"fx": {"frames", "ms", "loop", "origin"}` are animated strips
  (`fx_fire`, `fx_smoke`, ...); the origin pixel sits on the entity's position.
- Scale (after the hand fixes in `tools/art_handfix.py`): characters ~58 px tall, house doors ~60 px
  (a person is about door height), cars 84-111 px long (~1.5-1.9x a person), the colonial houses
  330x403, the ranch 345x206, the market 242x218.
- Items: 32x32 icons (`icon_*`).

## Audio

`AudioManager` indexes every `.ogg/.wav/.mp3` under `res://audio/` by file name, so the audio team
can organise folders freely. Names used now (see `audio/AUDIO_LIST.md`): music `title`,
`home_evening`, `unease`, `chaos`, `aftermath`, `dawn_hope`; ambience `suburban_evening_loop`,
`crickets_night_loop`, `wind_loop`, `chaos_city_far_loop`, `dawn_quiet_loop`, `fridge_hum_loop`,
`fluorescent_hum_loop`, `car_alarm_loop`, `fire_crackle_loop`, `crowd_panic_far_loop`,
`drone_tension_loop`; SFX `footstep_<wood|carpet|asphalt|grass>` (random `_01.._04`),
`typewriter_tick`, `door_open`, `pickup`, `inventory_open`, `ui_confirm`, `ui_back`, `whoosh`,
`bat_swing`, `punch`, `hit_heavy`, `hurt`, `grunt`, `dog_bark`, `dog_growl`, `store_door_chime`,
`register_beep`, `phone_buzz`, `power_cut`, `car_crash`, `scream_distant`, `glass_break`,
`emergency_broadcast_tone`, `cutlery_clink`. Looping is done by the player (any file can loop).
Zones choose music/ambience in data; scripts use `~ music`, `~ ambience`, `~ sfx`.
Missing names (currently `cloth_drop`, `smoke_chirp`) are logged once and skipped.
Buses `Music`, `Ambience`, `SFX` are created at start-up.

## Exporting

`.dlg` files are plain text: add `*.dlg` to the export preset's "Filters to export non-resource files".
