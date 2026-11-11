# Trainer prototype: notes

A playable feel prototype for the creature-trainer action RPG in VISION.md. It answers one question: **does fighting as
a trainer with a creature partner, using hybrid control, feel good?** Built on the Lanternfall foundation (Godot 4.7.2,
typed GDScript, code-made art). How to play: PLAY.md.

## What is in
- **Opening meeting:** three starters (honey badger, Ember, brave melee; cuttlefish, Glass, quick ranged trickster;
  pangolin, Bloom, sturdy protector) wait in the meadow. Each reacts when you come close (puffs up and blasts embers /
  flickers through colours / curls into a ball) with a line. Click one to pick it; the other two hop away.
- **One meadow** from Lanternfall's zone generator (biome `tamer_glade`: Glasswood look, daylit, no city wall),
  18 wild packs (one kind per pack; tougher kinds and levels further out) and a camp clearing.
- **Trainer:** click to move (hold to keep walking), Space to roll (i-frames), items on 4 (Honeyberry heal) and
  5 (Smelling Salts revive), 1-3 swap (the one coming in does an entry blast). You can be hit; a fall wakes you at camp.
- **Partner:** always out, follows a little behind and to the side, never collides with you (separate physics layers),
  fights what you clicked, else whatever is attacking you or comes close, leaves dazed creatures alone, comes back if
  pulled too far, and teleports back if it gets lost.
- **Moves:** Q W E R per species (4 distinct kits for the starters, kits for the wild kinds too) plus a bond move on T.
  Five move kinds: strike (an arc), bolt (projectiles, fans, rings), lunge (a dash or a blink, path or landing hits),
  burst (an area at self or aim, with a warning circle, optionally pulsing), guard (a ward for creature and trainer).
  Element-coloured slashes, orbs with trails, blasts, streaks, wards; Lanternfall's impact, hit-stop, shake and
  camera punch on every hit.
- **Hybrid control:** hold Shift. The camera blends over to the creature, it gets a gold outline and a pulsing ground
  ring (the trainer has the outline otherwise), the HUD badge says who you control, and clicks or arrow keys move it.
  It has its own dodge (Space). Let go and it returns to following. It is held within a leash around the trainer.
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
  With none left, the wild creatures go for you.
- **HUD:** trainer life orb, the two items, the "controlling" badge, the active creature's card (portrait, element and
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
| `trainer.gd` | Click-to-move, roll, life, ward, fall and rise |
| `brains/` | `PartnerBrain`, `WildBrain`, `ControlledBrain`, `CampBrain`, `MeetBrain` (one job each, swapped at runtime) |
| `moves/` | `MoveBook` maps a move's `kind` to a `MoveKind` (strike, bolt, lunge, burst, guard). A new kind is a new subclass |
| `creature_combat.gd`, `creature_bolt.gd`, `tamer_fx.gd` | Damage with elements and feedback; projectiles; element effects |
| `team_field.gd` | Puts the active creature on the field: summon, swap and entry attack, knock-out and step-in, items, bond celebrations |
| `hybrid_control.gd` | Shift control: brains, outlines, camera focus blend, leash |
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
- `bash tools/run_all.sh`: Lanternfall's checks plus `-- --tamer-smoke` (46 checks: chart, meeting and pick, moves,
  auto-attack, hybrid on/off, creature dodge, befriending and its interruption, swap with entry hit, knock-out and
  step-in, items, bond and bond move, camp rest, pet, upgrade, drops, the shiny, falling and waking at camp, and a
  pack fight timing).
- `tools/tamer_shots.sh OUT_DIR [shot ...]`: stills (meeting, combat, hybrid, befriend, shiny, swap, camp, camp_panel,
  hud) under xvfb. No video.

## Known gaps (honest)
- **Never played by a person.** The smoke test plays it, and a pack-fight probe set wild damage: a starter alone, on
  auto-attack only, beats two level-1 wild creatures in about 7-9 s and loses 35-70% of its life. Feel numbers
  (speeds, cooldowns, follow distance, camera blend) live in `data/tamer/*.json` for quick tuning.
- Creature art is small and simple (side-on, 4-frame cycles, no turn or attack anims beyond a lean). The pangolin's
  scales are busy at 1x. The trainer is front-facing and only mirrors.
- No music (Lanternfall's dread score does not fit a daylit meadow); sound effects are Lanternfall's.
- A full team cannot take a 4th creature (no storage box yet); befriending is refused with a notice.
- Wild creatures use their kits at random intervals, with no real tactics; no elites or a boss.
- Bond only unlocks one move; no natures in behaviour, no evolutions, no camp interactions between creatures.
- Nothing is saved: closing the game resets it.
- The window is 1920x1080 by default (Lanternfall's setting); the HUD lays out from the viewport but was only checked
  at that size.
