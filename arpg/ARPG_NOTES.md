# The Great Prince — ARPG prototype notes (keep updated)

Premise (Dan 10:12-13; Dan 12:1; Jude 9; Rev 12:7-9): in the time of distress people pray in a ruined suburb at night;
the archangel Michael is sent in answer. He fights only spiritual enemies (Eph 6:12) — shadowy demons, never humans,
never gory — and protects those who pray (Rev 8:3-4). No God figure; Satan is not shown or fought.

Godot 4.7.2 project: `arpg/game/` (run `godot --path arpg/game`; `-- --demo` plays itself and quits after 32 s;
`-- --smoke` headless test; `-- --demo --shots` writes review screenshots to `arpg/out/`).

## Controls (click-to-move is primary)
Hold LMB on the ground to keep walking toward the cursor; LMB on an enemy = walk to it and strike; LMB on an item's
name = walk to it and take it (clicking the ground never takes an item); LMB on a crate/lockbox/waystone = use it;
hold Shift = stand still and strike/cast toward the cursor; Space = Dash; C = character sheet. RMB and Q W E R use the skills placed on those keys
(1-4 alternates); Space dodge; I inventory, K skills, P stars, Alt item labels on/off, Esc pause. Options in
`data/settings.json`: `wasd_movement` (off), `camera_zoom` (1.0 default; 1.5 = larger), `screen_shake` (0..1),
`auto_pickup` (none / all / a rarity and better). The demo bot drives a virtual cursor through the same Game methods.

## View and light
Camera zoom 1.0 by default (more of the street and the packs in view; 1.5 is the option), whole pixels either way.
The night is darker (night tint 0.17/0.18/0.30); fires are the main lights (12 fires, flickering), one flickering
streetlight, the rift's red glow. Michael casts no glow on the ground: a light with `range_item_cull_mask = 2` touches
only characters (Michael, demons, chests, stones on light mask 2), so they stay readable.

## Map (3840x2160, 4x4 screens; `art/build_zone.py` writes ground, minimap, props and `data/zone.json`)
Suburb (two streets of houses, side street) -> highway (four lanes, median barrier with gaps, guardrails with gaps,
pile-up of wrecks, an overpass that turns see-through when Michael is under it) -> park (dirt paths, dark and dead trees,
woods along the edges) -> the rift (ash ground, cracks, a chasm with a red-hot rim and smoke rising from it, Rev 9:2):
the final arena. 27 mixed packs; 3 prayers (suburb, highway verge, park); 5 chests where they make sense (by a garage,
behind the store, beside the wrecked van, by the park hedge, by a burned stump); 4 waystones (found by passing; use one
to travel to any found stone); minimap top-right. Performance: headless ~1.3 ms process + ~1.3 ms physics per frame
with ~95 demons (demons farther than 1300 px sleep); the xvfb software renderer is slow (~20 fps) - not representative.

## Enemies
Imp, Cinder (bursts near Michael and on death), Brute, Ravager (winds up and charges), Mauler (large, ground slam),
Shade (ranged), Caller (summons imps), Stalker (blinks behind Michael) - palette variants of the three generated demons;
plus three from Revelation (paid art, hand animation): Locust (Rev 9:7-10: crowned, human-like face, iron scales,
scorpion tail; flies over obstacles and darts to sting), Impure Spirit (Rev 16:13-14: frog-like; hops, spits bolts and
empowers nearby demons), Fire Horse (Rev 9:17-19: lion head, fire and smoke from its mouth, serpent tail; charges and
breathes a cone of fire). Champions (18% of packs): two members with 1-2 modifiers (Hasted, Ember-Burst, Shielded) shown
in their names. Hero: Gravemaw (final pack). Demons arrive as streaks of black smoke that swirl and coalesce, land with a
dark burst and dust (respawns, waves, summons, the hero); after the final battle the rest leave the same way.

