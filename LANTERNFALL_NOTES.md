# LANTERNFALL — design and handoff notes (keep updated every pass)

A fast action RPG in Godot 4.7.2 (typed GDScript). One class, the Lamplighter. Everything you see and hear is
made by code (Python+PIL sprites, Godot shaders/particles, numpy/scipy audio). Fonts: Pixelify Sans and
Silkscreen (OFL, licences in `game/fonts/`). Read STYLE.md (look) and CODE_STYLE.md (code) with this file.

Status: **pass 1 — test slice** (title, intro, one big Act 1 zone, 4 skills with trees, light mechanic, loot,
passives, Glazier mini-boss, save). See "Progress" at the end.

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
| story | `Objectives` |
| demo | `DemoBot` (plays the video) |
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
- **Pass 1**: design (this file); test slice: title + intro cards, the Glasswood (generated, checked), the
  Lamplighter + 7 NPC designs, gloam/hound/moth + elites (modifiers) + the Glazier, 4 skills with trees, Wickstep,
  tonics, Light, loot (5 rarities, tiers, uniques, set), inventory, character sheet, skill and passive panels,
  mastery, HUD, minimap with fog, damage numbers, hit-stop, shake, flashes, procedural audio + 2 music loops,
  save/continue, all checks.
