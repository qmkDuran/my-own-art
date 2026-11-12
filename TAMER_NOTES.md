# Trainer prototype: notes

A playable feel prototype for the creature-trainer action RPG in VISION.md. It answers one question: **does fighting as
a trainer with a creature partner feel good?** It now uses battle mode (exploring as the trainer, battles as the creature). Built on the Lanternfall foundation (Godot 4.7.2,
typed GDScript, code-made art). How to play: PLAY.md.

## What is in
- **Opening meeting:** three starters (honey badger, Ember, brave melee; cuttlefish, Glass, quick ranged trickster;
  pangolin, Bloom, sturdy protector) wait in the meadow. Each reacts when you come close (puffs up and blasts embers /
  flickers through colours / curls into a ball) with a line. Click one to pick it; the other two hop away.
- **One meadow** from Lanternfall's zone generator (biome `tamer_glade`: Glasswood look, daylit, no city wall),
  18 wild packs (one kind per pack; tougher kinds and levels further out) and a camp clearing.
- **Battle mode** (`battle_mode.gd`; replaced the earlier Shift steering after the first playtest): exploring, you are
  the trainer (left click walks) and your creature follows. Right-click a wild creature, or let one notice your team,
  and a battle starts with a short beat ("Go, <name>!", a leap, camera punch, vignette). You then control the
  creature: left click moves, right click attacks the target (or swings toward the cursor), Space dodges, Q W E R
  aim while held and fire on release (`AimPreview`: arc, bolt lines, dash path and landing, burst circle, ward).
  The trainer walks to a safe spot behind the fight by themselves. It ends when no awake wild creature is near (or
  you run out of range), with a Victory summary (defeated, materials, bond, dazed ones to befriend).
- **The trainer is never damaged** (not a Combatant). Their part: commands on A S D G (`TrainerCommands`: Cheer,
  Focus, Rally, Mark, cooldowns, stronger with bond), the **bond aura** (+15% damage within 170 px of the trainer,
  a faint ring), swaps on 1-3 with an entry attack and a **perfect swap** (just before a telegraphed attack lands:
  it whiffs and the entry hits twice as hard), items on 4/5, and befriending (F: the trainer walks over and calms
  the dazed creature).
- **Move clarity:** every move has a sentence in `moves.json`; hovering a move icon shows it with real numbers
  (`MoveText`); the first use of each move shows its name; the creature info panel (I, or click the team strip, or
  Info at camp) lists all five moves with element, kind, words and numbers.
- **Wild creatures** telegraph every attack (a red cone or circle and a wind-up), go only for your creature, and start
  small near the start (1-2 per pack, more deeper in). A full team wipe is a **white-out**: fade, retreat to camp,
  recover, lose one of each material.
- **Elements:** the 8-element chart from VISION.md (`data/tamer/elements.json`): x1.6 super effective, x0.6 resisted,
  with a "Super effective!" or "Resisted" word over the target (one per target per 0.6 s).
- **Befriending:** below its species' threshold (the pink notch on its life bar) a wild creature is dazed (gold stars,
  stops fighting). Hold F within reach for 1 s; being hit, rolling, walking or the creature fainting breaks it.
  It joins at half life (max 3 in the team). Three befriendable kinds: maned wolf (Gale), aye-aye (Echo), Tasmanian
  devil (Rot).
- **Shiny:** every species has a shiny palette. The maned wolf's shiny chance is 12% in the prototype, and one shiny
  wolf is guaranteed each time the packs spawn. Gold name, sparkles, a chime when it appears and when befriended.
- **Bond:** 0-100 per creature. It grows per hit, per win, on befriending, on resting, and from petting and feeding.
  At 60 the bond move unlocks on T, with a celebration (hearts, flash, chime) and a notice.
- **Camp:** walk in with no fight nearby. Everyone heals and wakes, the packs respawn (not on top of you), the team
  sits round the fire (the active one walks over), and the camp panel opens: Pet and Feed (once each per rest),
  and raise Life, Power or Speed with materials.
- **Materials:** each wild kind drops its own (1-2, flying to you when near): devils give Rot Fangs (Life), wolves Wind
  Tufts (Power), aye-ayes Night Whiskers (Speed). Costs rise 2, 3, 4, 5, 6 per level.
- **Knock-outs:** a knocked-out creature fades and recovers after 20 s (or at camp); the next one steps in by itself.
- **HUD:** the trainer's commands, the two items, the Exploring/Battle badge, the active creature's card (portrait, element and
  level, life, bond meter with the unlock mark, Q W E R + T slots with cooldowns), the team strip (1-3, life, bond,
  knock-out timers), materials, notices and captions, and the tracker telling you what to try next.

