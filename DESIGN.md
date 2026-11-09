# Design Doc

> The project's memory. Claude doesn't remember past sessions, so decisions live here.
> New idea? Check it against this doc first. If it doesn't fit the current milestone, it goes in a parking lot.

## Hook
An ARPG where your starter creature is your class. You're a trainer who sends a creature into the world through a **spirit link** and **fights as it**, with deep skill trees and gems that change how its attacks work.

## Story frame
- **Spirit link:** the trainer stays safe in the hub and guides the creature through a mental bond. This explains why the player directly controls the creature.
- In the field, the trainer is **not shown for now** (their design is undecided); only their Aid tonics fly in from off-screen. In towns they would appear fully.

## Story premise
- **Glimra** (*GLIM-rah*) is the name for the creatures: beings that carry a living light inside them (it "glimmers"). Emberoo is a Glimra.
- **Two worlds:**
  - **The home world** (our own original world, never a real franchise's): bright and hopeful; people and Glimra live as partners.
  - **The portal world** (dark): the trainer and Emberoo fall through a portal into it. Here Glimra have been hunted almost to extinction; humans drain their light to power and feed their **AI God**.
- The AI God's servants implant **control chips** in captured Glimra to bind them; the chips are invisible in the art.
- **Two words for the same creatures:** the trainer calls them **Glimra**; the Wardens call them **"stock"**. (e.g. *"Fresh stock. Drain it."* vs *"He's not stock. He's my Glimra."*)
- Warden visors are tuned to see Glimra light; the trainer has no light of their own, so the visors can't see them (supports the parked "trainer walks with you" idea).
- A few Glimra survive, hiding in the wild; later they could **freely join you** as new classes (no capture).
- Humans are the threat. **Your trainer is the exception.**
- **Names to avoid:** *Lumari* (a funded studio's creature-collector game), *Lunari* (a League of Legends faction). Final names still need a formal trademark check (USPTO/EUIPO) before the game is announced.

## The trainer (in the world)
- **No capture device, no ball.** We never catch Glimra and Emberoo is with you the whole game (like a partner who just walks beside you), so nothing stores or releases him. Avoid Pokéball-, Mega Bracelet- and Z-Ring-like items.
- *(Parked)* The trainer **walks with Emberoo**, a few steps behind. Enemies ignore them (Warden visors only see Glimra light).
- Original look: brown coat, cream shirt, **orange scarf matching Emberoo**, satchel. 18×28 sprite, front view for now (walk/diagonal animations later).
- **In the field: not shown for now.** No trainer is on screen during play (no portrait, no walking trainer) until their look is decided.
- The walking trainer, the layered look kit and the customiser are **parked for towns**, where the trainer appears fully.
- **Trainer's Aid (F):** the unseen trainer throws a healing tonic that arcs in from just below the bottom edge of the screen, under Emberoo, and lands on him (+4 health); the HUD's `UnseenTrainer` node gives the launch point. **3 charges**; can't be used at full health.
- **Berries:** toads sometimes drop a glowing berry (25%); walking over it refills one Aid charge (it waits if Aid is full).

## Drops and progression resources
- **Light motes (almost every kill):** the stolen light bursts out of defeated bound Glimra and flies to Emberoo = **XP**. *(Next to build.)*
- **Berries (sometimes):** refill Trainer's Aid charges.
- **No loot.** No gear piles, no inventory clutter.
- **Glimmer Shards (hand-placed, ~15–20 per game):** rewards from bosses, exploration and story moments, never random drops. The first sits in Ruins Edge's Overgrown Shrine; for now it's a placeholder pickup (`scenes/pickups/glimmer_shard.tscn`, each with its own `shard_id`) that shows "GLIMMER SHARD FOUND (shards coming soon)" and is recorded in the `ShardInventory` autoload. Socket into skills to change how they behave (never add a new element). 1 slot per skill, +1 per evolution. Free to swap outside combat.
- **Heat** (Emberoo's resource): built by landing jabs, spent by skills, cools off out of combat. Shown as fire pips beside the heart.

## Loot plan: hacked chips (build after the vertical slice)
- **The Link Rod:** the trainer carries a stolen, hacked Warden control rod with a few chip slots (1-2 at first, more through the story).
- **Chips drop only from humans** (Wardens, captains, other servants of the AI God), never from Glimra, so loot stays rare and hunting Wardens is the chase.
- **Hacking:** chips drop "locked" with 1-3 modifiers; hack them with scrap from broken rods to reveal, reroll or upgrade mods (crafting).
- **Mods:** simple, with exact numbers like the Ember Tree (stats, effects, rare "overclocked" mods that change a skill).
- **Glimmer Shards stay separate:** hand-placed finds that change how skills behave. No gear on Emberoo, no clothes, no inventory grid.

## Build system (locked)
- **One evolution line:** Emberoo → Furnaroo (Stage 2, ~24×24) → Emperoo (Stage 3, ~32×32), the same for every build (reference: art/reference/emberoo_inferno_line_concept.png). Builds differ through the Ember Tree and show through skills and effects, not body shape. (Branching evolution was considered and dropped: about 3× the art.)
- **Levelling:** a small automatic stat boost (the "ding") + **1 skill point** per level. Levels get slower to earn: ~level 1 after the first pack, ~4–5 by the end of Ruins Edge, ~10–12 by the end of Act 1, cap **50** at the end of the game (curve and maths in `scripts/systems/progression.gd`). **Evolution:** a big power jump + a new tree ring + another shard slot.
- **Ember Tree:** small (fits on one screen) with **2–3 labelled branches** (e.g. Inferno = burn, Flurry = speed/combos, Bruiser = tanky). Players can mix freely.
- Nodes should **change how you play**, not just add small percentages. Keep to ~5 clear stats (Health, Power, Speed, Heat, Burn).
- **Crits:** every attack (jab, spin, skills) can crit: **10% base chance, ×2 damage** (rounded), shown as a gold "4!" number and in the Ember Tree stats. No tree nodes change crits yet.
- **Starting point:** Emberoo starts at **level 0 with no skill points**. The first small pack of enemies brings level 1 and the first point, so the first pick (a tier-0 build starter: Searing Jab, Spinning Hook or Ash Guard) feels earned and comes within the first minute; skills (Flame Uppercut, Spinning Hook, ...) only work once ignited in the tree.
- **Stage 1 is fully built:** every inner-ring node works and shows live numbers. Bruiser: Ash Guard (W, 2 Heat, 4s cooldown: 1.2s guard, 50% damage taken, no shoves; W again, attacking or dodging drops it), Thick Hide, Counter Punch (a hit taken in guard makes the next punch within 1s a sure crit with a hard knockback), Iron Gut, Unshakable (shoves push 25% as far). Inferno: Wildfire (an enemy dying while burning passes its burn to the nearest enemy within 48px). Flurry: Ember Hop (dodges leave a 1.5s fire trail; touching it burns 1/s for 2s).
- **Respec free or nearly free.** 1–2 optional "build starter" suggestions per creature.
- Lessons from research: PoE 2's huge tree overwhelms; Diablo 4's early tree felt shallow (gear decided builds) and its 2026 rework moved to skill variants that change behaviour; Last Epoch's per-skill trees + cheap respec are loved.

## Structure and story
- **Campaign ARPG** structure (like Grim Dawn / Diablo 4): story split into **acts**; each act is a region of **hand-made zones**. No roguelite randomised runs.
- **Moving hub:** the trainer journeys town to town / camp to camp; each act has a new hub.
- Story told mostly **in the hub** via short dialogue. No cutscenes.
- Journey-style story: a region to cross, a rival, powerful figures to beat, a villain group (original setting and characters).
- **Tone: dark themes, not graphic content.** Loss, war, corruption, moral grey areas. No gore.
- Scope: ~1 act for the demo, ~3 acts for the full game.
- Write the story **after** the vertical slice is fun.

## Zones
- **Zone design rules** (from our zone research):
  - **5–8 minutes** per zone on a first run.
  - **3–5 points of interest** (a fight area with its own look, a landmark, a pocket, a vista), and never more than about one screen of plain trees along the path without something: a fork, a pack, a prop or a view.
  - **25–35% optional space**: side pockets cut into the forest, each visible from the main path (a gap in the trees or a short trail) and each with a reward (berries, a shard, an elite, a lore stone). No dead end without a reward.
  - **One loop** per zone, so the player never walks the same corridor twice; a one-way drop or breakable wall is fine.
  - **A checkpoint before each boss:** a small safe clearing out of every enemy's notice range, with 1–2 berries and a "boss ahead" warning (lit cyan conduits, Warden banners).
  - **A Glimmer Shard every 1–2 zones**, hand-placed in a pocket or behind a boss.
  - **Elites guard side pockets**, never the main path: `EliteModifier` (`scripts/components/elite_modifier.gd`) attached as a child of an enemy in the zone scene gives 2.5× health (rounded up), 3× light motes, a quiet cyan aura at its feet and a gold name tag ("BRISTLING TOXLOP") that shows when you're near. Never scaled up.
  - Each fight area gets its **own identity** (a prop, a floor, a light), not just another grey courtyard, and each zone has **one tall landmark** you can see from several areas.
- **First zone: Ruins Edge** (`scenes/zones/ruins_edge/`), overgrown ruins at the edge of the AI God's territory. The game starts here; `scenes/main/main.tscn` stays as the test arena (enemies start paused there).
- Main path through hand-made areas, each with its own look: Start Glade (dummy, berries), **Mossy Steps** (three terraced stone steps), **Fallen Courtyard** (a toppled statue, its head rolled away), **Sunken Garden** (flooded stone beds with lilies and reeds; the water is decoration for now, maybe slowing later), **Conduit Hall** (its conduits lit cyan again), the **Warden Gate** (a stone arch with the Wardens' lit visor slit, closed in by a wall, Warden banners either side), Final Arena (the Warden Captain's boss room). Aim: ~5–6 minutes. Enemy density rises toward the end.
- Ruins Edge's points of interest off the main path:
  - **Overgrown Shrine** (gap east of the Start Glade → Mossy Steps trail): a stone shrine, the zone's **Glimmer Shard** and an elite Toxlop.
  - **Boar Den** (through the gap in Conduit Hall's north wall): an elite Gruntite and a cache of 3 berries.
  - **Broken Tower** (the landmark, between the Fallen Courtyard, the Sunken Garden trail and Conduit Hall): a lore stone at its foot. Its clearing is the **loop**: a shortcut from Conduit Hall's south-west mouth back down to the Fallen Courtyard → Sunken Garden trail and the middle meadow.
  - **Berry Hollow** (west of the Sunken Garden, now larger) keeps its toads and berries.
  - **Boss-gate checkpoint** (east of the trail between Conduit Hall and the Warden Gate): a waystone, lit conduits, Warden banners and 2 berries. Its `Areas/BossGateCheckpoint/Checkpoint_BossGate` Marker2D (group `checkpoints`) is where a respawn system should put you; there is none yet (dying still reloads the zone). The Warden Gate pack stands 3 tiles further south so the clearing stays out of their sight.
- Hand-placed berries never expire (`lifetime = 0`); dropped ones still fade after 25 s.
- Tiles are 16×16 from `art/tiles/ruins_edge_tileset.tres`: Ground, Decoration, and an Obstacles layer y-sorted with the creatures (`World` node). Dense forest walls the map in. Cyan conduits in the stone are the only tech hint: dead and dark-blue in the open ruins, lit in Conduit Hall and near the boss. Rows 28+ of the atlas hold the revamp's tiles (water by side mask, terrace steps, lit conduits, the statue, shrine, standing stones, Warden banner, gate arch and broken tower); nothing above row 28 moved.
- **Enemies wait until they notice you:** toads and Gruntites within ~7 tiles, Zephoots ~8, Wardens ~9 (their visors see Glimra light). Noticing (or being hit) alerts the rest of the pack; summoned toads come out already hunting. Noticing a species for the first time brings up its discovery card.
- Zephoots stand behind the toad packs (Mossy Steps, Sunken Garden), Gruntites hold the open stone areas (Fallen Courtyard, Conduit Hall); one of each guards the approach to the Final Arena. The Final Arena holds only the Warden Captain (its old Warden + toad pack was removed; his summons and XP burst replace it). Walking in (`Areas/FinalArena/BossArena`) wakes him and closes two cyan energy gates behind you (`ArenaGate`); they open when he falls.
- **Navigation:** each zone has a `ZoneNavigation` region that bakes a navmesh at load from the Obstacles layer's tile collision (plus closed arena gates; a gate rebakes when it opens or closes), shrunk by a 6 px agent radius so walkers clear corners. Baking from collision, not tile navigation polygons, keeps the tiles' collision the one source of truth and gives that margin. Enemies and click-to-move walk it through one shared `PathMover` (repaths every 0.25 s, staggered); Wardens and Zephoots back away by turning aside from walls; the Gruntite's charge and arrow-key movement stay straight. Without a navmesh (the test arena) everything walks straight.
- The HUD and game systems live in one shared scene (`scenes/game/game_layer.tscn`) that every level instances.

## Platform
- Engine: Godot
- Release: Steam (PC)
- Team: solo developer (first game; full-time software dev)
- Pace: ~20 hours/week, sustainable over years

## Art
- 2D pixel art, made by the developer in Aseprite (studying *Pixel Logic*)
- Tiles and world: 16×16
- Creature size grows with evolution: stage 1 = 16×16, stage 2 ≈ 24×24, stage 3 = 32×32
- **Palette: Apollo** (46 colours, Lospec), chosen for its dark tone and clear ramps. Swappable later via Aseprite colour remap.
  - **Every colour we pick comes from Apollo**: art files *and* colours set in code (UI, particles, effects). Checked by script: all art is 100% Apollo; code colours snapped to Apollo.
  - On screen, transparency, fades and glow blend Apollo colours into in-between shades; that's expected and fine.
  - Use ~4–6 colours per creature
  - Darker, muted colours for the world; brighter, saturated colours for creatures, enemies and attacks (readability)
  - No pure black: outlines use `#090A14`; cool darks for world shadows, warm darks (`#241527`, `#341C27`) for the fire creature
- Silhouette first; one consistent light direction
- **No night/dark lighting.** Tried a dark tint + 2D point lights; rejected (the banded light rings looked bad). Keep the world bright.

## Combat
- Real-time, 2D
- The player directly controls the creature they send out

## Starter selection
- **No catching.** At the start, the player picks a starter creature, which is their class.
- Catching was cut for scope.

## Classes and creatures
- **One creature line per element.** Each line is its own class with its own element, playstyle and skill tree.
- **No dual masteries / class mixing.**
- Build **one creature first**; add the next only when the first is fun.

### Creature #1: Fire
- Melee brawler: fast claw combos
- Hits stack **burn** on enemies

## Enemies
- **All enemies are front view only for now** (always face the camera), to keep art small.
- **Handlers don't attack.** Early-game grunts: they keep their distance, back away when approached, and summon. ~5–6 jabs to kill.
- Handler sprite: **18×24** (humans use taller canvases at the same pixel size; never scale sprites in-game). Holds a **control rod** that signals the control chips implanted in the creatures; its tip flares when summoning.
- Handler look: hooded servant of the AI God, dark navy coat, shadowed face with a glowing cyan visor slit, cyan trim, control rod with a glowing tip.
- **Handlers (called Wardens in-game):** human trainers serving the AI God. They stay back and send out **waves of ~6 weak bound creatures that die in one hit** (implanted control chips) for a PoE-style power fantasy.
- **Killing the Handler stops new waves.** Creatures already out keep fighting.
- Handlers use a **small fixed roster** of 2–3 bound creature species across the game (saves art).
- Vertical slice: 1 Handler + 1 bound creature type (simple: runs at you and bites).

- **Zephoot** (wind, `art/zephoot/`): a puff-owl floating on a cloud, 2 jabs. Keeps ~70–110px away (backs off, drifts), then a 0.6s puff-up wind-up with a glint and one slow gust orb (~55px/s, 1 damage + small push; a dodge passes through). A shot every ~2.2s; slow to move right after one (the counterplay window). 4 XP, 10% berry.
- **Warden Captain** (first mini-boss, Final Arena of Ruins Edge; `art/warden_captain/`, `scripts/enemies/warden_captain/`): an elite Warden, 24×34 front view: armoured navy coat, steel pauldrons with cyan trim, a hood with a steel crest and an antenna with the only red light, a wide cyan visor and a heavy halberd-rod. Elite aura: a slow cyan pulse at his feet and blinking data-pixels drifting up. **80 health** (~70-80 jabs at level 4-5 with crits, uppercuts and burn; ~60-90 s). He walks you down and picks an attack, each telegraphed with super armour while it winds up, then a punish window (a hit can stagger him, at most every 2 s):
  - **Rod sweep** (≤34px): 0.55 s wind-up with a red wedge filling toward you, then a 140° swing (36px): 2 damage + shove. Dodge or step back.
  - **Shockwave slam** (≤90px): 0.9 s overhead charge (red sparks; a faint ring shows the reach and the gap), then a red ring rolls out to 96px with a 55° gap placed away from you: 2 damage unless you stand in the gap or dodge-hop it. He's dazed 1.3 s after.
  - **Summon:** 2 Toxlops (at most 3 out, a new wave only when none are left, every ~11 s); phase 2 adds one Zephoot (at most 1).
  - **Phase 2 at half health:** "You're just stock!", red flash, busier aura; wind-ups and recoveries ×0.7, walks ×1.3; adds the **chip pulse**: 3 gust orbs in a spread (75px/s, 1 damage each).
  - **Death:** he staggers, his visor flickers out, his chip shorts in a cyan spark burst and 30 motes ×4 XP (120 XP, about one level at 4-5) fly out; "WARDEN CAPTAIN DEFEATED" shows top-centre for 2 s. The **boss bar** (name + bar, half-health notch) sits top-centre while he lives and steps aside for discovery cards.
- **Gruntite** (stone, `art/gruntite/`): a clay-rock boar, 5 jabs, health bar once hit. Plods slowly; from ~40–90px a 0.8s wind-up (red eyes, then head down with a hoof scrape and dust) and a straight 90px charge at 3× walk speed: 2 damage + a strong shove. A miss skids into a ~1s daze (the punish window); a wall stops it with a bonk. Super armour while winding up and charging. 8 XP.

### Creature #1 (player): Emberoo
- Fire kangaroo boxer. Stage 1 sprite done (16×16): idle (with blink), hop, jab, jab2, dodge in front/side/back.
- Jab: hold to repeat, alternates fists, roots you in place. Dodge: a kangaroo leap that can cancel a jab.
- **Skills on Q/W/E/R** (the skill bar), paid with Heat. **Flame Uppercut (E):** 3 Heat, 2s cooldown; a rising punch that bursts into a ~100° arc of flame (~26px), 3 damage + strong knockback to everything in it. Roots you; the dodge can cancel only its wind-up. Q, W and R are empty for now.
- **Controls:** mouse is the main control; arrow keys also move (no WASD, since W is a skill key). Space = dodge, F = Trainer's Aid.

## Naming
- Creature names blend **[element/trait] + [animal/sound]** into 2–3 fun syllables (e.g. **Emberoo**, **Toxlop**); evolutions get heavier names.
- Every name must be original and checked (web + later USPTO/EUIPO) before use.
- Names in use: **Glimra** (the creatures), **Emberoo** (player, fire kangaroo), **Toxlop** (toxic toad), **Zephoot** (wind puff-owl) and **Gruntite** (stone boar), both pending the trademark check, **Wardens** (the Handlers; fine for enemies, not as a game title).

## HUD
- **Health: one heart** at the bottom-centre, filled with red that drains from the top down as health is lost, with the numbers beside it (e.g. 7/10) in a tiny pixel font.
- **Enemy health:** Wardens and Gruntites show a small bar once hit; one- and two-hit mobs show none.
- **Bottom cluster, centred, left to right:** the heart (with the Trainer's Aid flasks lying on top of it), the skill slots **Q W E R** in one evenly spaced row (key labels, cooldown veils), then the Heat flame, evenly spaced (5 px between the heart, the slot row and the flame; 3 px between slots).
- **No mana yet.** When skills arrive, Emberoo's resource is **Heat**, gained by landing hits and spent on fire skills, shown as **fire pips** next to the heart. Each element class gets its own resource.

## Skill tree presentation
- **Radial "Ember Tree":** Emberoo's live idle animation sits at the centre; the tree grows outward in rings. Inner ring = stage 1, middle ring opens at the stage 2 evolution, outer ring (Ultimates) at stage 3.
- Skills are diamond **embers**, stat picks are round **coals**; learned nodes glow, available ones are outlined, locked ones are cold coal. Learned paths are **flame veins**; learning a node sends fire along the vein.
- Same rules underneath as before (skill → Enhanced → choose 1 of 2; stat nodes between).
- Each element's tree has its own motif (fire veins for Emberoo; e.g. glowing mycelium for toxic).
- UI is **hybrid**: pixel-art icons and frames, text rendered at higher resolution for readability.
- **Premium polish checklist:** eased motion everywhere (no popping), 2D glow on bright pixels, a unique hand-drawn icon per skill, one good licensed pixel font, a custom 9-slice frame, generous spacing, sound for hover/learn/unlock, consistent style across all screens.
- Mockups: radial ember tree and column tree (session scratchpad; regenerate if needed).

## Visual hierarchy (applies to every enemy)
Brightest and busiest first: **player** > **danger cues** (attack tells, projectiles) > **elites/bosses** (auras, glows) > **trash mobs** (readable but quiet) > **world**.
- Trash mobs get no ambient particles; their monster feel comes from design (silhouette, one signature feature, expression).
- Trash effects only on **events**: e.g. Toxlop's toxic splat on death and droplets on its tongue lash.
- Ambient auras are reserved for elites, so an aura means "this one's dangerous".

## Elements
- **Vertical slice: flavour only.** Element sets colours, effects and theme; no damage rules.
- **Soon after: status effects.** Each element applies its own effect (fire = burn, toxic = poison over time).
- **No type chart for now.** Revisit only when there are many elements.

### Enemy #1: Toxlop, the toxic toad (locked)
- Purple toad with toxic green warts, yellow eyes; 16×16, sprite in `art/toxic_toad/`.
- **Front view only:** always faces the camera and hops in any direction (like a slime), so one view covers everything.
- Animations: idle 2, hop 4 (code lifts it in an arc with a ground shadow), attack 3 (mouth opens; the tongue is drawn in code toward the target).
- Hurt/death via shader flash and fade.
- Hyena was dropped as the first enemy (four-legged side view too hard at 16px); it may return later as a bigger enemy.
- Later enemies, one at a time: tick (drains energy), vulture (circles then dives).

## Progression
- Levelling + evolutions + skill trees
- Skill tree inspiration: Grim Dawn, PoE 2, Last Epoch, Diablo 4
  - Leaning toward D4-style skill tiers + "pick one of two" modifier choices
  - Stat-choice nodes are welcome
  - Keep trees small: dozens of nodes, not hundreds. Depth from combinations, not quantity.
- **Gems instead of loot:** gems change how attacks work and carry the build-crafting (the role gear plays in D4). No traditional loot system for now.

## Saving
- One save slot, `user://save_1.json`, written by the `SaveGame` autoload. It has a `version` field; older files are migrated in `SaveGame._migrate`, and damaged or newer-version files are moved to `save_1.unreadable.json` and the game starts fresh.
- Saved: level, XP and debug bonus points (Progression), learned Ember Tree node IDs and the open stage (EmberTree), species met (CreatureLog), Glimmer Shards found by ID (ShardInventory; a found shard never appears again), the current zone and Trainer's Aid charges. Spent points aren't stored: loading gives back every point, then re-learns the saved nodes under the normal rules, so unknown IDs or nodes beyond the points owned are dropped.
- Each system owns its section (`to_save_data` / `load_save_data`); new systems add a section the same way. The tree is saved by node ID only, so nodes added later need no migration.
- Saves automatically on a level up, on learning or unlearning a node, on meeting a new species, on finding a shard, every 60 s and on quitting; writes go to a temp file that is renamed over the save. Loads at game start, before the zone is built.
- The test arena never loads or writes the save (DebugControls' `uses_save_file` is off there). Debug keys: F5 saves now ("SAVED" toast), F9 deletes the save and restarts fresh.

## Scope rules
- Vertical slice first, placeholder art allowed: 1 creature, 1 enemy type, XP/levelling, 1 evolution, 1 small skill tree (3–5 nodes).
- If it isn't fun with boxes, better art won't fix it.

## Code rules
- **Throwaway code goes.** A mockup, demo or prototype is deleted as soon as the real thing replaces it (git keeps the history).
- **One responsibility per file.** Aim for under ~200 lines; past that, split it into components or helpers.
- **Readable names.** Say what a thing is or does (`move_direction`, not `dir`); no unexplained magic numbers.
- **Colours only from the shared Apollo palette** (`scripts/ui/apollo_palette.gd`, `ApolloPalette`). Never a raw `Color(...)` value in a script; screen-specific roles (e.g. `EmberTreePalette`) are built from it.
- **Components over big classes.** A creature or enemy is a thin coordinator; each job (input, click orders, summoning, a shove, drops on death) lives in its own child node or helper.

## Open questions
- Core gameplay loop: draft is hub → link into zone → fight → XP + gems → hub to spend → harder zone → evolve
- How evolution is triggered and how it ties to the skill tree
- Gem system details

## Reference games
- **Monster Sanctuary:** per-monster skill trees, near-solo dev (turn-based)
- **Creature Keeper:** real-time creature-taming ARPG
- **Adore:** action roguelite, summon and control creatures
- **Hades:** melee game feel
- **Last Epoch / Grim Dawn / Diablo 4:** skill trees
