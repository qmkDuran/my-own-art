# The Great Prince — ARPG prototype notes (keep updated)

Premise (Dan 10:12-13; Dan 12:1; Jude 9; Rev 12:7-9): in the time of distress people pray in a ruined suburb at night;
the archangel Michael is sent in answer. He fights only spiritual enemies (Eph 6:12) — shadowy demons, never humans,
never gory — and protects those who pray (Rev 8:3-4). No God figure; Satan is not shown or fought.

Godot 4.7.2 project: `arpg/game/` (run `godot --path arpg/game`; `-- --demo` plays itself and quits after 47 s;
`-- --smoke` headless test; `-- --demo --shots` writes review screenshots to `arpg/out/`).

## Controls
WASD move (or click the ground), mouse aims. LMB Strike (click an enemy to walk up and strike; with WASD held a click
strikes toward the mouse). RMB Descent. 1-4 (also Q E R F; W is a movement key) Rebuke, Shield of Faith, Trumpet Call,
Radiance. Space dodge. I inventory, K skills, P stars (the Hosts), Esc pause / close panels. Items are picked up by
walking over them or clicking their names.

## Systems (mechanics inspired by classic dark ARPGs; all names, UI and art original)
- **Skills (mastery style):** 3 skill points per level. The mastery bar (max 20) opens tiers at 1 / 4 / 8 and adds life
  and damage per point. Skill ranks 1-8 (+12% per rank). Each skill has two one-point modifiers. `data/skills.json`.
- **Stars (the Hosts, Isa 40:26):** separate point type: 1 per level after the first + 1 per answered prayer. Five groups
  of 4-6 stars (24 stars), taken in order; a finished group gives a bonus; Cedar needs Anchor, Crown needs Vigil + Eagle.
  `data/hosts.json`.
- **Loot:** rarity tiers common / magic / rare / unique (white / blue / gold / orange), random affixes by item level,
  rolled values, ground labels with a coloured light, auto pickup, 32-cell bag, paper doll with the armour of God
  (Eph 6:13-17) + 2 rings + amulet. `data/items.json`, `scripts/loot/`.
- **Enemies:** Imp (fast swarmer), Brute (slow, heavy), Shade (keeps away and casts "flaming arrows" — Eph 6:16 — that the
  Shield of Faith puts out). Champion packs (22%: two empowered members, named "Champion"), a hero demon (Gravemaw) in the
  final pack. Packs respawn after 22 s when Michael is away. Hit flash, knockback, damage numbers, hit-stop, dissolve
  into shadow (shader). `data/enemies.json`, `scripts/actors/demon.gd`, `shaders/shadow.gdshader`.
- **Objective:** three praying people (light circle + rising incense light). Reaching one brings a wave; clearing it answers
  the prayer (+1 star). After all three: a final pack with Gravemaw; defeating it drops a unique, two rares and a magic item.
- **Michael never dies:** struck down, he is raised again at the start ("Peace! Be strong now; be strong", Dan 10:19).

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
- `art/build_arpg.py`: Michael sheets (idle/walk/slash, rows down/up/left), demon sheets (rim light + hand animation: idle
  bob, move lean, attack lunge), item icon atlas (8 slots x 8), praying people (heaven people, everyday clothes), zone ground
  (Project R tiles + scorch and rubble), darkened/ruined props (dead tree by hand). Review sheets `out/sprites_3x.png`,
  `out/item_icons_2x.png`.
- `art/ext/`: read-only copies of `/home/user/project-revelation/art/exterior` (same Resurrect 64 palette).
- `art/audio/synth.py`: all audio, procedural, CC0 (reuses heaven's synth instruments).
- Paid scripts (run from `heaven/`, all through `heaven/tools/guard.py`): `art/gen_michael.py`, `art/mk_michael.py`,
  `art/gen_demons.py`, `art/gen_items.py`.

## Scripture
NIV only, exact fragments, `game/data/verses.json`; check with `python3 -I tools/check_verses.py` after
`python3 -I tools/fetch_niv.py` (local cache `art/niv_source.json`, never shipped). The Biblica notice is on the pause screen.
Verses used: Dan 10:12, 10:13, 10:19, 12:1; Jude 9; Rev 2:10, 8:4, 12:7, 12:8, 12:9, 12:11; Eph 6:10, 6:12-18;
1 Thess 4:16; Num 22:31; Ps 34:7, 91:5, 91:11, 92:12; Isa 40:26, 40:29, 40:31; Heb 6:19.

## Names (all in data JSON; easy to rename)
Skills: Strike, Descent, Rebuke, Shield of Faith, Trumpet Call, Radiance. Modifiers: Wide Arc, Heavy Blow, Wingbeat,
Long Reach, Dread, Echo, Quench, Steadfast, Resound, Shockwave, Kindle, Mending. Mastery bar: Mastery.
Star groups: Vigil, Anchor, Eagle, Cedar, Crown. Item bases: Girdle, Breastplate, Boots, Round Shield, Helm, Longsword,
Ring, Amulet. Prefixes: Steadfast, Burnished, Bright, Fleet, Unbroken, Keen. Suffixes: of Dawn, of Renewal, of Precision,
of Mercy, of Peace, of Truth. Rare words: Dawn/Ash/Iron/Ember/Silver/Storm/Bright/Stone/Winter/Cinder +
Guard/Ward/Bastion/Mantle/Edge/Oath/Brand/Veil/Bulwark/Vow. Uniques: Oathband, Swiftfoot, Dawnbreaker, Last Wall.
Enemies: Imp, Brute, Shade; Champion; hero Gravemaw.

## Budget (generations; guard START 168.5, CAP 100 for job A + B)
| Item | Cost |
|---|---|
| Michael 64 px batch (16 variants, seed 777; #01 used) | 10 |
| Michael 4-direction character | 1 |
| Walk, template walking-8-frames x4 directions | 4 |
| Sword slash, pixminimax 8 frames x4 directions | 4 |
| Demons 64 px batch (16 variants listing the three kinds; #02 imp, #04 brute, #08 shade) | 10 |
| Item icons 32 px batch (64 variants, 8 per slot) | 10 |
| **Total** | **39** (balance 129.5; USD unchanged) |

## Known weak spots
- Michael's walk template barely moves the legs facing down; the east walk recoloured a wing (the side row uses the west walk;
  right = mirrored). No cast animation (skills use the idle pose + effects).
- Demons have one facing (mirrored) and hand-made animation (bob / lean / lunge), no real walk cycles.
- The zone is a 2x2-screen street; houses are Project R art darkened, not truly ruined; no doors to enter.
- Balance is first-pass; the demo bot starts at level 6 so every skill appears in the recording.
- Skill icons are simple drawn glyphs; the paper doll slots have no labels (tooltips name them).
