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
- The AI God's servants implant **control chips** in captured Glimra (and in the people they make into Wardens) to bind them; the chips are invisible in the art, except as a cyan glint the moment one fails (the Warden Captain's, see "Act 1 outline").
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
- **No gear loot.** No gear piles, no inventory clutter: the only drops that last are hacked chips from Wardens (see "Loot: hacked chips") and scrap to hack them.
- **Glimmer Shards (hand-placed, ~15–20 per game):** rewards from bosses, exploration and story moments, never random drops. Each shard (`scenes/pickups/glimmer_shard.tscn`, its own `shard_id`) gives one **permanent upgrade**, set by its `reward` export (`ShardReward`): `CHIP_SLOT` (+1 Link Rod slot, up to 4), `SKILL_POINT` (+1 skill point), `MAX_HEAT` (+1 max Heat) or `AID_CHARGE` (+1 Trainer's Aid charge). The toast says exactly what you got ("GLIMMER SHARD: +1 chip slot"). `ShardInventory` saves each found shard with its reward, so the upgrade comes back on load and the shard never respawns or pays twice (a shard found in an older save, before rewards, pays out once when its zone loads). Skill-changing effects come from chips, not shards.
  - **The Overgrown Shrine shard (Ruins Edge) gives `CHIP_SLOT`:** the rod starts with one slot and Ruins Edge's Wardens and Captain are the first chip drops, so a second slot in zone 1 doubles the build space right when chips arrive; skill points already come every level (~5 in Ruins Edge), so one more would barely be felt.
- **Heat** (Emberoo's resource): built by landing jabs, spent by skills, cools off out of combat. Shown as fire pips beside the heart.

## Loot: hacked chips (built)
- **The Link Rod** (`LinkRod` autoload): the trainer's stolen, hacked Warden control rod. **1 chip slot** at the start, +1 per `CHIP_SLOT` Glimmer Shard, **up to 4**. Storage holds **20 chips** (equipped ones included); salvage to make room (a chip on the ground waits, with a "CHIP STORAGE FULL" toast).
- **Drops only from humans** (`ChipDrop` on the Warden and Warden Captain scenes; future Warden types get one too), never from Glimra: a Warden drops a chip **25%** of the time and always **2–4 scrap**; the Captain always drops a chip (2–3 mods, better tiers) and **12–15 scrap**. The chip pops out as a small cyan 16×16 chip (`art/pickups/hacked_chip.png`); scrap bits fly to Emberoo like motes. Ruins Edge holds ~35 scrap and ~2–3 chips.
- **Each chip:** its tier is the act it dropped in (Ruins Edge = Act 1). Its **1–3 mods** roll at that tier (20% a tier higher, 50% from the Captain) and can be upgraded to tier act + 1, so **Act 1 chips hold tier 1–2 mods**. Mods drop **locked ("???") and do nothing until revealed.**
- **Hacking with scrap** (`ChipHacking`): **reveal** a locked mod **5**, **reroll** a revealed mod into another of the same tier **12**, **upgrade** a revealed mod one tier **30** (never past the chip's max tier; overclocked mods stay at tier 2). **Salvage** gives 3 + 2 per mod tier.
- **Mods** (one table, `scripts/chips/chip_mod_table.gd`, tier 1 / 2 / 3): +1/2/3 jab damage, +2/3/5 max health, +1/2/3 max Heat, -0.3/0.5/0.8s Flame Uppercut cooldown (floor 0.5s), +3/5/8% crit chance, burn lasts +0.5/1/1.5s, +1/2/3 Aid heal, poison 25/50/75% shorter (floor 20%), +4/6/10 run speed, -0.05/0.1/0.15s dodge cooldown (floor 0.1s). **Overclocked** (tier 2 only, 12% of tier-2 rolls): "Jabs hit a second enemy behind the first" (24px past the furthest hit), "Dodge leaves a short fire trail" (0.8s, 1 burn/s for 1s; quiet if Ember Hop is learned), "Flame Uppercut pulls enemies in" (to 10px, from up to reach + 20px).
- **Exact numbers, never vague percentages:** every revealed mod shows its stat as before → after against Emberoo's live stats (`ChipStatSheet`), e.g. "Crit chance 10% → 15%", "Max Health 10 → 12"; upgrades show theirs too ("Upgrade to T2: Max Health 12 → 13"). Burn and uppercut mods note "(needs Searing Jab / Flame Uppercut)".
- **`ChipEffects`** (GameLayer) applies the equipped chips' revealed mods to Emberoo, re-applying on every change and on load and tracking what it added, so totals stay exact; overclocked mods add a small component to the player (`scripts/chips/overclocks/`).
- **The Link Rod screen (C, `link_rod` action):** C does nothing until the Tinkerer in Hometown has hacked the rod (`StoryFlags.LINK_ROD_GIVEN`, saved; older saves keep the rod; the test arena always has it). Pauses, Ember Tree style (Monogram, card frames, 960×540). Left: the rod (`art/ui/link_rod.png`, sockets lit cyan when filled, faint when open, crossed when not found yet) with its slots, and "The rod gives Emberoo" (without chips → now). Middle: storage as a list (no grid), "IN ROD" marked. Right: the selected chip, each mod with its numbers and Reveal / Reroll / Upgrade buttons (greyed with the reason when not possible), Put in rod / Take out and Salvage. Header: scrap and costs. Click selects; right-click a chip puts it in or takes it out.
- **Saved:** chips (mods, tiers, revealed), equipped serials, scrap (`link_rod` section).
- **Debug:** F7 gives a random tier-2 chip (3 mods) and 50 scrap.
- No gear on Emberoo, no clothes, no inventory grid.

## Build system (locked)
- **Awakening = evolution (Art direction v2, 2026-11-09):** each Awakening is an evolution stage with its own PixelLab art (`art/emberoo_v2/`): **Pyroo** (stage 1, the start, ~35 px, cloth hand-wraps), **Emberoo** (stage 2, Awakening I, ~46 px, obsidian gauntlets with glowing cracks) and **Cinderoo** (stage 3, Awakening II, ~63 px, flame mane, red sash, magma gauntlets). No recolour, rim or aura: the new art is the change, and his fire stays gold → orange → red (`EmberooFlameColors`). The same for every build; builds still differ through the Ember Tree, skills and effects.
  - **Trigger:** a level threshold, `AwakeningStage.ONE_LEVEL` = **10** (about the end of Act 1) for **Awakening I**, `TWO_LEVEL` = **25** (planned, mid-game) for **Awakening II** (`scripts/systems/awakening_stage.gd`; the `Awakening` autoload holds the stage).
  - **The evolve moment** (~1.2 s): Emberoo stops and faces the camera, light gathers (a warm flash and a small ring), then the flare: a white flash on his body as the new form appears, an ember burst, a fire ring, three shockwaves, a screen shake, a brief white screen flash and a "EMBEROO AWAKENED" banner (top-centre). He can't be hurt meanwhile (`AwakeningMoment`, HUD `AwakeningAnnouncement`). Loading and F4 stepping down swap the form at once.
  - **Forms** (`HeroForm` resources in `data/hero_forms/`, put on the creature by `HeroFormSwitch`): each holds the sheet folder, canvas (64/64/96) and sprite offset (feet on the node: -27/-27/-35), the fist spots for the fist sparks, and the body and reach numbers, so gameplay grows with the body:

    | | Pyroo (stage 1) | Emberoo (stage 2) | Cinderoo (stage 3) |
    |---|---|---|---|
    | jab reach / hit radius / fist height | 24 / 13 / -14 | 30 / 16 / -22 | 38 / 19 / -32 |
    | Spinning Hook radius | 36 | 48 | 60 |
    | Flame Uppercut reach | 40 | 52 | 64 |
    | feet collision radius / body middle | 5 / -16 | 6 / -22 | 7 / -30 |
    | dodge speed (× 0.33 s) | 180 | 190 | 205 |

    Hits (jab, hook, uppercut) are measured on the ground, feet to feet, so a tall hero still hits small machines; the effects are drawn at fist height and as big as the real hit area (`HeroFxScale.SKILL_SIZE_SCALE` = 1).
  - **Power:** each Awakening opens the next Ember Tree ring (Awakening I → Stage 2, Awakening II → Stage 3 Ultimates) and gives a flat bump: **+3 Max Health and +1 jab damage** per Awakening (`AwakeningBoost`), shown as an "Awakening" row in the tree's stats panel.
  - **Debug:** F4 cycles the stage (0 → I → II → 0); stepping up plays the moment.
- **Levelling:** a small automatic stat boost (the "ding") + **1 skill point** per level. Levels get slower to earn: ~level 1 after the first pack, ~4–5 by the end of Ruins Edge, ~10–12 by the end of Act 1, cap **50** at the end of the game (curve and maths in `scripts/systems/progression.gd`). **Awakening** (levels 10 and 25): the next evolution form, a flat stat bump and a new tree ring (see above).
- **Ember Tree:** small (fits on one screen) with **2–3 labelled branches** (e.g. Inferno = burn, Flurry = speed/combos, Bruiser = tanky). Players can mix freely.
- Nodes should **change how you play**, not just add small percentages. Keep to ~5 clear stats (Health, Power, Speed, Heat, Burn).
- **Crits:** every attack (jab, spin, skills) can crit: **10% base chance, ×2 damage** (rounded), shown as a gold "4!" number (twice the size, popping in white) and in the Ember Tree stats. **Damage numbers never overlap:** hits on the same target within 0.3 s merge into one rising total, a new number whose path up would cross another's moves above it, and at most 8 show at once (oldest first). No tree nodes change crits yet.
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

## Zone sweet spot (2026-11-09, applies to every zone)

The game is about beating up packs, flashy skills, effects and loot: the more of that per minute, the better. Size serves density, never the other way round.

- **Size (in 480×270 screens):** linear 4–6 screens long; open 6–9 across; maze 6–8. Boss arena 1–1.5 screens so the whole fight fits the camera. Ruins Edge (about 6 × 6.6) is a medium open zone.
- **Time:** 5–7 minutes per zone including fights; about 2 minutes of pure walking.
- **Density (the important part):**
  - A pack every **6–12 seconds** of walking; never more than ~3 seconds without something to hit, break or pick up on the main path.
  - Packs of **6–14 trash** that die in 1–2 hits and explode in chains; a Warden relay in the bigger packs.
  - About **one elite every 60–90 s**, and one rare "named" pack or mini-boss per zone (plus the zone boss where there is one).
  - Breakables (crates, scrap, wrecks) along the path that drop small loot.
- **Loot rhythm:** something drops from almost every pack; a notable drop (chip, core, shard, gem) every 1–2 minutes; one guaranteed good drop from each zone's boss or event.
- **Layout:** one loop or branch, 25–35% optional space with a reward in every pocket, no dead ends without a reward, no long empty corridors, a checkpoint before bosses.

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
- **First zone: Ruins Edge** (`scenes/zones/ruins_edge/`), overgrown ruins at the edge of the AI God's territory, reached from Hometown's west road. A new game starts at the **Hometown Outskirts** (`run/main_scene`; see "Act 1 outline"); `scenes/main/main.tscn` stays as the test arena (enemies start paused there).
- **Its exits:** `Exit_Hometown` at the west edge where the Start Glade's road runs into the trees (back to Hometown's `from_ruins_edge`), a few tiles from the entry `from_hometown` (the spawn); and `Exit_Zone2` down the paved road through the Final Arena's south gate, to zone 2's `from_ruins_edge`, shut ("THE WARDEN CAPTAIN BARS THE WAY") until the Captain falls; arriving back from zone 2 lands on `from_zone2` inside the arena. **Once beaten, the Captain stays beaten** (`BossArena.defeated_flag`, saved in StoryFlags): later visits find the arena empty, so the road on stays open.
- **Zone travel** (reusable): a `ZoneExit` (Area2D: `target_zone`, `target_entry_id`, optional `required_flag` and its `locked_text`) and `ZoneEntry` markers (a `Checkpoint` whose `checkpoint_id` is the entry id; reached only by arriving). Walking into an open exit (faint cream chevrons on the ground point the way) asks the `ZoneTravel` autoload to fade to dark, make the target entry the last checkpoint, swap the zone, bound Emberoo in onto the entry with the zone-entrance hop (the zone's Respawner, as for a loaded save), carry the Trainer's Aid charges over, save and fade back in. Each zone has its own GameLayer; progress lives in the autoloads. An exit to a zone scene that doesn't exist yet says "PATH BLOCKED (COMING SOON)". Keep entries a few tiles from exits.
- **Story flags** (`StoryFlags` autoload, saved): one-off story moments: `arrival_raid_won`, `link_rod_given`, `ruins_edge_captain_defeated`, `warden_captain_spared` (set as his chip cracks, beside the arena's defeated flag; the hub's Elder Bram and Pip speak of him from then on), `frostveil_pass_ice_cutters_beaten`, `galebloom_orchard_boss_defeated`.
- **v2 layout (2026-11-09, for the new scale: hero 35–63 px, robot trash 24–32 px in packs):** 176×112 tiles; corridors 6–7 tiles wide, fight clearings ~21×15, the arena ~27×20 (its mouths narrowed to 5 tiles for the gates). A battlefield of the AI God's war: wrecked drones and walkers, scrap, broken pylons and cables, a burned-out Warden camp, and the pale husks of wild Glimra drained to power the machines, among the old ruins. ~6 min first run (the bot walks the main route with every pocket in ~115 s at 60 px/s; 10 packs plus the boss on that route). 12 packs (5–10 each, 88 placed enemies, ~410 XP), each out of the next one's notice range; mostly toad rushers, Gruntite chargers, a Zephoot or two at the back, a Warden in the big packs (4 Wardens in all, under the summon cap).
- Main path: **Start Glade** (spawn, dummy, berries; a crashed drone) → the old road north (a dead pylon, a cut cable, a husk) → **Drone Crash** (pack 1, 6 rushers: a sentry drone came down through a ruin wall) → **Cable Run** (pack 2 on the trail under fallen pylons) → **Scrap Yard** (pack 3, 10 with a Warden: a Warden drain rig on an old paved floor, scrap heaps, crates) → the **loop**: north by **Pylon Row** (8, two Zephoots under the pylons) or south through the **Husk Field** (9, drained Glimra husks and dead crystal spires, two Gruntites), both meeting at **The Fallen Colossus** (the landmark: a giant AI-God walker half sunk in the earth, a last flicker in its chest core; lore stone at its foot; pack of 10) → **Conduit Hall** (9 with a Warden; lit conduits) → **Warden Gate** (9 with a Warden by a rusted watch post; the Wardens' wall across the road with a 5-tile gap) → boss-gate checkpoint → **Final Arena**.
- Ruins Edge's pockets (each seen from the path, each with a reward): **Burned Camp** (west of the Drone Crash: burnt Warden tents, a firepit, stores; an elite Gruntite with 4 toads, 3 berries), **Scavenger Hollow** (south of the Cable Run: a walker wreck and husks, a pack of 6, 2 berries), **Overgrown Shrine** (south of the Husk Field: the stone shrine, the zone's **Glimmer Shard** `ruins_edge_overgrown_shrine`, an elite Toxlop with 4 toads), **Boar Den** (north of Conduit Hall: an elite Gruntite with 4 toads in the wreckage, 3 berries). Optional space: pockets ~17%, plus the loop's other branch ~29%.
  - **Boss-gate checkpoint** (an east nook just past the Warden Gate's wall): a waystone, lit conduits, Warden banners and 2 berries. Its waystone's flame glyph lights up once you reach `Areas/BossGateCheckpoint/Checkpoint_BossGate` (a `Checkpoint`, group `checkpoints`); see "Death and respawn". It sits out of the gate pack's notice range.
- Hand-placed berries never expire (`lifetime = 0`); dropped ones still fade after 25 s.
- Tiles are 16×16 from `art/tiles/ruins_edge_tileset.tres`: Ground, Decoration, and an Obstacles layer y-sorted with the creatures (`World` node). Dense forest walls the map in. Rows 28–36 hold the first revamp's tiles (water, steps, lit conduits, statue, shrine, standing stones, Warden banner, gate arch, broken tower); **rows 37+ the v2 war props, drawn by hand in Python** (Apollo, gritty grade, `#090A14` outline, top-left light, no baked shadows so `GroundShadows` casts them; cyan/magenta only on machine cores): 37–38 two-tile props (wrecked drone, scrap heap, broken and leaning pylons, crate stack, burnt Warden tent, drained Glimra husk, wrecked walker, burnt banner, dead crystal spire), 39 one-tile obstacles (scrap, crate, barrel, small husk, dead crystals, small drone, cable spool, firepit, sandbags, armour plate), 40 flat decorations without collision (cables, cut cable end, debris, oil, scorch marks, ash, bones, crystal shards, bolts, tread marks), 41–46 big pieces (the Fallen Colossus 5×6, the Warden drain rig 3×3, a rusted watch post 2×3, a wall a machine arm smashed through 3×2, tank traps 2×1). Row 47 holds ground-variety decals (dead grass, rubble, cracked paving, gravel, puddle, moss), scattered in clumped patches so the dirt and grass don't read as one flat colour; each fight clearing also has a few low cover props off the trails. Nothing in rows 0–36 moved. The zone is built by a generator script (Python, like the zone 2–5 builders).
- **Enemies wait until they notice you:** toads and Gruntites within ~7 tiles, Zephoots ~8, Wardens ~9 (their visors see Glimra light). Noticing (or being hit) alerts the rest of the pack; summoned toads come out already hunting. Noticing a species for the first time brings up its discovery card.
- The Final Arena holds only the Warden Captain (his summons and XP burst are the adds). Walking in (`Areas/FinalArena/BossArena`) wakes him and closes two cyan energy gates (`ArenaGate`, 80 px: the north mouth and the south road); they open when he falls.
- **Navigation:** each zone has a `ZoneNavigation` region that bakes a navmesh at load from the Obstacles layer's tile collision (plus closed arena gates; a gate rebakes when it opens or closes), shrunk by a 6 px agent radius so walkers clear corners. Baking from collision, not tile navigation polygons, keeps the tiles' collision the one source of truth and gives that margin. Enemies and click-to-move walk it through one shared `PathMover` (repaths every 0.25 s, staggered); Wardens and Zephoots back away by turning aside from walls; the Gruntite's charge and arrow-key movement stay straight. Without a navmesh (the test arena) everything walks straight.
- The HUD and game systems live in one shared scene (`scenes/game/game_layer.tscn`) that every level instances.
- **Zone 2: Mirelight Fen** (`scenes/zones/zone2/zone2.tscn`, own tileset `art/tiles/mirelight_fen_tileset.tres`), a Tide/Bloom marshland: open water you walk around (corner-shaped water tiles on their own `Water` layer, with collision, carved out of the navmesh; water also blocks the Marksman's beam), mossy boardwalks across it (the water under a boardwalk has no collision), reeds, glowing light-reeds, drowned ruins, grey swamp trees with moss drapes. ~6–7 min, ~46 placed enemies.
  - Main path: **Reedwater Landing** (start, `ZoneEntry` `from_ruins_edge`, exit back west) → **Brine Shallows** (a pool with a boardwalk straight across; Brinelobs on the banks, a toad swarm, a Rimoth shelling them) → the **loop**: north through the **Drowned Chapel** (flooded nave, 2 Wardens, a Rimoth) or south through the **Lightreed Marsh** (glowing reeds, 4 Bramoles hidden among reeds and bushes, a toad swarm), both meeting at the **Sunken Beacon** (the landmark: a half-sunk lighthouse relit by light-reeds, on an islet reached by a boardwalk; lore stone) → **Heron Ridge** (a Warden Marksman on a stone ridge behind rocks, wall stretches with walkable slopes between them; Wardens, toads and a Bramole below) → **Waystone Isle** (checkpoint, 2 berries, banners, lit conduits) → **The Dredge** (mini-event).
  - **The Mirelight**, a lake between the two routes, is seen from both and has a bank only on the beacon side, so it's a view, not a third way round. Heron Pool and flooded edges keep water in sight everywhere.
  - Pockets: **Mire Hollow** (south of Brine Shallows: elite Brinelob, 3 berries, a sunken statue head), **Lantern Shrine** (through the gap in the chapel's north wall: the zone's Glimmer Shard, `mirelight_fen_lantern_shrine`, +1 skill point, an elite Bramole hidden as one of three bushes), **Reed Nook** (2 berries).
  - **The Dredge** (mini-event): a drained stone basin around a Warden pump siphoning the fen's light. Walking in closes two energy gates; the **Dredge Foreman** (an elite Warden, 4× health, boss bar) summons toads beside 2 Brinelobs, a Rimoth and a Bramole. The south gate is the way on: it opens when he falls (`mirelight_fen_foreman_defeated` keeps him gone). Then `ZoneExit_to_zone3` (south edge); `from_zone3` is the entry for coming back.
- **Zone 3: Shockwire Quarry** (`scenes/zones/zone3/zone3.tscn`, own tileset `art/tiles/shockwire_quarry_tileset.tres`), a Spark/Stone quarry where the AI God mines Glimra light: grey grit ground, packed-earth haul roads, pale cut-stone terraces, sandstone rock heaps for walls (with faint cyan light veins), rails and ore carts, crackling conduits, pylons, Glimra crystal clusters. ~6–8 min, ~48 placed enemies plus the boss.
  - Main path: **Tailings Gate** (start, `ZoneEntry` `from_zone2`, exit back west) → **Cart Line** (a long open lane along a rail: 3 Gruntite chargers with room to charge, a Fizzbug pair beside them to bait, toads) → the **loop**: north up the **High Terraces** (three stepped stone terraces, retaining walls at the ends; Zephoots on the upper steps, a Warden and toads below) or south through the **Fizz Pits** (two Fizzbug swarms next to a toad pack and a Gruntite: lure the bugs into them), meeting at the **Siphon Rig** (the landmark: a Warden derrick over a shaft with a glowing tank of drained light; a Marksman on the walled gantry north of it, 2 Wardens, a Gruntite, a Zephoot, toads; lore stone) → **Pylon Row** (the densest run: pylons, crackling conduits, a Marksman on a crate-covered perch, a Warden, 2 Gruntites, Fizzbugs, a Zephoot) → boss-gate checkpoint (waystone, banners, lit conduits, 2 berries) → **Bull Pit**.
  - Pockets: **Ore Cache** (north-west off the terrace trail: elite Gruntite, 3 berries, ore carts) and **Old Shaft** (south-east of the Fizz Pits: the Glimmer Shard, `shockwire_quarry_old_shaft`, +1 max Heat, an elite Zephoot).
  - **Bull Pit** (mid-act boss arena, gated like the Final Arena): the **Quarry Bull** is a placeholder, a Gruntite with `EliteModifier` boosted (5× health = 25, 6× motes = 48 XP, name override, bigger aura) and pylons in the pit to bonk its charges into. **TODO: a real mid-act boss.** `shockwire_quarry_bull_defeated` keeps it beaten. Past the south gate, the corridor runs on off the map's south edge to `ZoneExit_to_zone4` (Frostveil Pass); `from_zone4` is the entry for coming back.
- **XP for zones 2–3** (placed enemies, elites at their mote multiplier; Wardens' summons add ~15 each): Mirelight Fen ~320 placed + ~70 from summons ≈ 390; Shockwire Quarry ~360 placed + ~50 from summons ≈ 410. After Ruins Edge (~380, level 5) that is ~1,180 total: **about level 9** (1,070) by the end of the quarry, level 7 leaving the fen.
- **Zone 4: Frostveil Pass** (`scenes/zones/zone4/zone4.tscn`, own tileset `art/tiles/frostveil_pass_tileset.tres`), a frosty highland pass (Frost/Wind): dusky blue-grey snow, trodden earth trails, snow-laden pines for the woods, the black ice of a frozen tarn with open-water holes (`Water` layer, collision), snow-capped rocks, cairns and old pass walls, Warden tents and heat lamps; light snow drifts across the view (`AmbientDrift`). ~6–7 min, 52 placed enemies.
  - Main path: **Rockfall Landing** (start, `ZoneEntry` `from_zone3` at the north edge, exit back to the quarry's `from_zone4`) → **Windscour Flats** (open snowfield: 3 Zephoots behind a toad pack, a Gruntite) → the **loop**: north round the **Frozen Tarn** (3 Brinelobs on the banks, toads on the ice, 2 Rimoths shelling them) or south down **Icefall Gorge** (a walled lane: 2 Gruntites charging down it, Zephoots and a Warden at the far end, toads), both meeting at the **Rime Spire** (the landmark: a towering shard of ancient ice with a great antlered Glimra frozen inside; a Marksman behind boulders, 2 Wardens, a Gruntite, a Rimoth, toads; lore stone) → **Waystone Nook** (mid-zone checkpoint `Checkpoint_Waystone`, 2 berries) → **Ice Cutters' Camp** (mini-event) → **Watchpost Ridge** (a Marksman at the foot of a wall, Zephoots, a Fizzbug trio, toads) → `ZoneExit_to_zone5` on the east edge (`from_zone5` is the entry for coming back).
  - Pockets: **Hunter's Hollow** (south-west of the flats: an old lean-to, an elite Gruntite, 3 berries), **Moth Grotto** (north of the tarn: an elite Rimoth among the ice, 2 berries), **Frostbound Hollow** (behind the frozen Glimra: the Glimmer Shard `frostveil_pass_frostbound_hollow`, **+1 Trainer's Aid charge**, 2 berries).
  - **The Ice Cutters** (mini-event, `CrewEncounter`): a Warden crew (2 Wardens, a Gruntite, 2 Rimoths, 3 toads) is sawing a frozen Glimra out of a block of ice that seals Frostbound Hollow. No gates: beat the whole crew (their summons don't count) and "ICE CUTTERS DEFEATED" shows, then the ice cracks and fades (`Barricade`): the Glimra is gone, the hollow open. `frostveil_pass_ice_cutters_beaten` keeps it won.
- **Zone 5: Galebloom Orchard** (`scenes/zones/zone5/zone5.tscn`, own tileset `art/tiles/galebloom_orchard_tileset.tres`), a wind-swept orchard gone wild (Bloom/Wind): bright meadow grass, blossom trees crowding the clearings' edges (greener deeper in), sandstone walls and paving, mill ponds with a footbridge, hay, carts, a cider press; petals and leaves drift on the wind (`AmbientDrift`). ~6–7 min, 45 placed enemies with the boss.
  - Main path: **Orchard Gate** (start, `ZoneEntry` `from_zone4`, exit back west; a broken orchard gate) → **Blossom Rows** (young blossom trees in rows, 3 Bramoles hidden by the bushes, toads, 2 Zephoots) → the **loop**: north over **Windmill Hill** (the landmark: a tall sandstone mill, its sails turning in the gale, a Warden cable at its door; 3 Zephoots, a Marksman by the hay cart, a Warden, toads; lore stone) or south by the **Mill Ponds** (a footbridge across; 2 Brinelobs, a Rimoth, toads, a Bramole), meeting at the **Press House Yard** (a ruined press house the Wardens use as a store: 2 Wardens, 3 Fizzbugs, a Gruntite, toads) → **Petal Terraces** (the densest run: a Marksman on the upper terrace, a Warden, a Gruntite, a Zephoot, a Rimoth, 2 Bramoles, toads) → boss-gate checkpoint (waystone, banners, lit conduits, 2 berries) → **Blossom Court**.
  - Pockets: **Scarecrow Patch** (north of the rows: an elite Bramole hidden by the berries, 3 berries), **Old Well** (south of the ponds: an elite Toxlop, 2 berries).
  - **Blossom Court** (mid-act boss arena, gated north and south through sandstone gateposts; a round paved court ~20×15 tiles, sized for the Shalendrill's 104 px slam ring, 170 px leap and Rockfall; the great blossom tree on its west edge, four stone lanterns): `World/Boss` is the **Shalendrill** (it shows its own boss bar, so the arena's `boss_bar_name` is empty); `galebloom_orchard_boss_defeated` keeps it beaten. Past the south gate, `ZoneExit_to_zone6` (needs the flag; then "PATH BLOCKED (COMING SOON)" until zone 6 exists); `from_zone6` is ready for coming back.
- **XP for zones 4–5:** Frostveil Pass ~340 placed + ~60 from summons ≈ 400; Galebloom Orchard ~270 placed + ~50 from summons ≈ 320 before the boss, then the Shalendrill's 280. That is ~1,900 total at the boss door: **level 11** (1,759) for the fight, as the boss is tuned for, and ~2,180 after it (level 12 at 2,186). Level 10 (Awakening I) comes in the pass.
- **Bosses and elites as bosses:** `BossArena.boss` takes any `Enemy`. The Warden Captain shows his own boss bar; for any other boss `boss_bar_name` makes the arena show, hide (on a fall) and announce ("<NAME> DEFEATED") the bar. `EliteModifier.name_override` gives an elite its own name instead of "Bristling <species>".
- **Biome tilesets** keep the Ruins Edge atlas layout for rows 0–36 (same tile ids, recoloured per biome: the zone builders reuse every Ruins Edge tile id) and add their own rows from 37: the fen's corner-mask water (row 37 with collision, row 38 without, for under boardwalks), boardwalks by side mask (39 across, 40 along), reeds/light-reeds/lilies/shallows/mud (41) props (42+: mangrove, drowned pillar, statue head, Warden pump, stump, mossy rock, willow, light-reed bloom, the Sunken Beacon) and row 45's boardwalk overlays for the water beside a walkway (posts, and its shadow on the south/east side). Boardwalks are at most 2 tiles wide, planks laid across the walk, a dark nailed rail on each open side; the quarry's paved platforms (its stone/grit edge tiles are redrawn with crisp quarter-tile edges, a 1 px dark border and a lit lip, in the Ruins Edge stone greys so enemies stand out), rails, crackling conduits and hazard paint (37), ground bits (38) and props (39+: crystal clusters, crates, ore cart, pylon, terminal, rockfall, the Siphon Rig, spoil heap, barrel, boulder). Frostveil Pass redraws rows 0–36 rather than only recolouring them (snow ground, black-ice edges by corner field, snow caps on walls and props, snowy pines in every canopy slot) and adds open-water holes (37), small decorations (38) and props (39+: pines, ice crystals, cairn, heat lamp, tent, Warden crates, sled, log, signpost, cut ice, lean-to, the Rime Spire, the frozen Glimra, ice saw, snowy boulders). Galebloom Orchard keeps the Ruins Edge shapes with meadow ground, sandstone and blossom crowns (`ZoneMap.crown_bias` puts them at the clearings' edges), plus pond water (37/38), footbridges (39/40), decorations and boardwalk overlays (41) and props (42+: young blossom tree, hay, scarecrow, barrel, crate, cart, well, cider press, fences, signpost, lantern, stump, the windmill, the great blossom tree, wheelbarrow).

## Act 1 outline (draft)
- **Intro (short):** the bright home world, then the portal throws you and Emberoo **100 years into the future**, into the same hometown, now under the AI God.
- **Arrival:** you land at the edge of the town in the middle of a Warden raid: a short fight right away (PoE-style "fight from minute one"). Then you enter the town.
- **Hub: the hometown, 100 years later:** people stare (nobody has seen a free Glimra in decades). Story set-up. The tinkerer has a stolen Warden rod and hacks it into the **Link Rod** (chips plan).
- **Built so far (2026-11-09):**
  - **Hometown Outskirts** (`scenes/zones/hometown_outskirts/`, the game's main scene): Emberoo lands on the road south of the town's palisade during a **Warden raid**: one Warden (who summons a single pair of Toxlops) and 2 Toxlops, ~10 s from the landing spot. `RaidEncounter` watches the raiders; when all are down, the townsperson by the crates shouts "You... you have a FREE Glimra?!" and the junk **barricade** across the gate (`Barricade`) shakes and falls away; the road north leads into town. Won once, it stays won (`arrival_raid_won`): later visits find the road open and quiet, and the townsperson then talks.
  - **Hometown** (`scenes/zones/hometown/`), the hub: safe, no enemies. A cobbled square, cracked and taken back by grass at its corners, round a broken fountain (a stone Glimra, its top snapped off); patched houses (tarps, tin sheets, bricks where the plaster fell off), a laundry line, two market stalls, a well, three dead AI God pylons (dark, a last cyan glint in a cracked lens, one overgrown), a crashed Warden drone in the grass. The waystone checkpoint (`Checkpoint_Waystone`) with 2 berries is south-west of the square. Roads: south to the outskirts, west to Ruins Edge (guarded).
  - **NPCs** (`Npc`, `scripts/npcs/`): 16×26 front view, 2-frame idle (the head dips a pixel: a breath), face rule: 12-row head, two solid 1×2 dark eyes (no whites), then a cheek row (1px nose shade), a 2px dark-red mouth (#602C2C) and a chin row, `art/npcs/`. Walk up and press **F or E** (a bobbing "F TALK" tag shows who's in reach, and those keys don't heal or cast then: `TalkFocus`), or click them (Emberoo walks over). Their lines are data (`Dialogue` resources in `data/dialogue/`, 2–4 lines, an optional flag set at the end and a HUD message); a second Dialogue can take over once a flag is set. Shown in the **DialogueBox** (GameLayer): a HUD card at the bottom (Monogram, card frame) with the speaker's portrait and name, each line typed out; click (or F, E, Space, Enter) to go on; the game pauses meanwhile.
  - **The cast:** **the Tinkerer** (old resistance woman, grey bun, goggles, leather apron, red armband; by her workbench outside the slate-roofed workshop): explains the stolen Warden rod, hacks it into the Link Rod and says to press C ("LINK ROD: PRESS C"; sets `link_rod_given`). **Elder Bram** (bald, white beard, blue robe, stick; by a bench): the 100 years: the AI God, Wardens draining Glimra light into "stock", implanted chips; once the Captain is spared, he recognises his son Varn in him. **Pip** (the kid, by the fountain): amazed by Emberoo; after the Captain, notices Bram staring down the west road. **The gate guard** (pot helmet, spear; west road): points to Ruins Edge. **The merchant** (stall): a joke and the free berries. **The townsperson** (red headscarf; outskirts).
  - **Art:** `art/tiles/hometown_tiles.png` + `hometown_tileset.tres` (separate from Ruins Edge's): bright grass, sandstone cobbles with curbs and broken patches, dirt road edges, three patched houses, pylons, workbench, two stalls, fountain, well, barricade, fences, laundry, crates, barrels, sacks, planters, bench, signpost, drone wreck. The forest, trees, waystone and decorations come from the Ruins Edge tileset on their own layers. Bright, no night lighting.
- **The Warden Captain (end of Ruins Edge), built:** he doesn't die. Beaten, he drops to one knee, the chip at his temple cracks, and for the first time in twenty years the AI God's voice in his head goes quiet. Three dazed lines (no name on screen yet, the bar and the box say "Warden Captain"):
  - *"...The light. It's gone quiet. First time in twenty years."* / *"Hometown? I... know that name. There was a well. I split my brow on it."* / *"Go, little flame. It'll send others now. Worse than me."* Then he staggers off north and is gone (`warden_captain_spared`).
  - Back in the hub, **Elder Bram** (`elder_after_captain.tres`): *"The Captain knew our town? A scar over his left eye, from the old well?"* / *"...Varn. My boy. The Wardens took him twenty winters ago."* / *"If his chip can crack, so can the others. Keep going. Please. Bring them home."* **Pip** (`kid_after_captain.tres`): *"You beat the Warden Captain?! The BIG one?!"* / *"Elder Bram keeps staring down the west road. He won't say why."*
  - **Who he is:** **Varn**, Elder Bram's son, taken from Hometown by the Wardens as a boy twenty winters ago and chipped into a Warden (the Wardens take children too, not only Glimra). Name: no famous trademark found (only a minor creature race in *Two Worlds*); pending the formal check like the other names.
  - **Threads for later acts:**
    - **Varn returns:** half-free, hunted by both sides; maybe an ally, maybe chipped again, and a homecoming with Bram worth earning.
    - **Chips can break.** The Captain's cracked under the strain: hope for freeing chipped Glimra *and* chipped people, and a goal for the Tinkerer and the Link Rod (from reading chips to breaking them).
    - **"It'll send others. Worse than me."** The AI God noticed a free Glimra: the act-2 hook is a stronger hunter sent after Emberoo.
    - Who else did the Wardens take from Hometown?
- **Zones:** about 10 per act at 5–8 min each, plus the hub. Zone 1 = **Ruins Edge** (ends with the Warden Captain). A mid-act boss around zone 5 and the act boss at about zone 10.
- **Demo scope:** the intro, the arrival fight, the hub and about 5 zones with 2 bosses (35–45 min).

## Platform
- Engine: Godot
- Release: Steam (PC)
- Team: solo developer (first game; full-time software dev)
- Pace: ~20 hours/week, sustainable over years

## Art direction v2: gritty world, PixelLab creatures (2026-11-09, IN PROGRESS)

Decided with the user after the size and grimdark mockups. This section wins over older art notes below where they disagree; the old 16×16 rules still describe the art that hasn't been switched yet.

- **Look: GRITTY (grade B).** The world is darker and greyer: ashen foliage, grey slush, cold stone. It is done by remapping each world colour to a darker Apollo colour (the table below), never by a night filter over the screen. The hero, attacks, effects, elites' auras and loot are the only bright, saturated things on screen. Attacks must be flashy.
- **Palette:** Apollo, all 46 colours (named in `ApolloPalette`). Every sprite, tile and UI pixel is Apollo; PixelLab output is generated with Apollo as its target palette and checked for 0 off-palette pixels.
- **View:** unchanged, 480×270 at 4× (16 px tiles).
- **Sizes** (trimmed sprite height, front view):
  - Hero Emberoo by evolution stage: Pyroo ~35 px, Emberoo ~46 px, Cinderoo ~63 px. All directions (front, frontdiag, side, backdiag, back; mirrored for the other side). Full animation set per stage.
  - **Trash = the AI God's machines** (drones, walkers, treads, turrets...): ~24–32 px, front view only (mirrored), 2-frame idle/move, a wind-up pose and a strike pose. One shared death: explosion, sparks, scrap, the stolen light bursting out as XP motes.
  - Elites: ~40–48 px. Bosses: 96–128 px. Humans (Wardens, NPCs): ~40 px; placeholders for now.
- **Lore:** wild Glimra are nearly gone, drained to power the machines. Chipped Glimra appear as elites and bosses.
- **Placeholders for now:** the world tiles (regraded old tiles), NPCs, Wardens, the trainer, bosses. Real art now: the hero (all stages and attacks), the trash machines, the UI regrade.
- **Hero gauntlets:** dark obsidian stone with glowing orange/gold cracks (the cracks must read on dark ground). No full-body rim light.

**Trash machines (built 2026-11-09).** Each old trash species is now one of the AI God's machines, same role, stats and code (the scenes and scripts keep their old names, e.g. `toad.gd` is the Seepcan); names pending the formal trademark check:

| Machine | Was | Element | Role | Look (stolen-light accent) |
|---|---|---|---|---|
| **Seepcan** | Toxlop | Toxic | melee, sludge-hose lash (poison) | squat leaking canister walker, green sludge (cyan eye) |
| **Zapmite** | Fizzbug | Spark | rusher/exploder | tiny round spark drone, crackling prongs (magenta eye) |
| **Ramtread** | Gruntite | Stone | charger | tread bot with a rusty stone ram plate (cyan eye) |
| **Augrub** | Bramole | Bloom | burrowing ambusher | drill bot under a dirt mound; only the drill tip shows (magenta eye) |
| **Clamplate** | Brinelob | Tide | shield tank | crab walker: a steel carapace with a cyan core and eye stalks on six jointed legs, between two blue pincer shield claws (hand-drawn) |
| **Chillvane** | Rimoth | Frost | flying support | moth-winged frost drone (cyan core) |
| **Gusteret** | Zephoot | Wind | ranged gust turret | hovering fan turret (magenta eye) |

- Art: `art/machines/<name>/`, 32×32 frames (sprites ~22–30 px), PixelLab generate-image-v2 with Apollo as target palette (Seepcan was the style anchor), poses from a second generation with the base as reference, idle/move from hand-made offsets and glow flickers; 0 off-palette pixels. Front view, mirrored to face the player (`Machine`).
- **One shared death** (`Machine.blow_up`, `MachineDeath`): a jagged white-hot pixel starburst, then an orange fireball, sparks, tumbling scrap, a smoke puff and flecks of the eye's stolen light (~0.4 s, ~40 bits, frees itself); the XP motes take the eye's colour (`scenes/enemies/machines/stolen_light_mote_*.tscn`). Elites add a small camera shake. A Zapmite's own burst blows it apart without freeing light. The Creature Log shows each machine's idle sprite (no painted portraits yet).

**Glue pass for the new scale (2026-11-09).**
- **Aim at the real body:** every enemy that aims at or draws on the hero uses his current form's body height (`CreatureBody`, from `Creature.body_height()`: -16/-22/-30), not the old -6: the Seepcan's hose rises from its spout to his middle, the Marksman's rail line is drawn from the barrel straight through his middle, gust orbs (Gusteret, the Captain's chip pulse) climb to his body height by the time they reach where he stood, light motes and scrap fly to his middle. Every enemy also states its own size (`Enemy.body_height`, `body_half_width`; machines ~-12 to -17 and 10–14 px): the blast, the Chillvane's beam, frost shells, the Zapmite's spark ring and Clamplate plinks sit on it. **Hits are still measured on the ground, feet to feet** (the hose's and rail's lines, the orbs, every ring).
- **Clicks:** a click targets an enemy anywhere on its drawn body (an oval from its feet to the top of its head, its half-width wide, +4 px), so the top of a 28 px machine or a boss's head counts; of several, the one the cursor is most squarely on wins (`MouseOrders.click_margin`).
- **Balance** (hero jab reach + hit radius 37/46/57 by form; jab damage ~1–2 in Ruins Edge, 2 in the fen and quarry, 3 after Awakening I; Spinning Hook 2, Flame Uppercut 3). Melee machines now strike from just outside both bodies (~28–40 px feet to feet) and land on a hero who stands still; trash dies in 1–2 hits for the zone it lives in; elites take ~3× (`EliteModifier.health_multiplier` 3.0, was 2.5; its default tag height 36 and aura 22×7 fit the machines).

| Machine | Health | Ranges and speeds (before → after) |
|---|---|---|
| Seepcan | 1 | hop 22 → 26 px; hose reach 40 (kept), hit width 5 (at the body) → 8 (on the ground) |
| Zapmite | 1 | rush 80 → 90 px/s; stops at 20 → 28 px; burst ring 32 → 40 px |
| Ramtread | **5 → 3** | walk 28 → 32 px/s; charges from 40–90 → 48–110 px, 90 → 110 px long, ram hit 9 → 12 px |
| Augrub | 3 | ambush 40 → 48 px; pops back up at 18 → 26 px; slam 28 → 34 px; burrow 24 → 28 px/s |
| Clamplate | **6 → 4** | walk 22 → 26 px/s; snap 24 → 32 px; front arc 9 → 15 px |
| Chillvane | 2 | keeps 80–100 → 90–115 px; flies 32 → 36 px/s; frost puff 26 → 32 px |
| Gusteret | 2 | keeps 70–110 → 80–125 px; shoots within 150 → 160 px; orb 55 → 60 px/s |
| Handler (Warden) | 6 | rod shove at 22 → 28 px, shockwave 30 → 36 px |

Notice distances, XP and the bosses' numbers are unchanged. Hero run speed stays 60 px/s for now: the v2 Ruins Edge route takes the bot ~2 min, which is fine; if packs feel sluggish in play, ~75 px/s is the next step (`Movement.top_speed`). The Quarry Bull (zone 3's placeholder boss, a Ramtread ×5) drops from 25 to 15 health with this; its zone scene can raise its `health_multiplier` when the zone is rebuilt.

Grade B colour table (world art only; colours not listed stay the same):

| From | To | From | To | From | To |
|---|---|---|---|---|---|
| d0da91 | 819796 | e8c170 | c09473 | df84a5 | a23e8c |
| a8ca58 | 577277 | de9e41 | be772b | c65197 | 7a367b |
| 75a743 | 394a50 | be772b | 884b2b | a23e8c | 7a367b |
| 468232 | 394a50 | 884b2b | 602c2c | 7a367b | 402751 |
| 25562e | 19332d | 602c2c | 4d2b32 | 402751 | 1e1d39 |
| 19332d | 151d28 | 341c27 | 241527 | a4dddb | 73bed3 |
| e7d5b3 | a8b5b2 | da863e | be772b | 73bed3 | 4f8fba |
| d7b594 | 819796 | cf573c | a53030 | 4f8fba | 3c5e8b |
| c09473 | 7a4841 | a53030 | 752438 | 3c5e8b | 253a5e |
| ad7757 | 7a4841 | 752438 | 411d31 | ebede9 | c7cfcc |
| 7a4841 | 4d2b32 | 411d31 | 241527 | c7cfcc | a8b5b2 |
| 4d2b32 | 341c27 | a8b5b2 | 819796 | 819796 | 577277 |
| 577277 | 394a50 | 394a50 | 202e37 | 202e37 | 151d28 |
| 151d28 | 10141f | 10141f | 090a14 | | |

(Water's 253a5e is kept so ponds don't vanish into the floor.)

Applied to the world tiles, NPCs, the trainer kit, the handler and the Wardens. Exceptions to the table:
- **All zone tilesets:** pond/lake water rows (28, and 37–38 in the fen and orchard) keep their `3c5e8b` ripples; the checkpoint post, lore stone and waystone tiles (row 30, columns 0–2) stay ungraded, so they sit a step brighter than the world.
- **Hometown** (the safe place, a touch warmer): paving and plaster go one warm step down (`d7b594`→`ad7757`, `e7d5b3`→`c09473`) instead of to grey; grass `468232`→`19332d`.
- **Galebloom Orchard:** blossoms wither to plum/rust (`df84a5`→`7a367b`, `c65197`/`a23e8c`→`4d2b32`, `7a367b`→`341c27`) so they don't compete with enemies; hay and other orange props go one extra step down (`e8c170`→`be772b`, `de9e41`→`884b2b`, `be772b`→`602c2c`).
- **Shockwire Quarry:** rock heaps (rows 13–26) one extra step down (`884b2b`→`4d2b32`, `7a4841`→`341c27`, `4d2b32`→`241527`), so blocking rock stays darker than the floor.
- **Townsfolk and the trainer:** skin goes one warm step down (`e7d5b3`→`d7b594`, `d7b594`→`c09473`, `c09473`→`ad7757`), not grey.
- **Handler and Wardens:** keep their blue cloth and cyan chip/visor (`3c5e8b`, `4f8fba`, `73bed3`, `a4dddb`; the marksman's `cf573c` visor too).
- Ambient: `AmbientLife` pollen became grey ash with the odd dim ember (`Kind.ASH`), leaves are dead greys/rust, fen motes and quarry dust are fainter; `AmbientDrift` snow is grey ash-snow and orchard petals are withered plum; `WaterGlints` are dimmer. Shadow `core_alpha` on dark ground is 0.58 (was 0.66); the quarry uses the default 0.5.

## Art
- 2D pixel art, made by the developer in Aseprite (studying *Pixel Logic*)
- Tiles and world: 16×16
- Emberoo evolves by Awakening into bigger sprites (Pyroo ~35 px, Emberoo ~46 px, Cinderoo ~63 px; see Art direction v2 and Awakening)
- **Palette: Apollo** (46 colours, Lospec), chosen for its dark tone and clear ramps. Swappable later via Aseprite colour remap.
  - **Every colour we pick comes from Apollo**: art files *and* colours set in code (UI, particles, effects). Checked by script: all art is 100% Apollo; code colours snapped to Apollo.
  - On screen, transparency, fades and glow blend Apollo colours into in-between shades; that's expected and fine.
  - Use ~4–6 colours per creature
  - Darker, muted colours for the world; brighter, saturated colours for creatures, enemies and attacks (readability)
  - No pure black: outlines use `#090A14`; cool darks for world shadows, warm darks (`#241527`, `#341C27`) for the fire creature
- Silhouette first; one consistent light direction
- **Canvas sizes:** small creatures 16×16; bulkier creatures (tanks, bosses) may use 20×20–24×24 when they need the pixels. Pixels always stay the same size (never scale sprites).
- **No night/dark lighting.** Tried a dark tint + 2D point lights; rejected (the banded light rings looked bad). Keep the world bright.

### Art direction (world checklist; every zone follows it)
- **Light from the top left.** Highlights on top/left faces, shade on bottom/right faces, cast shadows fall down-right.
- **Every standing thing has a shadow.** Tiles: a `GroundShadows` node (`scripts/world/ground_shadows.gd`) above the ground/decoration layers and below `World`, with the zone's obstacle layers as `caster_layers`; it builds the shadows from the tiles' pixels (an oval under a narrow foot like a tree or lamp, a band along the base plus a sliver down the right side of anything wide or tall like a house, wall or the forest edge). Characters and pickups draw their own small oval. One style everywhere: Apollo outline `#090A14` with a softer 1 px rim; `core_alpha` 0.5 on bright ground (towns), ~0.66 on dark grass or stone (Ruins Edge, the fen) so shadows still read. Never paint shadows into a prop's tile unless the whole set does it the same way.
- **Value hierarchy:** ground darkest-to-mid and low in contrast, props and walls a step lighter, creatures, enemies, pickups and attacks brightest and most saturated. If a floor shares its lightest colour with an enemy (e.g. the Wardens' `#819796`), drop that highlight one Apollo step on the floor. Blocking walls (forest, rock heaps) sit darker than the walkable floor: the quarry's rock crowns were stepped down one Apollo shade for this. Big paved areas get their highlights stepped down so they don't shimmer.
- **Props make sense where they are.** Crates, barrels and sacks sit in small clusters against something (a stall, a house wall, a workbench), never alone in a field or the middle of a square. Lamps/pylons line roads or mark plaza corners. Debris (rubble, pebbles) only right beside what broke (a wreck, a fallen wall); a lived-in town square is swept. Berries by bushes, waystones or rest spots. Lore stones at landmarks. Nothing overlaps walls, trees, water or paths.
- **Edges aren't razor straight.** Natural paths meander; where a diagonal path steps, grass tufts fill the inner corners. Man-made paving may be straight. Water banks use the corner-shaped tiles, not hard squares (except built stone basins).
- **Depth:** the y-sorted `World` layer lets canopies overlap what stands behind them; walls and the forest edge get contact shade at their base (the `GroundShadows` band does this).
- **Small ambient life**, cheap and faint, never competing with the fight: `AmbientLife` on the zone camera (pollen in sunny meadows, leaves under old woods, fireflies over a fen, grit dust in the quarry; `AmbientDrift` for snow/petals, never both on one camera) and `WaterGlints` on open water.

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
  - **Defeat (he lives):** he staggers, then drops to one knee (`warden_captain_kneel_sheet.png`, 2 frames, visor dark); his implanted chip shows as a cyan glint at his temple (`ChipGlint`, the only time a chip is drawn) that blinks faster and faster, then shorts and cracks in a cyan spark burst, and 30 motes ×4 XP (120 XP, about one level at 4-5) fly out; "WARDEN CAPTAIN DEFEATED" shows top-centre for 2 s. Chip drop, scrap and the arena flag work as for any boss. Then he speaks, dazed (DialogueBox, `data/dialogue/captain_waking.tres`), and staggers off north through the arena gate, fading, the cracked chip still spitting sparks (`CaptainDefeat`; the story is in "Act 1 outline"). The **boss bar** (name + bar, half-health notch) sits top-centre while he lives and steps aside for discovery cards.
- **Gruntite** (stone, `art/gruntite/`): a clay-rock boar, 5 jabs, health bar once hit. Plods slowly; from ~40–90px a 0.8s wind-up (red eyes, then head down with a hoof scrape and dust) and a straight 90px charge at 3× walk speed: 2 damage + a strong shove. A miss skids into a ~1s daze (the punish window); a wall stops it with a bonk. Super armour while winding up and charging. 8 XP.
- **New enemies (zones 2–5; in Mirelight Fen and Shockwire Quarry, and in the test arena `scenes/main/main.tscn`):** front view, 16×16 (the Marksman 18×28); each telegraphs its area attack with its pose, a ring of its reach on the ground that fills during the wind-up, and a glint at the last moment. Effects only on events.
  - **Bramole** (Bloom, ambusher, `art/bramole/`): a mole whose leafy hood passes for a bush (only its pink bud gives it away). 3 jabs. Sits hidden until you're within ~40px; its eyes peek out (0.3 s), then a 0.5 s claws-up wind-up while the bud opens (super armour), then a slam: roots burst out to ~28px, 1 damage + **Root** 0.8 s. Exposed ~1.2 s after; then it burrows after you and pops again once ~18px away. A hit while hidden makes it pop at once. 5 XP.
  - **Brinelob** (Tide, shield-bearer, `art/brinelob/`; recoloured a step deeper along the blue ramp so it doesn't blur with Rimoth/Zephoot cyan): a crab with its claws up as a shell wall. 6 jabs, health bar once hit. Hits from in front (±55°) plink off with a small push-back; back and side hits, the Spinning Hook and burn get through. It turns to face you at 140°/s (so circling works); a thin arc on the ground shows its front while the guard is up. Within ~24px: a 0.6 s claws-wide wind-up, then a clap: 2 damage + **Soak**. Its guard is down ~1 s after each snap. 6 XP.
  - **Fizzbug** (Spark, exploder, `art/fizzbug/`): a static-charged beetle. 1 jab. Rushes at ~80px/s (1.6× a Toxlop's hop speed), stops within ~20px, glows 0.8 s (flashing faster), then bursts in a 32px ring: 2 damage + **Jolt** to you, 1 damage to every other enemy in the ring (it gets round shells): lure it into packs. A burst gives no XP; killing it first gives 5.
  - **Rimoth** (Frost, support, `art/rimoth/`): a frost moth. 2 jabs. Keeps ~80–100px away; every 4 s a 0.7 s cast with a visible chill beam gives the nearest unshelled ally (within ~130px) a **frost shell** that soaks the next 2 damage (fire, including burn ticks, breaks it in one hit). Cornered (~26px): a 0.5 s tell, then a frost puff: 1 damage + **Chill**. A hit breaks its cast. Kill it first. 5 XP.
  - **Warden Marksman** (human sniper, `art/warden_marksman/`, 18×28; the approved v2 redesign with the coat one Apollo shade darker, #202e37, so he separates from stone): 5 jabs, health bar once hit. Keeps 130–160px away, kneels, and a dashed cyan lock-on line tracks you for 1.0 s, freezes (blinking) for 0.25 s, then a solid rail beam fires: 2 damage. Walls and obstacles block it (line of sight), and he won't start aiming without a clear line; step off the frozen line or dodge through it. Slow to stand back up (~1.1 s). A hit throws off his aim. Drops chips and scrap like a Warden (ChipDrop, 1 in 4) and 16 XP.
- **Shalendrill** (mid-act boss, end of zone 5; `art/shalendrill/`, `scripts/enemies/shalendrill/`, `scenes/enemies/shalendrill/`): a hulking shale-backed mandrill Glimra bound by the AI God, 40×40 front view: brown shaggy fur, layered slate shale on its head and shoulders, slate bracers, a long dark muzzle with a red nose ridge; its stolen light shows as cyan in its eyes, muzzle ridges and stone cracks (the chip itself stays invisible). Stone. **360 health** (a level-11 Emberoo with a sensible build: ~60–75 s for a sharp player, ~80–120 s typical, with real risk). Elite aura (BossAura, larger). It knuckle-walks you down; every attack has super armour while it winds up and a punish window after; a hit can make it flinch at most every 2.5 s:
  - **Knuckle barrage** (≤34px; the Ash Guard check): 0.7 s wind-up, fists cocked, a red wedge fills toward you; then 3 punches 0.22 s apart (1, 1, then a 2-damage haymaker), each turning up to 30° after you, 40px reach. Back out of reach, or take it on **Ash Guard**: a punch that lands on the guard cracks its knuckles and it **reels 1.8 s** (instead of 0.6 s), and Counter Punch is armed.
  - **Quake slam** (≤100px; the dodge check): 1.0 s with both fists overhead, a faint red disc and pulsing ring show the reach (104px); then a **gapless** ring of cracking ground rolls out (3 damage + shove): **dodge-leap it** or stand beyond it. Phase 2 sends a second ring 0.9 s later (longer than a dodge and its cooldown). Its fists stay stuck 1.6 s after: the best punish window, right where a hop over the ring lands you (Ember Hop's trail burns it there).
  - **Boulder leap** (64–170px, when you keep away): 0.55 s crouch while a red circle fills where you stood, then a 0.6 s leap (can't be hit in the air) onto it: 3 damage, a throw and a 0.5 s stagger in 28px. It lands heavily (1 s).
  - **Phase 2 at half health:** it roars ("RRRAAAWRR!", the roar pose, cyan shockwaves, a shove that throws you out of reach, no damage), wind-ups and recoveries ×0.75, walks ×1.35, and adds **Rockfall** (rears up; 4 red circles, one on you, three scattered, fill 1.1 s while shale drops: 2 damage each) and **calls 2 Fizzbugs** (at most 2 out, a new pair only when both are gone, every ~14 s; under the zone summon cap; spawned only in its line of sight). Lure their bursts into it.
  - **Death:** it reels, sinks to its knuckles while the cyan in its eyes and stone goes out, then the chip shorts in a cyan spark burst and 40 motes ×7 XP (280 XP, ~2/3 of level 11→12) fly out; "SHALENDRILL DEFEATED". **No chip or scrap**: chips only drop from humans (see "Loot: hacked chips"); a hand-placed Glimmer Shard behind the arena is the zone's bigger reward. Shows its own boss bar (like the Warden Captain), so its BossArena's `boss_bar_name` stays empty.
  - **Test arena:** `scenes/enemies/shalendrill/shalendrill_test_arena.tscn` (no save; `BossTestLoadout` makes Emberoo level 11, Awakened, with an 11-point build), walk north through the gate to start.

### Creature #1 (player): Emberoo
- Fire kangaroo boxer. Three evolution forms (`art/emberoo_v2/stage1..3`): idle (with blink), hop (his walk), jab, jab2, uppercut and dodge in five views (front, frontdiag, side, backdiag, back; the left side mirrored). Missing jab2/uppercut views fall back to the jab sheet. The jab lands as its fist-out frame 1 starts (0.10 s, 0.40 s in all); Flame Uppercut bursts as the fist-up frame 2 starts (0.17 s).
- Jab: hold to repeat, alternates fists, roots you in place. Dodge: a kangaroo leap that can cancel a jab.
- **Skills on Q/W/E/R** (the skill bar), paid with Heat. **Flame Uppercut (E):** 3 Heat, 2s cooldown; a rising punch that bursts into a ~100° fan of crisp pixel flame tongues (reach grows with his form: 40/52/64 px), 3 damage + strong knockback to everything in it. Roots you; the dodge can cancel only its wind-up. Q, W and R are empty for now.
- **Controls:** mouse is the main control; arrow keys also move (no WASD, since W is a skill key). Space = dodge, F = Trainer's Aid, K = Ember Tree, C = Link Rod (once the Tinkerer has made it). Next to a townsperson, F or E talks instead.

## Naming
- Creature names blend **[element/trait] + [animal/sound]** into 2–3 fun syllables (e.g. **Emberoo**). Each evolution stage has its own name: **Pyroo → Emberoo → Cinderoo** (user's pick, 2026-11-09; quick web check: no game uses Pyroo or Cinderoo; Magmaroo was rejected because it is a Dragon Quest IX volcano).
- Every name must be original and checked (web + later USPTO/EUIPO) before use.
- Names in use: **Glimra** (the creatures), **Pyroo / Emberoo / Cinderoo** (the player's fire kangaroo line), **Toxlop** (toxic toad), **Zephoot** (wind puff-owl) and **Gruntite** (stone boar), both pending the trademark check; **Bramole** (bush mole), **Brinelob** (shield crab), **Fizzbug** (spark beetle) and **Rimoth** (frost moth), also pending the trademark check; **Shalendrill** (shale mandrill boss; no web hits, pending the formal check); **Wardens** (the Handlers; fine for enemies, not as a game title).

## HUD
- **Health: one heart** at the bottom-centre, filled with red that drains from the top down as health is lost, with the numbers beside it (e.g. 7/10) in a tiny pixel font.
- **Enemy health:** Wardens (the Marksman too), Gruntites and Brinelobs show a small bar once hit; one- and two-hit mobs show none.
- **Bottom cluster, centred, left to right:** the heart (with the Trainer's Aid flasks lying on top of it), the skill slots **Q W E R** in one evenly spaced row (key labels, cooldown veils), then the Heat flame, evenly spaced (5 px between the heart, the slot row and the flame; 3 px between slots).
- **No mana yet.** When skills arrive, Emberoo's resource is **Heat**, gained by landing hits and spent on fire skills, shown as **fire pips** next to the heart. Each element class gets its own resource.

## Skill tree presentation
- **Radial "Ember Tree":** Emberoo's live idle animation sits at the centre; the tree grows outward in rings. Inner ring = stage 1, middle ring opens at Awakening I (level 10), outer ring (Ultimates) at Awakening II (level 25).
- Skills are diamond **embers**, stat picks are round **coals**; learned nodes glow, available ones are outlined, locked ones are cold coal. Learned paths are **flame veins**; learning a node sends fire along the vein.
- Same rules underneath as before (skill → Enhanced → choose 1 of 2; stat nodes between).
- Each element's tree has its own motif (fire veins for Emberoo; e.g. glowing mycelium for toxic).
- UI is **hybrid**: pixel-art icons and frames, text rendered at higher resolution for readability.
- **Premium polish checklist:** eased motion everywhere (no popping), 2D glow on bright pixels, a unique hand-drawn icon per skill, one good licensed pixel font, a custom 9-slice frame, generous spacing, sound for hover/learn/unlock, consistent style across all screens.
- Mockups: radial ember tree and column tree (session scratchpad; regenerate if needed).

## Creature Log (the bestiary)
- **Why we track creatures:** the Creature Log is Emberoo's **bestiary**. The `CreatureLog` autoload records each species the first time you meet it (the discovery card pops up) and SaveGame keeps that list.
- **What it will show, per species met:** its name, element and portrait; **what it does**: its attacks and the status effects they bring (e.g. "Tongue lash poisons: 1 damage every 1.5 s for 3 s"; "Charge ram staggers"); and **tips** for fighting it (e.g. "Dodge through the gust orb"; "A missed charge leaves it dazed: punish it").
- Unmet species stay hidden (a silhouette at most), so the log fills up as you explore. Elites and bosses can get their own entries.
- **No screen yet:** the data is recorded now; the Creature Log screen is parked (PARKING_LOT.md).

## Visual hierarchy (applies to every enemy)
Brightest and busiest first: **player** > **danger cues** (attack tells, projectiles) > **elites/bosses** (auras, glows) > **trash mobs** (readable but quiet) > **world**.
- Trash mobs get no ambient particles; their monster feel comes from design (silhouette, one signature feature, expression).
- Trash effects only on **events**: e.g. Toxlop's toxic splat on death and droplets on its tongue lash.
- Ambient auras are reserved for elites, so an aura means "this one's dangerous".

## Elements
- **Vertical slice: flavour only.** Element sets colours, effects and theme; no damage rules.
- **Soon after: status effects.** Each element applies its own effect (fire = burn, toxic = poison over time).
- **No type chart for now.** Revisit only when there are many elements.

### Enemy status effects
Enemies give the player mild elemental effects, **sparingly**: they must never get annoying.
1. **Only signature attacks apply effects,** never every hit. Effects are short and mild by default; only elites and bosses get stronger ones (each attack exposes its effect numbers as parameters).
2. **Always telegraphed:** only attacks the player can see coming and dodge (a dodge avoids the hit and the effect).
3. **No lock-downs:** after any movement-impairing effect (stagger, push, later slow or root) the player is immune to that effect for **2 s**.
4. **Clear visuals:** a subtle tint pulse on Emberoo (green for poison, stone for stagger); a small 7×7 pixel icon beside the heart with a draining timer bar; tick numbers in the element's colour over Emberoo. A tick only tints the heart's rim for a blink (no shake or flash).
- **Toxlop, poison (Toxic):** only a tongue lash that lands poisons: 1 damage every 1.5 s for 3 s (2 ticks). A new lash refreshes it (no stacking yet).
- **Gruntite, stagger (Stone):** only the charge ram staggers: 0.4 s in which the current jab or skill is cut off and Emberoo can't act, on top of the damage and shove. Then 2 s of stagger immunity.
- **Zephoot, push (Wind):** the gust orb's small push is the Wind effect; once pushed, other gusts can't push again for 2 s (they still hurt), so a volley can't juggle.
- **Bramole, root (Bloom):** only the root slam roots: 0.8 s in which Emberoo can't walk or dodge but can still jab; a small tangle of roots holds his feet. Then 2 s of root immunity.
- **Brinelob, soak (Tide):** only the claw clap soaks: 20% slower for 1.5 s. Then 2 s immunity.
- **Rimoth, chill (Frost):** only the cornered frost puff chills: 15% slower for 1.5 s. Then 2 s immunity. (Slows stack by multiplying.)
- **Fizzbug, jolt (Spark):** only the burst jolts: the next jab within 1 s comes out 0.15 s late. Then 2 s immunity.
- **Counters:** Ash Guard blocks every enemy status effect (the hit still lands at half damage); Unshakable halves staggers (0.2 s).
- Code: one system. `StatusEffect` (attached at runtime, by node name, with the immunity), `DamageOverTime` (Burning, Poisoned), `ImpairingEffect` (Staggered, Buffeted, Rooted, Jolted, and `SlowingEffect`: Soaked, Chilled); the player's `StatusResistance` decides what lands. Ticks go through `Health.take_tick_damage` with their `DamageType`. Enemy defences are `HitShield`s on a Health (a Brinelob's shell turns front hits away, a frost shell soaks damage); hits say how they come in (`Health.HitKind`: strike, sweep or fire).

### Enemy #1: Toxlop, the toxic toad (locked)
- Purple toad with toxic green warts, yellow eyes; 16×16, sprite in `art/toxic_toad/`.
- **Front view only:** always faces the camera and hops in any direction (like a slime), so one view covers everything.
- Animations: idle 2, hop 4 (code lifts it in an arc with a ground shadow), attack 3 (mouth opens; the tongue is drawn in code toward the target).
- Hurt/death via shader flash and fade.
- Hyena was dropped as the first enemy (four-legged side view too hard at 16px); it may return later as a bigger enemy.
- Later enemies, one at a time: tick (drains energy), vulture (circles then dives).

## Progression
- Levelling + Awakenings + skill trees
- Skill tree inspiration: Grim Dawn, PoE 2, Last Epoch, Diablo 4
  - Leaning toward D4-style skill tiers + "pick one of two" modifier choices
  - Stat-choice nodes are welcome
  - Keep trees small: dozens of nodes, not hundreds. Depth from combinations, not quantity.
- **Gems instead of loot:** gems change how attacks work and carry the build-crafting (the role gear plays in D4). No traditional loot system for now.

## Saving
- One save slot, `user://save_1.json`, written by the `SaveGame` autoload. It has a `version` field; older files are migrated in `SaveGame._migrate`, and damaged or newer-version files are moved to `save_1.unreadable.json` and the game starts fresh.
- Saved: level, XP and debug bonus points (Progression), the Awakening stage (Awakening; it decides which tree rings are open, and a save without one gets the stage its level has earned), learned Ember Tree node IDs (EmberTree), species met (CreatureLog), Glimmer Shards found by ID with their rewards (ShardInventory; a found shard never appears again), the Link Rod's chips, equipped chips and scrap (LinkRod), the last checkpoint reached with its zone (Checkpoints), story flags (StoryFlags), the current zone and Trainer's Aid charges. Save `version` 2 (version 1 saves get `link_rod_given`, since they already had the rod). Spent points aren't stored: loading gives back every point, then re-learns the saved nodes under the normal rules, so unknown IDs or nodes beyond the points owned are dropped.
- Each system owns its section (`to_save_data` / `load_save_data`); new systems add a section the same way. The tree is saved by node ID only, so nodes added later need no migration.
- Saves automatically on a level up, on Awakening, on learning or unlearning a node, on meeting a new species, on finding a shard, on a story flag, after every zone change, every 60 s and on quitting; writes go to a temp file that is renamed over the save. Loads at game start, before the zone is built.
- The test arena never loads or writes the save (DebugControls' `uses_save_file` is off there). Debug keys: F4 cycles the Awakening stage, F5 saves now ("SAVED" toast), F6 makes Emberoo fall (tests death and respawn), F7 gives a tier-2 chip and 50 scrap, F9 deletes the save and restarts fresh.

## Death and respawn
- **Forgiving, ARPG style** (PoE / Last Epoch campaign checkpoints). No XP or progress is lost for now; a penalty (e.g. some XP toward the next level) could come later, once the game has the depth to make it fair.
- **The fall (about a second):** Emberoo freezes on his crouched hop frame, sags, darkens and fades (`CreatureFall`) in brief slow motion; then the screen fades to dark with a small "EMBEROO FELL" in the HUD's pixel font (`DeathScreen`). `Respawner` (in the GameLayer) runs the sequence.
- **In the dark** (`WorldReset`): enemies already killed stay dead; living ones heal to full, lose their status effects and go back to their spawn points, unaware (`Enemy.return_to_spawn`); summoned creatures vanish. Emberoo gets back up at full health, with no Heat, every Trainer's Aid charge and no status effects, and bounds in with the zone-entrance hop.
- **Checkpoints** (`Checkpoint`, a Marker2D in group `checkpoints`): walking within ~40 px makes one the last reached, with a small "CHECKPOINT" toast (`CheckpointToast`); a waystone's flame glyph glows while it's the current one (`WaystoneGlow`). Each zone has a start checkpoint at the spawn (`is_zone_start`), reached silently when the zone starts and never by walking back. The `Checkpoints` autoload keeps the last one (with its zone) and saves it, so loading a game starts you there.
- **Ruins Edge:** `Checkpoint_Start` at the spawn and `Checkpoint_BossGate` at the waystone before the Final Arena.
- **Arriving through a zone exit** makes the entry (`ZoneEntry`) the last checkpoint. Hometown Outskirts: `Checkpoint_Start` at the landing spot; Hometown: the entries and `Checkpoint_Waystone`.
- **Bosses:** falling in the Warden Captain fight starts it over: he heals to full, goes back to phase 1 and his spawn, his bar hides, the gates open (`BossArena.start_over`), and you get up at the boss-gate checkpoint (starting the fight counts as reaching it, silently).
- **The test arena** has no checkpoints, so you get back up where you fell.

## Scope rules
- Vertical slice first, placeholder art allowed: 1 creature, 1 enemy type, XP/levelling, 1 Awakening, 1 small skill tree (3–5 nodes).
- If it isn't fun with boxes, better art won't fix it.

## Code rules
- **Throwaway code goes.** A mockup, demo or prototype is deleted as soon as the real thing replaces it (git keeps the history).
- **One responsibility per file.** Aim for under ~200 lines; past that, split it into components or helpers.
- **Readable names.** Say what a thing is or does (`move_direction`, not `dir`); no unexplained magic numbers.
- **Colours only from the shared Apollo palette** (`scripts/ui/apollo_palette.gd`, `ApolloPalette`). Never a raw `Color(...)` value in a script; screen-specific roles (e.g. `EmberTreePalette`) are built from it.
- **Components over big classes.** A creature or enemy is a thin coordinator; each job (input, click orders, summoning, a shove, drops on death) lives in its own child node or helper.

## Open questions
- Core gameplay loop: draft is hub → link into zone → fight → XP + gems → hub to spend → harder zone → Awaken
- Gem system details

## Reference games
- **Monster Sanctuary:** per-monster skill trees, near-solo dev (turn-based)
- **Creature Keeper:** real-time creature-taming ARPG
- **Adore:** action roguelite, summon and control creatures
- **Hades:** melee game feel
- **Last Epoch / Grim Dawn / Diablo 4:** skill trees
