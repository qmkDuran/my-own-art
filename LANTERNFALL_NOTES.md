# LANTERNFALL — design and handoff notes (keep updated every pass)

A fast action RPG in Godot 4.7.2 (typed GDScript). One class, the Lamplighter. Everything you see and hear is
made by code (Python+PIL sprites, Godot shaders/particles, numpy/scipy audio). Fonts: Pixelify Sans and
Silkscreen (OFL, licences in `game/fonts/`). Read STYLE.md (look) and CODE_STYLE.md (code) with this file.

Status: **pass 2 — Act 1 playable**: Tallow (hub, people, services), the Glasswood, the Ember Road, Moth Hollow
and the Moth Matron; quests and dialogue as data; zone travel; loot filter; save format 2. See "Progress".

## 1. Premise and story bible

**The world.** Three hundred years ago the sun went out. People live in walled cities under Great Lanterns,
each burning a *sunshard*. Outside is **the Dusk**: a living darkness that *rewrites* what it swallows — a forest
turned to glass, a river that runs upward, a town reliving one Tuesday forever, a desert where shadows are solid,
a bell tower drowned in air. Rewritten places follow dream logic, because they are dreams.

**The truth (revealed across the acts).** The sun is not dead. It is **asleep**, and the Dusk is its nightmare.
Three hundred years ago it had a fever — **the Long Noon**, a year without night that burned half the world. The
first Lamplighters **lulled it to sleep** with the Lull Bell and cut shards from it to light the cities. Every
lantern is a piece of a wounded, dreaming sun. Each boss is a **memory the sun fears**. The finale asks whether to
wake it, knowing what happened the last time it was awake.

**Tone.** Grim, quiet, strange; people are wry and stubborn, not grimdark-edgy. Short lines, never walls of text.
Lore is optional (notes, objects, places). No religious content, no borrowed fantasy staples (no elves, dragons,
chosen-one prophecy, dark lord).

### The city: Tallow
The last city in reach, under the Great Lantern (the "Old Flame"). Soot, oil, brass, wax. The hub grows as you
bring people home (each rescue opens a service or a side story).

### Characters (lineup: `npc_lineup.png`)
| Who | What they want | Arc |
|---|---|---|
| **The Lamplighter** (you) | A man, the Ninth of the order; few words; gold eyes under the brim | From errand-runner to the one who decides the sun's fate |
| **Mother Ottilie Brask** — Keeper of the Great Lantern | Keep Tallow lit at any cost | Raised you; has always known what the lanterns burn. Lies out of love; confesses in Act 4; gives her own shard in Act 5 |
| **Captain Ysolde Marr** — Commander of the Wall | Shut the gates, keep the living alive | Shot the last person who came back "wrong". Learns to open the gate; holds it alone in Act 4's siege |
| **Nim Saltry** — wall-runner, 11 | Be a Lamplighter; map everything | Taken by the Dusk in the opening. A liar and a mapmaker; her maps of the Dusk turn out to be maps of the sun's dreams. Taken again in Act 3 (the Tuesday loop) |
| **Auntie Fenn Caddock** — smith of the Ember Forge | Make things that last | Crafting. Deaf, loud, forges with sunshard slag; knows what the slag screams |
| **Lio Quill** — Archivist of Rewritten Things | Understand the Dusk | Keeps rewritten objects in jars (a teacup that is always tomorrow). Pieces the twist together; tempted to let the Dusk rewrite him |
| **Hask** — a man the Dusk half rewrote | To be finished, one way or the other | Companion/rival: helps, lies, works for Teague; in Act 4 chooses a side |
| **Teague Morrow** — the Eighth Lamplighter (missing) | Keep the sun asleep forever | Your teacher. His notes are in every zone. Act 4 antagonist: he wants your shard to deepen the sleep (the Dusk spreads, but no Noon ever again). He is not wrong |
| **The Sleeper** | To stop being afraid | Speaks only in Act 5, through dream fragments |

### Acts (5 x ~2 h) — zones, what makes each different, bosses
Each zone is generated from its own biome rules + set-pieces (see section 4). Bosses are fears of the sun.