## Builds (dual mastery, Grim Dawn-style mechanics, original content)
Masteries (pick a second at level 3): Sword (Strike, Whirl), Shield (Shield of Faith, Bash), Voice (Rebuke, Silence,
Trumpet Call), Wings (Descent, Gale), Light (Radiance, Lance). Each mastery bar (max 20) opens its skills' tiers at 1/4/8
and adds stats. Ranks 1-8; 1-2 modifiers per skill. Learned skills take the first free key; click the key in the panel to
move a skill. Attributes (1 point per level): Might, Agility, Spirit; items can roll them. Class titles by pair: Warden,
Captain, Vanguard, Sentinel, Herald, Guardian, Keeper, Messenger, Witness, Beacon. Respec refunds every point.
Uniques have build effects: Dawnbreaker (third swing bursts light), Last Wall (Shield of Faith throws bolts back),
Swiftfoot (Descent recovers twice as fast), Oathband (Rebuke restores 8% life). Progress saves to
`user://great_prince_save.json` (every 5 s when changed and on quit; not in --demo/--smoke/--fresh).

## Style (see STYLE.md)
Michael is the reference. World art goes through `build_zone.to_style`: true scale by measured doors/cars/fences
(`style.PIECES`; houses 1.33-1.5x, store 1.2x, fences 0.75-0.8x), the 31-colour world palette, a 1 px outline; the
store's plan-view roof is foreshortened to 3/4. The suburb was relaid for the bigger houses (3 houses north, 2 bungalows +
store south); tall roofs rise 150 px above the map edge over a dark strip. `tools/check_palette.py` checks palette,
outline and scale; `game/tests/run_all.sh` runs every check. `out/reference_sheet.png`, `out/style_before_after.png`.

## Step 2 world test (Michael as style reference)
`art/gen_world_test.py` (paid, run from heaven/): `tiles` = create-tiles-pro 16 x 32 px (asphalt cracks, sidewalk,
night lawn; style images = two 32 px crops of Michael; target palette = the world palette), `house` = image-v2 168 px,
4 variants, the straight-front 3/4 wording + Michael's front sprite as style image (#02 used). `build_zone.WORLD_TEST`
puts the test tiles west of x 960 in the suburb and the test house as the first north house; False restores the old art.
`tests/compare_shots.gd` (`-- --fresh --compare`) writes `out/world_test_generated.png` / `world_test_reused.png`;
sheet `out/world_test_compare.png`. Findings: the tiles fit (the asphalt came back as crack overlays on transparency, so
they sit on a dark fill); a 168 px house is drawn at miniature scale (door ~16 px vs the 67 px rule), and 4x Scale2x makes
it blobby next to Michael - buildings need a bigger canvas (image-v2 allows up to 512x512) or the styled reused houses.

## UI (fonts, layout, numbers)
- Fonts (OFL, from github.com/google/fonts; licences in `game/fonts/OFL-*.txt`): **Pixelify Sans** for titles (20,
  weight 600) and body (10), **Silkscreen** for small labels and numbers (8). Whole-pixel sizes, antialiasing and hinting
  off, kerning off, +2 px word spacing (`fonts/body.tres`, `title.tres`, theme `fonts/ui_theme.tres`). All glyphs the
  game uses are present (checked against every data file). `UiDraw.TITLE/BODY/SMALL` and `UiDraw.label_settings()` are the
  only way text is sized.
- Window stretch `aspect=expand`: the HUD and panels lay out from the viewport size (HUD cluster anchored to the bottom
  with a 6 px margin, minimap and inventory to the right edge, pause/stars/travel centred). Tested and screenshotted at
  1920x1080, 1280x720 and 1440x900 (16:10); the smoke test checks the cluster is on screen.
- Hotbar: LMB, RMB, Q, W, E, R, Space (Dash). 36 px slots: key label top-left in Silkscreen, the 22 px icon centred
  below it, a clockwise cooldown sweep with seconds; hover for the skill's numbers.
- Character sheet (C): `CharacterPanel.rows()` - every value comes from `Stats` (damage range, attack speed in swings/s,
  cast time, crit chance and damage, holy damage, cooldown recovery, life on hit, life/glory and regen, armour and its
  reduction, block chance and amount, fire and shadow resistance (cap 75%), dash cooldown, move speed). Damage types:
  blows are physical (armour, block), bolts are shadow, fire breath and bursts are fire. The smoke test recomputes stats
  by hand from equipment + attributes, rolls 200 hits against the shown range, and compares the sheet to the live stats.