## Architecture (`game/scripts/tamer/`, data in `game/data/tamer/`)
| Script | Job |
|---|---|
| `tamer_game.gd` (TamerGame) | The scene root: builds the meadow, wires systems, routes a few events. `TamerGame.current` is the documented service locator, as `Game.current` in Lanternfall |
| `tamer_data.gd` | Loads elements, species, moves, rules and sprite layouts; matchups |
| `creature_record.gd` | One creature as data: species, level, shiny, bond, upgrades, life, knock-out time |
| `team.gd` | The team, active index, materials, items (state plus signals) |
| `combatant.gd` | Base of trainer and creatures: sides, `receive_hit`, knockback, steering around blocked ground |
| `creature.gd`, `creature_sprite.gd` | A creature on the field; its look (sheet, gait, hit flash, outline, stars, sparkle) |
| `trainer.gd` | Click-to-move, roll, the bond aura; never a target |
| `brains/` | `PartnerBrain`, `WildBrain`, `ControlledBrain`, `CampBrain`, `MeetBrain` (one job each, swapped at runtime) |
| `moves/` | `MoveBook` maps a move's `kind` to a `MoveKind` (strike, bolt, lunge, burst, guard). A new kind is a new subclass |
| `creature_combat.gd`, `creature_bolt.gd`, `tamer_fx.gd` | Damage with elements and feedback; projectiles; element effects |
| `team_field.gd` | Puts the active creature on the field: summon, swap and entry attack, knock-out and step-in, items, bond celebrations |
| `battle_mode.gd`, `trainer_commands.gd`, `aim_preview.gd` | Exploring/battle switch, beat, trainer safe spot, Victory; trainer commands; move ghosts |
| `befriending.gd`, `tamer_spawner.gd`, `material_pickup.gd`, `camp.gd`, `starter_meeting.gd` | Each one system |
| `tamer_input.gd`, `tamer_keys.gd`, `tamer_guide.gd` | Input to commands; extra key actions; tracker steps |
| `ui/` | `TamerHud`, `CreatureCard`, `TeamStrip`, `CampPanel`, `CreatureTag`, `MoveIcon`, `CreaturePortrait` |

Reused from Lanternfall: ZoneGen and its steps, LayoutCheck, ZoneView, Nav, CameraRig, Fx, Impact, HitStop, FloatText,
Telegraph, Overlay, HudOrb, UiDraw, PropSprite, LightTex, Atmosphere (ambient), Audio and its sounds, the palette and
`pix.py`/`people.py` art kit. Small shared refactors so they work outside `Game`: `Fx.layer`, `Fx.screen` and
`Fx.flash_gain` (Impact and screen flashes no longer reach into `Game.current`), TreeFade watches the `fade_focus`
group, UiDraw can draw body text from a Node2D and `Impact.hit` takes optional spark colours.

The prototype bypasses Lanternfall's player, skills, loot, passives, story and title. All of it is still there:
to run Lanternfall, set `run/main_scene` back to `res://scenes/title.tscn` (its checks still run in `tools/run_all.sh`).

## Art (code only)
`python3 -I art/build_creatures.py [review_dir]` draws the six creatures (side view, 56x48 frames: idle 4, move 4,
act 2) and their shiny palettes from `art/creatures.py`, plus the trainer from Lanternfall's parametric people. Palette
gained 8 colours for elements (leaf greens, sea blues, bile). `tools/check_art.py` covers them.

## Checks and stills
- `bash tools/run_all.sh`: Lanternfall's checks plus `-- --tamer-smoke` (72 checks: chart, meeting and pick, moves,
  clarity (descriptions, tooltip, info panel), battle mode (LMB walks, RMB battles, control, aim and release,
  trainer stays back and is never targeted, Victory), wind-ups, befriending by the trainer, swaps, knock-outs,
  items, bond move, commands, aura, perfect swap, camp, upgrades, drops, the shiny, the white-out, and a pack fight
  (`tests/tamer_pack_fight.gd`: three fights, a move about once a second; target 20-35% life lost, last run 25%).
- `tools/tamer_shots.sh OUT_DIR [shot ...]`: stills (meeting, exploring, battle_start, battle, befriend, victory, info, shiny,
  swap, camp, camp_panel, hud) under xvfb. No video.

## Known gaps (honest)
- **Battle mode is untested by a person.** The pack-fight probe tunes it (5-9 s per near 2-pack, ~25% life lost);
  feel numbers live in `data/tamer/*.json`.
- The battle-start beat has no real zoom (a non-integer zoom would smear the pixel art); it uses a punch, a shake
  and a vignette. Items are not thrown yet (they apply at once). No retreat key: run out of range to escape.
- Creature art is small and simple (side-on, 4-frame cycles, no turn or attack anims beyond a lean). The pangolin's
  scales are busy at 1x. The trainer is front-facing and only mirrors.
- No music (Lanternfall's dread score does not fit a daylit meadow); sound effects are Lanternfall's.
- A full team cannot take a 4th creature (no storage box yet); befriending is refused with a notice.
- Wild creatures use their kits at random intervals, with no real tactics; no elites or a boss.
- Bond only unlocks one move; no natures in behaviour, no evolutions, no camp interactions between creatures.
- Nothing is saved: closing the game resets it.
- The window is 1920x1080 by default (Lanternfall's setting); the HUD lays out from the viewport but was only checked
  at that size.