**Act 1 — Beyond the Wall** (glass and moths). Hook: the Great Lantern goes dark for seven heartbeats; something
takes Nim over the wall.
1. **Tallow** (hub). Lantern Square, Ember Forge, the Archive, the Wall Gate.
2. **The Glasswood** *(built: the test slice)* — a forest turned to glass; trees chime and catch your light;
   a glass stream, a woodcutter's hut, Brennick fishing in glass, Teague's cairn, a watchtower, an expedition's
   camp, a hidden Lamplighter cache, the stone ring. Mini-boss **the Glazier** (fear: the hands that cut it).
3. **The Ember Road** — farmland under dead waylamps; relighting reclaims the road (zone-wide relight event).
4. **Moth Hollow** — caves of cocoon-silk; zones of "hunger" where moths drink your Light.
5. **The Matron's Nest** — boss **the Moth Matron** (fear: being devoured). Reveal: Teague's notes say the Dusk
   is *remembering*.

**Act 2 — The Upward River** (water falling into the sky).
1. Riverbank Hamlet (rescue: the ferrywoman → hub boat to Act 2). 2. **The Rising Falls** (platforms on falling-
up water; currents move you). 3. **Saltmarsh of Lanterns** (drowned lanterns as wisps; light lures). 4. **The
Drowned Belfry** — boss **the Bellwright**; reveal: the bell is the Lull Bell; the order rang it.

**Act 3 — The Town of One Tuesday** (a loop).
1. Hollin's Ford outskirts (clocks stopped). 2. **Tuesday Market** (the zone resets every few minutes; things
you change stay changed). 3. The Schoolhouse (Nim, taken again, found mid-loop). 4. **Clocktower Square** — boss
**the Mayor of Tuesday**, fought across loops; reveal: Tuesday was the last day of the Long Noon.