- Tooltips: skills (`SkillInfo`) show damage ranges at the current and next rank, area, durations, cost and cooldown
  after recovery, modifiers (taken in green); items show all stats, item level, and for bag items the difference against
  the worn item (green/red); the target bar shows name, champion modifiers, health numbers and a barrier line.
- Dash (Space): 120 px in 0.22 s, untouchable while it lasts, 1.1 s cooldown (Agility/dash recovery shortens it),
  afterimages and a smoke trail. Using a skill holds Michael for the cast time (cast speed shortens it).

## Loot
Drops land in a ring on open ground (never in a wall, prop, wreck, the chasm or a fire, never under Michael's feet);
labels stack so they never overlap; Alt hides/shows them.

## Impact
Every hit: sparks and a torn-off puff of shadow, a metallic tick; criticals: a flash ring, bigger number, small shake.
Skills: blasts with rings, light and dust (Rebuke, Trumpet Call), a scorched crater with debris (Descent), a beam (Lance).
Deaths: a shadow explosion with embers and a ring; neighbours are jolted so packs fall in a ripple. Screen shake scales
with impact (setting). Layered procedural sounds (impact_heavy, burst, crunch, spark). Master bus: hard limiter -1 dB and
per-sound ducking.

## Module map (`game/scripts/`)
| Folder | Modules |
|---|---|
| core | `InputSetup`, `GameData` (all JSON), `SceneData`, `Scripture` (verses.json), `SpriteFactory`, `Blockers`, `Fx`, `LightTex`, `Audio` (autoload) — SceneData/Scripture/SpriteFactory/Blockers/Fx/Audio copied from heaven |
| actors | `Michael` (movement, combo, dodge, being hit, light), `Demon` (AI, ranks, hurt, dissolve) |
| skills | `SkillSystem` (cooldowns, glory, ranks/modifiers, every skill's effect) |
| combat | `Stats`, `Progression` (xp, skill points, mastery, stars), `Bolt`, `FloatText`, `HitStop`, `SkillFx` |
| loot | `LootGen`, `Inventory`, `GroundItem` |
| world | `Zone` (ground, props, night tint, lights, fire, ash), `Spawner` (packs, champions, hero, respawn, drops), `PrayerObjective` |
| ui | `Hud`, `GamePanel` → `InventoryPanel`, `SkillPanel`, `HostsPanel`; `PausePanel`, `Overlay` (unlit world text), `UiDraw`, `SkillIcons`, `UiText` |
| demo | `DemoBot` (plays for the recording: fights, uses skills, loots, answers prayers, opens panels on a timeline) |
| `game.gd` | builds the world, wires the systems, turns input into Michael's commands |

## Art pipeline (run from `arpg/`)
- `art/build_zone.py`: the zone — one source of truth for the ground image, the prop sprites and `data/zone.json`
  (two rows of houses facing two streets, a side street with crosswalks, back fences, wrecks on the road, scorch and rubble
  grouped at the wrecks and fires, three small fires, bare trees with hand-drawn branches, streetlights).
- `art/build_arpg.py`: Michael sheets (idle/walk/slash, rows down/up/left), demon sheets (rim light + hand animation: idle
  bob, move lean, attack lunge), item icon atlas (8 slots x 8), praying people (heaven people, everyday clothes). Review sheets `out/sprites_3x.png`,
  `out/item_icons_2x.png`.
- `art/ext/`: read-only copies of `/home/user/project-revelation/art/exterior` (same Resurrect 64 palette).
- `art/audio/synth.py`: all audio, procedural, CC0 (reuses heaven's synth instruments).
- Paid scripts (run from `heaven/`, all through `heaven/tools/guard.py`): `art/gen_michael.py`, `art/mk_michael.py`,
  `art/gen_demons.py`, `art/gen_items.py`.

## Scripture
NIV only, exact fragments, `game/data/verses.json`; check with `python3 -I tools/check_verses.py` after
`python3 -I tools/fetch_niv.py` (local cache `art/niv_source.json`, never shipped). The Biblica notice is on the pause screen.
Verses used: Dan 10:12, 10:13, 10:19, 12:1; Jude 9; Rev 2:10, 8:4, 9:2, 12:7, 12:8, 12:9, 12:11; Eph 6:10, 6:12-18;
1 Thess 4:16; Num 22:31; Ps 34:7, 91:5, 91:11, 92:12; Isa 40:26, 40:29, 40:31; Heb 6:19.

## Names (all in data JSON; easy to rename)
Masteries: Sword, Shield, Voice, Wings, Light. Classes: Warden, Captain, Vanguard, Sentinel, Herald, Guardian, Keeper,
Messenger, Witness, Beacon. Skills: Strike, Whirl, Shield of Faith, Bash, Rebuke, Silence, Trumpet Call, Descent, Gale,
Radiance, Lance. Modifiers: Wide Arc, Heavy Blow, Momentum, Quench, Steadfast, Daze, Dread, Echo, Long Silence, Resound,
Shockwave, Downdraft, Long Reach, Gust, Kindle, Mending, Pierce. Attributes: Might, Agility, Spirit. Star groups: Vigil,
Anchor, Eagle, Cedar, Crown. Item bases: Girdle, Breastplate, Boots, Round Shield, Helm, Longsword, Ring, Amulet.
Prefixes: Steadfast, Burnished, Bright, Fleet, Unbroken, Keen. Suffixes: of Dawn, of Renewal, of Precision, of Mercy,
of Peace, of Truth, of Might, of Agility, of Spirit. Rare words: Dawn/Ash/Iron/Ember/Silver/Storm/Bright/Stone/Winter/
Cinder + Guard/Ward/Bastion/Mantle/Edge/Oath/Brand/Veil/Bulwark/Vow. Uniques: Oathband, Swiftfoot, Dawnbreaker, Last Wall.
Enemies: Imp, Cinder, Brute, Ravager, Mauler, Shade, Caller, Stalker, Locust, Impure Spirit, Fire Horse; champion
modifiers Hasted, Ember-Burst, Shielded; hero Gravemaw. Places: Main Street, Highway, Park, The Rift; Supply Crate, Lockbox.

## Budget (generations; guard START 168.5, CAP 100 for job A + B)
| Item | Cost |
|---|---|
| Michael 64 px batch (16 variants, seed 777; #01 used) | 10 |
| Michael 4-direction character | 1 |
| Walk, template walking-8-frames x4 directions | 4 |
| Sword slash, pixminimax 8 frames x4 directions | 4 |
| Demons 64 px batch (16 variants listing the three kinds; #02 imp, #04 brute, #08 shade) | 10 |
| Item icons 32 px batch (64 variants, 8 per slot) | 10 |
| **Total, first pass** | **39** (balance 129.5; USD unchanged) |
| Locust, Impure Spirit, Fire Horse: one 64 px batch each (16 variants; #02, #04, #01 used) | 30 |
| **Total, enemies pass** | **69** (balance 99.5) |
| Step 2 test: tiles (create-tiles-pro) 10, house 168 px 15 | 25 |
| **Total** | **94** (balance 74.5; USD unchanged) |

## Known weak spots
- Michael's walk template barely moves the legs facing down; the side row is the mirrored west walk. No cast animation
  (skills use the idle pose + effects).
- All enemies are side views mirrored, with hand-made animation (bob / lean / lunge / wingbeat by shifting the upper half,
  hop by squash and stretch), not drawn walk cycles. Palette variants share silhouettes with their base demons.
- Houses repeat (four art pieces, some mirrored/darkened) and cannot be entered; the park is mostly open grass and trees.
- The overpass is a flat deck drawn overhead (no ramps); the highway's lanes are walkable everywhere.
- Balance is first-pass; the demo bot starts at level 6 with the Sword + Voice build so the skills appear in the recording.
- Skill icons are simple drawn glyphs.