**Act 4 — The Umbral Waste** (shadows are solid).
1. Scorchline (Noon-burnt land). 2. **Dunes of Cast Shadow** (a false sun moves; shadows are walls that sweep
the map). 3. The Sundial City. 4. **Teague's Camp** — boss **the Hollow Lamplighter** (Teague). Tallow is besieged
meanwhile (Ysolde's stand); Ottilie confesses.

**Act 5 — The Sleeper's Hollow** (inside the dream).
1. The Ashen Stair. 2. Memory Gardens (fragments of every earlier zone, remixed). 3. The Lulling Hall (where it
was done). 4. **The Heart of Noon** — boss **the First Lamplighter** (the sun's deepest fear: the people who cut
it). **The choice**: *Wake* (return the shards; Tallow goes dark first; dawn — or fever), *Lull* (ring the bell;
the Dusk recedes for another three hundred years; you become the Keeper), or *Stay* (enter the dream as its
lantern so it can wake gently). The endgame continues whatever you chose.

### The opening (as built) — hook in the first minute
Title → four short cards ("…for seven heartbeats, it went dark. Something came over the wall… It took a child.")
→ you stand at Tallow's gate with Captain Marr; **gloams pour through within three seconds**. Then: the
Glasswood with people worth talking to (Marr, Hask), a side story (Brennick in glass, his daughter's note), a
mystery (Teague's cairn: "Ask her what the Great Lantern burns"), a secret (a deer trail to a Lamplighter cache:
"Rule two: it is not a stone"), relight events, an elite or two, the Glazier holding Nim in glass.

## 2. Activities and the grind (designed; slice builds the starred ones)
- **Main story** (5 acts, ~25 zones, ~10 h). *Act 1 zone 2 built.*
- **Waylamp relights*** — hold a lamp while the dark sends waves; a lit lamp is a safe zone, respawn point,
  tonic refill. A zone with all lamps lit is **Reclaimed**: its map turns gold, a vendor or person moves in,
  and its Dusk version unlocks for the endgame.
- **Side stories** — one per zone, told through objects and a person (Brennick's daughter; the ferrywoman; the
  boy who keeps Tuesday's newspapers). Reward: hub growth + a unique.
- **Rescues → the hub grows** — every person saved opens something in Tallow (forge, archive, map room, stable
  of light-moths, a fortune-teller who rerolls a unique's lore stat).
- **Vaults** — optional sealed dungeons behind a Lamplighter door (key: a lore set), with a puzzle of light
  (carry/throw the lantern to open shutters) and a guaranteed set item.
- **Roaming Dusk-beasts** — rare named bosses that wander a zone and flee into darkness; tracked by Nim's maps.
- **Bestiary and Archive** — kill counts reveal lore lines and a small permanent bonus per family; Lio's jars
  collect rewritten objects (collections with set bonuses).
- **Crafting at the Ember Forge** — see 5. **Endgame Dusk maps** — see 6. **Chase uniques** — build-defining
  (examples in 5).

## 3. The class: the Lamplighter
A caster with a **lantern staff** (the lantern hangs from a hooked staff) who conjures a **light whip** for close
range. Resources: **Life**, **Oil** (skill cost), and **Light** (the lantern; see 3.3). Controls: LMB move/attack
(hold), Shift stand-and-attack, RMB Q W E R skills, Space Wickstep, 1 tonic, I C K P panels, Alt labels, Esc menu.

### 3.1 Passives (Last Epoch-style)
One point per level. **Base tree "Lamplighter"** (14 nodes in rows needing 0/5/10/15 points). At **level 8** choose
a **mastery** (bonus + its own tree); the other two open after 20 base points.
- **Beacon** — hold the light up: big radius, steady flame, Flare; ultimate **Noon**. Bonus +25% radius, +10% Blazing damage.
- **Mothwright** — breed fire in the lantern: moths, ignite, spells; mastery skill **Cocoon** (a moth-nest turret).
- **Duskwalker** — the dark's own manners: damage to Shrouded enemies, dashes, crits; mastery skill **Eclipse**.
Full trees later: ~30 base nodes, ~20 per mastery, with a few keystones that change rules (e.g. *Lighthouse
Keeper: your light no longer shrinks when hit, but never grows past 60*).

### 3.2 Skills (each levels to 20; 1 specialisation point per level; trees change behaviour)
Built (trees partly): **Sunlash** (whip combo; Backhand, Sunwave crescents, ignite, Light on hit), **Flare** (burst
sized by your Light; Lancet cone, Spend the Flame, Afterglow, stuns), **Lantern Toss** (throw the lantern, fight in
the dark, recall; Beacon exposure, Dark Adept, Tether, Ember Trail), **Moth Swarm** (seeking ember moths; Brood,
Cinder bursts, Linger, Guardians catch shots, Matriarch), **Wickstep** (dash).
Planned: **Eclipse** (shutter the lantern: everything Shrouded, you hit like the dark), **Noon** (ultimate: one
breath of daylight), **Kindle** (burning aura), **Glass Ward** (barrier of shards), **Hook** (whip pull),
**Cinder Rain**, **Wick Trap**, **Lull** (a bell-tone that stuns and slows). Five specialisation slots (levels 1,
1, 3, 5, 10). Names are short; veto freely.

### 3.3 The Light mechanic (numbers in `game/data/light.json`)
- Light 10–100, start 60. **Radius = (70 + 1.5 x Light) px x (1 + light radius %)** → 85 px at 10, 160 at 60, 220
  at 100. Drawn as a banded warm light with a faint dashed ring at the edge.
- **Hit**: lose 2 + 14 x (damage / max life), less with "Less Light lost when hit". Light-Drinker elites take 6 more.
- **Kill**: +3 (magic +6, rare +12, boss +30) + Light on kill.
- **Drift**: below 35 it recovers 2.5/s; above 65 it settles 0.8/s → never stuck in the dark, high Light is earned.
- **Shrouded** (outside every light: yours, a thrown lantern, a lit waylamp): enemies take **25% less** and deal
  **25% more**; they show as silhouettes with glowing eyes. Builds can flip this (Duskwalker, Night Eyes, The Long Night).
- **Blazing** (80+): +15% damage (+ Brightness, Noonday). **Guttering** (<25): a warning state.
- Skills use it: Flare's size follows Light; Spend the Flame burns 15 Light; Lantern Toss moves the light away.

## 4. Zones from rules (how the generator works)
`ZoneGen` builds a `ZoneLayout` from biome JSON in steps, each with a reason (`scripts/world/zone_*.gd`):
geography (city wall + cleared strip, the stream, clearings away from water and each other, ponds) → paths (MST +
loops by A* over terrain costs: they meander, merge, avoid ponds, cross the stream where a bridge is built; a
deer trail to the secret) → closed border → set-pieces (props placed together on open ground of their clearing,
never on paths/water/each other; chests next to the thing that explains them) → edge glass where clearings meet
the forest, away from routes → trees only inside the thicket with trunks clear of open ground → packs (harder
mixes further from the gate, a few elite packs). **LayoutCheck** enforces every rule; `ZoneGen.make()` retries
the next seed if any fails. The Glasswood: 150 x 96 cells of 32 px (4800 x 3072 px, about 30 screens), ~34
packs (~120 enemies), 3 waylamps, 4 chests, 1 secret, 3 lore objects, 2 people.

## 5. Itemisation (data: `game/data/items.json`)
Slots: Lantern Staff, Relic (hand lanterns, oil flasks, charms, reflectors), Head, Body, Hands, Feet, Belt, Neck,
2 Rings. Rarities: **Normal, Magic (1–2 affixes), Rare (3–4; max 2 prefixes + 2 suffixes), Set, Unique**. Affixes
have **5 tiers** gated by item level (higher tiers rarer). Tooltips show tier, ranges, and the difference against
what you wear. Built uniques: **The Long Night** (staff: huge damage vs Shrouded, smaller radius, Sunlash always
ignites in the dark), **Moth-Mother's Wick** (+3 moths, moth hits feed Light), **Glasswalker Treads** (Wickstep
leaves cutting glass), **Ottilie's Spare**; set **Ninth Watch** (2 pieces).
**Crafting (planned, the Ember Forge):** *Embers* drop from kills: Kindle (add an affix), Temper (raise a tier),
Quench (remove one), Anneal (reroll values). Each item has **Heat** (forging potential) that each craft spends
(random amount; a crit spends none). **Kindled uniques** (unique + rolled affixes via a sacrificed rare) are the
long chase. A **loot filter** (praised in LE) is planned early.

## 6. Endgame: Dusk Maps (planned)
Reclaimed zones reopen as **Dusk Maps**: generated variants with stacked **modifiers** (Darker: radius -30%;
Starving: no Light from kills; Swarming; Glass-Skinned packs; Upward: projectiles curve; Tuesday: the map resets
once). Tiers 1–10 raise level, density and drops; a **Dreamline** (a branching path of maps, like LE's echoes)
ends in a **pinnacle**: *the Fever* (the Long Noon given shape), *the Lull Bell*, *Teague Unmade*. Corruption-like
scaling ("Depth") raises rewards without a cap.

## 7. Research summary (mechanics only, nothing copied)
Last Epoch: base class tree → mastery after 20 points; nodes gated by points spent in that tree; specialisation
slots unlocked by level; each skill levels to 20 and has its own tree; respec costs gold ([Upcomer](https://upcomer.com/how-to-specialize-in-skills-in-last-epoch),
[Gamespot respec](https://Gamespot.com/articles/how-to-respec-mastery-and-skill-points-in-last-epoch/1100-6521217/),
[bloxodes masteries](https://bloxodes.com/wiki/last-epoch/masteries)). Items: 2 prefixes + 2 suffixes, affix tiers,
**forging potential** spent per craft, legendary = unique + affixes ([Icy Veins crafting](https://www.icy-veins.com/last-epoch/crafting-guide)).
Endgame: Monolith timelines, echoes, corruption ([Icy Veins Monolith](https://www.icy-veins.com/last-epoch/monolith-of-fate-overview-for-last-epoch)).
Praised: the loot filter, build depth, crafting. Criticised: **weak story, forgettable characters, no clear
villain, slow opening**, late-game grind repetition ([PC Gamer](https://www.pcgamer.com/last-epoch-review/),
[PCGamesN](https://www.pcgamesn.com/last-epoch/review), [Shacknews](https://shacknews.com/article/138830/last-epoch-review-score?amphtml=1)).
Our answers: a hook in minute one, a villain you love (Teague), people with arcs, a story told in short lines;
endgame modifiers that change how maps *play*, not just numbers. (maxroll.gg was not reachable from this session.)

## 8. Production plan (honest)
One "pass" = one long working session. The slice took one pass.
| Pass | Content |
|---|---|
| 1 (done) | Design, test slice, checks, video |
| 2 | Feedback fixes; Tallow hub (walkable, 6 people, services); dialogue/quest system; Act 1 zones 3–5 + Moth Matron; loot filter |
| 3 | Eclipse, Noon + 4 more skills; full passive trees + keystones; 5 slots; respec |
| 4 | Ember Forge crafting; more uniques and sets; bestiary/archive |
| 5–8 | Acts 2, 3, 4, 5 (one act per pass: 4 zones, a boss, its story, new enemies/biome rules) |
| 9 | Endgame Dusk Maps + Dreamline + 2 pinnacles |
| 10+ | Balance, polish, performance, audio/music per act, accessibility |
Realistic total: 10–12 passes for the ~10 h campaign + a first endgame; content quantity (enemy kinds, art) is
the bottleneck, so each act reuses the systems and adds biome rules, set-pieces and 4–6 enemies.

## 8b. Pass 2: how the campaign runs
- **Zones** (`data/zones.json`): id, biome file, seed, enemy levels, music, `links` (for routing). A new game starts in
  the Glasswood at Tallow's gate. `Session` (static) carries the character, the `Campaign` and every visited zone's
  state between zone scenes; `Session.travel()` captures and reloads the game scene in the next zone.
- **Exits**: set-pieces of kind `exit` (`to`: zone) — a road gate, a cave mouth, Tallow's gate. You arrive in front of
  the exit that leads back where you came from; map travel (Nim's maps, any lit waylamp) arrives by a lit waylamp.
- **Quests** (`data/quests.json`): ordered steps, each done by an event (`enter_zone`, `talk`, `boss_seen`,
  `boss_down`, `lamp_lit` with a count, `read`, `flag`); a target per step drives the tracker and the minimap's
  objective diamond (in another zone it points to the exit on the way). Rewards: xp, a unique, a set.
- **Dialogue** (`data/dialogue.json`): per person, topics in order with conditions (`quest_step`, `quest_past`,
  `quest_done`, `flag`, `not_flag`), `once`, effects (`start_quest`, `flag`, `service`). Services: travel (Nim),
  stash (Fenn), respec (Ottilie), bestiary (Lio).
- **Zone story** (`ZoneEvents`, biome `events`): arrival caption, first-visit ambush, the boss (rises when near, its
  music, what its death frees), game-wide tips.
- **Generators**: forest-like zones share `ZoneGen` steps with per-biome data (optional wall and stream, clearing
  counts, ground recolours via `ground`, ring stones, stone style flags/cobbles/silk, wear). Tallow is laid by hand
  (`CityGen`, biome `city`) but goes through the same layout data and checks.
- **New mechanics**: Husk death bursts (telegraphed; simultaneous bursts count once), Silk Crawler shots slow you,
  hunger nests drain Light, the Moth Matron (gust cone that shoves, dust clouds that drain Light, brood of moths,
  smother: your light shrinks to an ember for 4 s). The Lamplighter gains +4% damage per level (data).
- **Loot filter** (L): show/hide each rarity, hide plain pieces by slot, emphasise rare+; hidden drops never land.
- **Panels**: quest log (J), loot filter (L), Nim's maps, Fenn's lockers (with the inventory), the order's ledger
  (refund passives or a skill tree), Lio's bestiary (kills + lore).

## 8b-3. Act 3 (started): the Town of One Tuesday
After Lio's reveal (flag act2_reveal) Tallow's east gate opens. Quest "One Tuesday": Captain Marr says Nim walked
east after a school bell -> Hollin's Ford (outskirts: hedged fields, farmhouses, every clock stopped at four;
Repeaters and Clockfaces) -> the Town of One Tuesday: squares lined with lit houses, a market, the schoolhouse,
Clocktower Square. **The loop** (TuesdayLoop, biome `loop: true`): every 80 s the clocks strike four — everything
alive returns where it stood, whole again; everything dead stays dead; lamps stay lit (HUD clock "Tuesday 3:43").
Nim is stuck at her desk; break the loop by killing **the Mayor of Tuesday** (clock-face head, top hat, a plate-sized
pocket watch): HANDS (two clock-hand lanes, four below half life), REWIND (back to where he stood 4 s ago, regaining
a capped share of lost life), APPOINTMENTS (Repeaters arrive), STOP (time stops for you: a heavy slow). Nim, after:
"At four o'clock the sun went to sleep, and we were so glad." Reward: The Seventh Heartbeat.
Next for Act 3: the Schoolhouse as its own interior zone, Pell-like townsfolk side quests, loop-aware puzzles.

## 8c. Balance (bot-measured; `-- --balance --zone=<id>`, headless, fixed 60 fps)
The DemoBot plays like a player at the zone's intended level (middle of its range; rare staff, coat and relic of
that level; passives and a few tree points spent): it walks up to the 8 nearest packs in order, fights each, then
fights the boss at the top of the range. It dodges warning circles and toll rings only when Wickstep is ready, so
deaths are an upper bound for a human. Tuning done in this pass: enemy damage per level 0.12 -> 0.17, early
enemies x1.2-1.5 damage, Lamplighter +3% damage per level (was 4), Glazier 1100 -> 2000 life and 16 -> 10 damage,
Matron 1900 -> 4200 life, Bellwright 2800 -> 4000 life and 19 -> 11 damage, Falls Heron 15 -> 14.

| Zone (level) | Pack clear (avg) | Life lost per pack | Deaths in 8 packs | Boss | Boss time | Boss deaths |
|---|---|---|---|---|---|---|
| Glasswood (4) | 5.6 s | 2% | 0 | Glazier (lvl 7) | 42 s | 1 |
| Ember Road (8) | 3.8 s | 9% | 0 | - | - | - |
| Moth Hollow (12) | 5.8 s | 1% | 0 | Moth Matron (lvl 15) | 28 s | 0 |
| Upward River (16) | 6.6 s | 11% | 0 | - | - | - |
| Rising Falls (17) | 7.9 s | 21% | 1 | - | - | - |
| Saltmarsh (19) | 2.8 s | 4% | 0 | - | - | - |
| Drowned Belfry (20) | 6.6 s | 16% | 0 | Bellwright (lvl 22) | 66 s | 2 |
Reading: Act 1 packs are easy at the intended level with rare gear (fast and punchy, as intended for the
opening; a player with plainer gear will feel more pressure); Act 2 packs bite (Falls Herons diving in pairs).
The Matron is now the easiest boss for her place — she should get tougher once the bot learns her gust (next
pass). One pack per zone times out because it sits where the bot cannot path to it (ranged moths over water,
or a pack inside a lure) — not a balance issue, but to look at.

## 9. Architecture (`game/scripts/`)
| Folder | What |
|---|---|
| core | `GameData` (all JSON), `Pal` (palette mirror), `InputSetup`, `Audio` (autoload), `Fx`, `LightTex`, `CameraRig` (follow + shake), `SaveGame` |
| world | `ZoneLayout` (data), `ZoneGen` + steps (`ZoneGeography`, `ZonePaths`, `ZonePlacement`, `ZoneForest`, `ZonePacks`, base `GenStep`), `LayoutCheck`, `ZoneView` (shader ground, props, trees, collision), `Nav` (A* grid), `Spawner`, `Telegraph`, `PropSprite`, `TreeFade` (trees in front of a fight turn see-through), interactables (`Interactable`, `Chest`, `Waylamp`, `LoreObject`, `Npc`, `Cocoon`) |
| actors | `Player`, `LanternLight`, `LightField`, `Enemy`, `brains/` (`EnemyBrain`, `SwarmBrain`, `LeaperBrain`, `RangedBrain`, `GlazierBrain`) |
| combat | `Stats`, `Progression`, `Combat` (damage both ways), `Projectile`, `FloatText`, `HitStop` |
| skills | `Skill` base, `SkillSystem`, `Sunlash`, `Flare`, `LanternToss`, `MothSwarm`, `GlassTrail`, `fx/` (whip, burst, thrown lantern, moth, burning ground) |
| items | `LootGen`, `Inventory`, `GroundItem`, `LootDrop`, `LabelStack` |
| ui | `GameUi`, `Hud`, `HudMessages`, `Minimap`, `GamePanel` + `InventoryPanel`, `CharacterPanel`, `SkillPanel`, `PassivePanel`, `PausePanel`, `TooltipLayer`, `ItemText`, `SkillText`, `LightText`, `EnemyTag`, `TitleScreen`, `UiDraw`, `Overlay` |
| story | `Campaign` (flags, quests, said, kills), `Dialogue`, `Objectives` (tracker lines, objective target, routing) |
| core (pass 2) | `Session` (character, campaign, zone states, stash, travel) |
| world (pass 2) | `CityGen`, `ZoneEvents`, `ZoneExit`, `HungerZone`, `ActorCheck` |
| demo | `DemoReel` (staged scenes of a video, `--demo` / `--demo2` / `--demo3` final reel), `DemoBot` (plays like a player) |
| items (pass 4) | `Forge` (craft rules), `MaterialDrop`; ui `ForgePanel` |
| `game.gd`, `game_input.gd` | session wiring and story beats; mouse/keyboard to commands |
`Game.current` is the one documented service locator. Content is data: `game/data/*.json` (settings, light,
player, stats, skills, passives, items, enemies, glasswood biome, story; props.json + sprites.json are generated).

## 10. Art and audio pipeline (all code)
- `python3 -I art/build_art.py [review_dir]` — builds every PNG into `game/art/` (actors with `_glow` emissive
  layers, props, item/skill icons, glyphs, effects) and `game/data/props.json`, `sprites.json`; with a dir, writes
  `reference_sheet.png` and `npc_lineup.png`. Modules: `palette.py`, `pix.py` (drawing kit: outline, rim light,
  emissive), `people.py` (parametric 64 px figures), `enemies.py`, `props.py`, `icons.py`, `reference_sheet.py`.
- The ground is a shader (`game/shaders/ground.gdshader`) over a one-texel-per-cell terrain map plus a smooth
  path mask, stream curve, pond ellipse and stone circle; palette colours with 4x4 ordered dithering.
- `python3 -I art/audio/synth.py` — every SFX (`.wav`) and the two music loops (`explore.ogg`, `boss.ogg`).

## 11. Checks (run every pass: `bash tools/run_all.sh`)
`check_art.py` (palette, size classes, feet don't slide, palette mirror) · `check_code.py` (typed signatures,
function ≤ 40 lines (aim 30), file ≤ 400, ## headers, no print/TODO/commented code) · `--layout` (24 seeds of the
zone through LayoutCheck) · `--ui` (HUD + panels at 8 sizes of 16:9/16:10: inside screen, no overlaps, node names
fit) · `--smoke` (49 checks of the real game headless: stats math, damage + Shrouded, Light, all skills + tree
effects, passives/mastery, 400 loot rolls, equip, drops + label stacking, walk/take, chest/waylamp/note/NPC,
Glazier + Nim, death/respawn, save/load). Review screenshots: `--shots` (needs xvfb). Video: see 12.

## 12. How to run / record
- Play: `godot --path game` (title) or `-- --play` (straight in), `-- --fresh` (no save).
- Shots: `xvfb-run -a -s "-screen 0 1920x1080x24" godot --rendering-driver opengl3 --path game -- --shots --out=DIR`
- Video: `... --resolution 960x540 --fixed-fps 60 --write-movie frames/f.png --path game -- --demo`, then ffmpeg
  scale 2x with `-sws_flags neighbor` (pixel-identical to 1080p, 4x faster to render in software GL).

## 13. Lessons
- Software GL (xvfb) is slow with per-pixel noise: compute the border warp once per pixel; record at 960x540.
- Cell-based terrain looks like stairs; draw water/paths/stone from their true geometry inside blocked cells.
- Props must avoid every route (not just dirt paths) or they plug narrow trails — LayoutCheck caught it.
- 3/4 view: trees south of a path hide the fight — fade trees that cover a body (bucketed, cheap).
- Godot: no global non-uniform shader vars; `const` can't hold class refs; typed arrays need typed sources.

## 14. Progress log
- **Pass 2b/3/4 + Act 2 start**: review fixes (two-frame tinted hit flash, no flash on burns; damage numbers merged
  per target within 0.15 s and stacked; bosses carry their own dim light, are never darkened, and the camera frames
  you and the boss together; the Matron hovers beside you; torn web floor; a check that tall props never hide
  anyone's feet unless faded; brighter Ember Road / Moth Hollow; Tallow dressed with benches, banners, planters, a
  well, barrels and five passers-by, plus an arrival shot of the Great Lantern and a camera lean toward it).
  Six more skills (Kindle, Hook, Glass Ward, Cinder Rain, Wick Trap, Lull) with trees; five specialisation slots
  (Specialise / Forget in the skill panel; only specialised skills level). The Ember Forge (data/crafting.json):
  materials (Ash, Kindle, Temper, Quench, Anneal) drop and fly to you; every item rolls Heat; Kindle adds an affix
  (normal -> magic -> rare), Temper raises a tier, Quench removes, Anneal rerolls, each spending Heat; uniques and
  sets can't be forged. Refunds at the ledger cost Ash. Uniques: Bellwright's Clapper, The Seventh Heartbeat,
  Hearthstone Band, the Matron's Silk (drops from her). Act 2 begins: the Upward River (river flows upward,
  hamlet, dock, rising pools, Odile the ferrywoman, Undertows that slow, Drowned Lanterns that drink Light),
  reached by the Ember Road's north gate after Act 1; quest "The Upward River". Then the Drowned Belfry (a flooded
  square of stone islands and causeways, pillars and rising water, a fallen belfry) reached by Odile's ferry, and
  its boss the Bellwright (a bell-headed giant: toll rings with gaps you stand in or Wickstep through, falling bells,
  Undertows from the water, the Lull Bell smothers your lantern; two rings per toll below half life). Lio's reveal:
  the bell was cast by the order "to be rung only at noon" — we put the sun to sleep. 95-check smoke test.
  Act 2 route now: Upward River -> (north gate, after its lamps) the Rising Falls (a tall cliff of terraces;
  updrafts push you north; Falls Herons dive) -> the Saltmarsh of Lanterns (false lights that spring Bog Lurkers;
  the order's shrine: "we carried it here so no one in the cities would hear it ring") -> the Drowned Belfry.
  Review fixes: Fx.flash lights touch only the ground/props (light mask 2) — they had blown dark sprites out to
  cream; life bars only on hovered and elite enemies; the camera frames the Great Lantern with you; staged scenes
  place the campaign silently (Campaign.place). New layout rule: every set-piece group must really be placed
  (it caught three silently missing groups). People and townsfolk now have 8-frame idles (breath, a blink, the
  coat swaying) and 8-frame walks (counter-swinging arms, step bob, alternating feet); the Lamplighter too.
- **Pass 3 (started)**: Eclipse (shutter the lantern: everything Shrouded, +60% vs Shrouded, speed, leech, a
  closing burst; tree: Long Night, Night Hunger, Predator, Unshutter, Umbra, Pitch Dark, New Moon) learned at level 6;
  Noon (daylight for a breath: every enemy on screen burns and reels, your Light blazes at full; tree: High Noon,
  Long Day, Sunburn, Zenith, Noon Bell, Second Sun) at level 10; six keystones (Unwavering, Wick and Bone,
  Moth-Heart in the base tree at 20 points; Undimmed, Brood of Embers, Shroud Strider in the masteries at 12),
  drawn with a gold double frame. 72-check smoke test. Next for pass 3: respec costs, the remaining skills
  (Kindle, Glass Ward, Hook, Cinder Rain, Wick Trap, Lull), more keystones, five specialisation slots enforced.
- **Pass 2**: review fixes (no Flare spokes, one-word light state, caption plates, trees/tall props fade over bodies
  and captions, free-spot search for every arrival and teleport, actor-vs-prop overlap checks, local minimap with
  arrow and objective, worn/varied stone, lit jaw, spectacles, tree-like glass trees); multi-zone campaign (Session,
  Campaign, quests, dialogue, exits, travel, save 2); Tallow hub with Ottilie, Fenn, Lio, Mara, Nim and four
  services; the Ember Road (burnt farmland, hedgerows, five road lamps, Husks); Moth Hollow (caves, hunger nests,
  Silk Crawlers) and the Moth Matron; loot filter; quest log; 64-check smoke test; layout checks for all four zones;
  demo reel 2. Known weak spots: see the report; Tallow is small and a little sparse; NPCs still 4-frame idles.
- **Pass 1**: design (this file); test slice: title + intro cards, the Glasswood (generated, checked), the
  Lamplighter + 7 NPC designs, gloam/hound/moth + elites (modifiers) + the Glazier, 4 skills with trees, Wickstep,
  tonics, Light, loot (5 rarities, tiers, uniques, set), inventory, character sheet, skill and passive panels,
  mastery, HUD, minimap with fog, damage numbers, hit-stop, shake, flashes, procedural audio + 2 music loops,
  save/continue, all checks. Deliverables: screenshots (title, light, dark, skill tree, passives, inventory +
  tooltip at 3 sizes, character sheet, boss, zone overview), `npc_lineup.png`, `reference_sheet.png`, a 46 s video
  (three staged scenes joined by fades: gate ambush at level 1, an elite pack at level 7, the Glazier at level 10).
- **Known weak spots after pass 1**: one zone only, no hub yet; Eclipse/Noon/crafting designed not built; people
  have 4-frame idles and the Lamplighter's attack is one pose (direction comes from effects); enemies animate by
  pose shifts, not drawn cycles; balance only bot-tested (elite packs are dangerous at level 5–7 — kept apart by
  the generator now); performance measured only in software GL (~10 fps at 1080p, a real GPU will be fine but is
  unmeasured); glass-tree canopies read a little like spiky shrubs.
