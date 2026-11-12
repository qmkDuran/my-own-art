# Battle ideas: terrains, hazards and systems

A menu to pick from. Everything has a counter, and every buff has a cost.

---

## Design rules (agreed with the user; every change is checked against these)
**Keep it simple**
- No overheat, weather or mid-fight arena events for now (later, if the core holds up).
- Each creature has at most 1 status move.
- At most 1 active buff and 1 active debuff per creature: a new one replaces the old one of its kind.
- Each arena has ONE main terrain mechanic; the others are secondary.
- Only grass regrows (about 20 s after it burns or is flattened).

**Terrain: destroying it changes the fight, never ends it**
- Destroying terrain costs a move (gauge or time); nothing breaks on its own.
- Destroyed terrain transforms: grass burns, then lies as ash and smoke (hides whoever is in it, about 4 s), then
  a burnt field (a slight slow), then regrows. A rock becomes rubble (trips a dash). A bridge breaks and drops
  anyone on it into the water. A cracked floor caves into a pit (damage).
- Burning spreads slowly through grass and hurts anyone inside, the one who lit it too (unless it is their home).
- Effects stay local (a patch, never the whole arena). Walls, ledges and deep water never break.
- Bloom regrows grass (and grows vines).

**Readability: one visual language**
- Buff: a gold ring with rising arrows at the feet. Debuff: a purple ring with sinking arrows.
- Channelling: a circle filling at the feet.
- Every terrain state looks distinct (flames, ash and smoke, black burnt ground, rubble, cracks, a pit) and has its
  own sound.
- Creatures render (and their bodies are) 1.5x bigger in arenas; status icons with timers stay, larger.
- Total damage bonus from element + terrain + buffs is capped at +40%.

**Equal footing**
- Your creatures and AI creatures follow exactly the same rules: the same stat formulas, gauge, move costs,
  wind-ups, lockouts, swap cost and cooldown, entry strike, buff limits, bonus cap and home-terrain bonuses. No
  items in battle for either side.
- The AI difficulty tiers change only DECISION-MAKING (how fast it reacts, how often it attacks, whether it dodges,
  leads, takes cover, saves gauge, swaps). Never stats, never hidden bonuses.
- Visible variants of a species (an alpha, an evolved form) are part of the species, not a hidden edge.

**The trainer, catching**
- The trainer at the arena edge calls the swaps ("Come back, X! Go, Y!"), uses the Sync Lens, and shouts on big
  moments (flavour only).
- Catching: weaken it until gold stars show, press F, the lens beam locks on and a 2.5 s scan runs (faster with a
  better lens). The creature struggles with telegraphed lunges; a hit on your creature breaks the scan (the stars
  stay; retry after a moment). Success syncs it and ends the battle.

**Arenas**
- Two sizes (medium, large) picked in the Gate Hall; the camera fits each with a margin; creatures stay 1.5x.

**Wild variety and reusable blocks**
- Quick win: walking into a wild creature 8+ levels below your active one beats it on the map (no arena).
- Alphas: rare bigger wild creatures (x1.4, a glow, more life, their signature move), a real fight with better
  rewards. A visible variant of the species, not a hidden edge.
- Every species picks one of four movement styles (brawler, kiter, tank, flanker) from data; arenas are composed
  from a piece library in data, so a new arena is a data file.
- A headless balance bot plays every creature x arena x difficulty and flags outliers.

**Parked**
- Bond, as a NON-COMBAT system for later (ideas: field abilities, finding secrets, personality, cosmetics, bond
  events). It never gives a combat advantage. Not in the demo.
- Overheat, weather, mid-fight arena events.

## 1. Combat feel (the foundation)
- **Pace:** slower and methodical. Moderate movement speed, readable projectile speed.
- **Reference game: Battlerite** (and its predecessor Bloodline Champions). Top-down arena fights of 1v1 up to 3v3, where almost every ability is a **skillshot**: you aim it, it travels, and it can miss. Win by **predicting** where the enemy will be, **timing**, **dodging**, and **baiting**. The closest existing game to what you described.
- Other references for methodical, readable combat:
  - **Monster Hunter:** commitment and reading patterns
  - **League of Legends** skillshot champions
- **Skillshots:** no homing. Projectiles go where you aim and can be dodged by moving.
- **Lead your shots:** a slow projectile has to be aimed where the enemy is going.
- **Telegraphed big moves** with a visible wind-up, so the other side can react.
- **Commitment:** strong moves lock you in place briefly.
- **Gauge:** basic hits fill it, moves cost it. Keep it.
- **Swapping** is allowed and costs gauge.

## 1b. Move types: physical, special and status (each with its own cost)
| Type | What it is | How it's paid for (tit for tat) |
|---|---|---|
| **Physical** | close-range hits: bites, claws, charges | **builds** gauge, but you have to get close and risk getting hit |
| **Special** | aimed skillshots: beams, bolts, waves | **costs** gauge; can miss; a wind-up while aiming |
| **Status** | buffs on you, debuffs on the enemy (growl, tail whip, harden, screech) | **channelled:** hold the key to charge it. The longer you hold, the stronger it gets, but you **can't move or dodge while channelling**, and getting hit cancels it |

- **Example: Growl.** Hold to growl; the longer you hold, the more the enemy's attack drops (up to −30% at 2 s). But you stand still and exposed the whole time.
- **Example: Harden.** Hold to raise defence, but you're rooted while hardening.
- **Debuffs fade over time, buffs fade faster when you're hit,** and every buff or debuff has a counter move somewhere in the roster (cleanse, shake off, roar).
- **The gauge stays,** but with a job per type: physical moves fill it, special moves spend it, status moves cost time and exposure instead of gauge.

## 1c. Elements: advantages only, no weaknesses
- **You hate weaknesses, so the rule is: elements give advantages, never penalties.**
- Water into fire hits harder (about ×1.3). Fire into water hits **normally**: never "resisted" or "not very effective".
- Every creature has things it's good against and nothing it's bad against, the same rule as terrain.
- **Elements also matter through terrain:** fire burns grass, water floods, glass freezes and so on. So picking the right creature is about the arena too, not just a type chart.
- **Tit for tat:** the advantage is smaller than in Pokémon (×1.3, not ×2), so a well-played neutral matchup can still win.

## 1d. Choosing your fights
- **Wild creatures don't all rush you.** Each species has a temperament:
  - **Shy:** runs away; you have to sneak up.
  - **Calm:** ignores you unless you engage.
  - **Territorial:** warns you first (a growl and a marker) if you get too close; back off and it calms down.
  - **Aggressive:** rare, clearly marked (a red eye glint), and it will chase you.
- **Trainers ask first:** "Want to battle?" with Accept or Decline. Only story and leader battles are required.
- **You start a fight** by walking into a creature or talking to a trainer, then the transition plays.

## 1e. Progression
- **Rewards from battles:** XP (plus materials, and the chance to catch wild ones).
- **Levelling up:** stats grow, and **new moves unlock over time.** You don't get the good stuff right away.
- **Choosing moves:** each creature keeps **4 active moves** chosen from everything it has learned, swappable at camp.
- **Evolution:** at certain levels. It's a big moment, with a stronger form and new moves.
- **Strong moves come late:** the strongest moves (signature moves) only unlock at high levels, the same for everyone.

## 1f. Catching, shinies and the wider game
- **Sync Lens upgrades:** better lenses scan faster, work on stronger creatures, and some species can only be synced with a specific lens (a deep-water lens, a night lens). Early lenses can only catch common or weakened creatures.
- **Shinies:** as rare as modern Pokémon, about **1 in 4,096**. Ways to improve the odds come later (chains, a charm-like item, endgame modifiers). The demo has a dev option to force one.
- **Story:** a journey to become the very best: leaders (gym-like) and rivals. An optional villain group can come later, not tied to the main story.
- **Leaders and bosses** always fight in **new, cooler arenas** with their own events. Each new region brings new terrains, and each region has **variety inside it** so it doesn't get stale.
- **The main focus is combat** that's different from classic Pokémon.

## 2. Enemy difficulty tiers
- **Easy (wild, early):** slow to react, predictable, walks into hazards, never uses terrain.
- **Normal:** dodges some shots, uses cover sometimes, swaps at low life.
- **Hard (rivals, leaders, endgame):**
  - **Reading you:** leads its shots, dodges on your wind-up, baits your big moves.
  - **Using the arena:** hides in grass, holds high ground, pushes you into hazards.
  - **Saving gauge to punish,** and swaps into counters.
  - **Team strategy.**
- **A difficulty setting** for wild creatures and trainers separately.

## 3. Tit for tat: every buff has a cost
| Buff | Benefit | Cost |
|---|---|---|
| **Sprint / Haste** | much faster for 4 s | **Lethargy** afterwards: slower for 4 s |
| **Harden / Shell** | takes half damage | moves at half speed, can't dodge |
| **Berserk** | +50% damage | takes +50% damage, can't retreat |
| **Stealth / Camouflage** | invisible | breaks on attack; the first hit taken is a crit |
| **Overcharge** | the next move is doubled | you self-stagger after |
| **Regenerate** | heal over time | the gauge doesn't fill while healing |
| **Focus** | the next shot can't miss (wide hitbox) | a long wind-up you can't cancel |
| **Taunt** | forces the enemy to target you | you take more damage while taunting |
| **Burrow / Dig** | underground and untouchable, pops up with an attack | can't see; the exit point is telegraphed |
| **Take flight** | over hazards and grass, hard to hit with melee | ranged hits do double damage while airborne |
| **Element infusion** | your moves take on an extra element | you also take on that element's weaknesses |

## 3b. Home terrain: every creature has one
- **Every creature has a home terrain where it's strong.** Everywhere else it's **neutral**. **No creature is ever weak on a terrain.**
- **Every home-terrain advantage has a cost (tit for tat):**
  - **It ties you to a place:** you only get the bonus while standing in that terrain, which makes you predictable.
  - **The enemy can take it away:** your terrain can be burned, flooded, flattened or broken.
  - **Its strength comes with a matching weakness inside that terrain.**
- **Examples from the demo creatures:**

| Creature | Home terrain | Advantage | The cost |
|---|---|---|---|
| **Honey badger** (Ember) | burning ground, coals | hits harder and ignores burn damage there | standing in fire makes it easy to find; Tide douses its home in one move |
| **Cuttlefish** (Glass) | water and ice | camouflaged (hard to target) while in it | its shots are weaker while camouflaged; Ember melts the ice; leaving the water reveals it |
| **Pangolin** (Bloom) | rocks and roots | can curl up and burrow there, very tanky | slow to come out, and it can't attack while curled up |
| **Maned wolf** (Gale) | tall grass | moves faster and stays hidden in grass | the grass can be burned or flattened, and fire spreads fast through it |
| **Aye-aye** (Echo) | trees and high ground | can see hidden enemies and its shots reach further | it's fragile up there, and a knockback sends it falling |
| **Tasmanian devil** (Rot) | mud and spore patches | heals slowly while in rot | slowed like everyone else in mud; Gale clears its spores |

- **The general rule:** whenever we give anything an advantage (a buff, a terrain, an item, a move), it also gets a cost or a counter. Nothing is free.

## 4. Terrain features (each with its counter)
| Feature | Effect | Counter |
|---|---|---|
| **Tall grass** | hides you at range; ambush bonus | attacking reveals you; Ember burns it, Gale flattens it, Echo reveals |
| **Cover rocks** | blocks projectiles | destructible by heavy moves; walk around |
| **Pillars** | thin cover, break line of sight | area moves hit around them |
| **Ledges / high ground** | +range and damage from above, landing slam | slow to climb; knockback pushes you off |
| **Ramps / vines to climb** | the routes to high ground | they can be cut or burned |
| **Holes / pits** | fall to a lower level and take damage | knock enemies in; stay off the edges |
| **Breakable floors** | collapse after heavy hits | avoid stomping on them, or use them to trap |
| **Shallow water** | slows most creatures; Tide is stronger | Glass crystallises it; fight on the dry side |
| **Deep water** | only swimmers and flyers can cross | ranged attacks from shore |
| **Mud** | everyone is slowed, dodges shorter | Ember dries it into hard ground |
| **Ice / glass sheets** | slippery, momentum carries | Ember melts it; careful movement |
| **Sand** | slowed, dust clouds hide you | Gale clears the dust |
| **Bridges** | narrow choke points | can be broken, dropping anyone on them |
| **Logs / rolling boulders** | push them into enemies | dodge sideways |
| **Bushes / thickets** | block movement, not shots | Ember burns, Rot decays |
| **Tree canopy** (upper level) | fight on branches; gaps you can fall through | knockback and gaps |
| **Roots** | tripping zones; a stumble on dash | jump or fly over |
| **Crystal clusters** | reflect beam moves | Echo shatters them |
| **Mirrors** (Glass arena) | bounce shots around corners | break them or bait them |
| **Bells / gongs** (Echo arena) | hit them for an area stun | timing; they're a shared resource |
| **Spore patches** (Rot arena) | poison clouds when stepped on | Gale clears; Ember burns |
| **Embers / hot coals** | burn damage on contact | Tide douses |
| **Shadows** (Shade arena) | Shade creatures are invisible inside | light sources reveal |
| **Light sources / torches** | reveal hidden things in their radius | they can be knocked over or snuffed |
| **Fog** | short vision range for everyone | Gale clears; Echo senses |
| **Wind tunnels** | push anything along a lane | Gale rides them; heavy creatures resist |
| **Geysers** | launch a creature into the air | time a dodge; launch the enemy |
| **Lava / tar cracks** | big damage zones | knock enemies in |
| **Thorn bushes** | damage when pushed in | knockback becomes a weapon |
| **Walls** | a wall slam staggers | stay in the open against knockback |
| **Teleport stones / burrows** | a pair of linked holes | the exits can be ambushed |
| **Healing spring** | a contested zone that heals | fight over it; it dries up after use |
| **Gauge crystals** | break one for gauge | contested, and they respawn |

## 5. Terrain your moves create or destroy
- **Bloom:** grows vine walls (cover), roots enemies, grows grass.
- **Ember:** burns grass, vines and bushes; dries mud; melts ice; leaves burning ground.
- **Tide:** floods an area into shallow water; douses fire; makes mud.
- **Glass:** crystallises water into slick floors; raises mirror crystals that reflect beams.
- **Gale:** flattens grass, clears fog and spores, pushes projectiles off course.
- **Echo:** shatters crystals and glass; reveals hidden creatures; rings bells.
- **Rot:** decays wood (bridges, logs, vines); leaves spore patches.
- **Shade:** creates patches of darkness to hide in; snuffs light sources.

## 6. Weather and time of day (per arena) (later: not in the demo, see the design rules)
- **Rain:** Tide up, Ember down, puddles form over time.
- **Heatwave:** Ember up, Tide down, grass dries (burns faster).
- **Wind:** Gale up, projectiles drift.
- **Fog:** Shade and Echo up, vision down.
- **Night:** Shade up, Glass glows.
- **Spore season:** Rot up, random spore clouds.
- **Storm:** random lightning strikes (telegraphed) on high ground.

## 7. Arena events mid-fight (later: not in the demo, see the design rules)
- The tide rises and the low ground floods.
- The floor collapses and everyone drops to the underground level.
- The canopy branch snaps and the upper level breaks.
- A wildfire spreads across the grass.
- A rockslide adds new cover and blocks a path.
- Night falls, or day breaks.
- A wild creature stampede crosses the arena (dodge it).
- The bell tolls and stuns everyone.

## 8. Arena types (built from the pieces above)
1. **Meadow:** tall grass, a few rocks, open sightlines. The basic arena.
2. **Forest clearing:** trees as pillars, bushes, roots, fog.
3. **Riverbank:** shallow and deep water, a breakable bridge, mud.
4. **Canopy (two levels):** branches up top, gaps you fall through to the forest floor.
5. **Cave / underground:** darkness, crystals, light sources, pits.
6. **Ruins:** ledges, pillars, breakable floors, bells.
7. **Glass flats:** ice sheets, mirrors, crystal clusters.
8. **Fungal hollow:** spore patches, decaying logs, shadows.
9. **Cliffside:** high ground, wind tunnels, a deadly drop at the edge.
10. **Volcanic vent:** coals, geysers, lava cracks.
11. **Marsh:** mud, fog, deep pools, roots.
12. **Storm peak:** lightning on high ground, wind.

## 9. Trainer battle ideas
- **3v3 standard;** 1v3 and 2v3 as challenges.
- **Teams with a plan:**
  - **Rain team:** floods the arena.
  - **Ambush team:** grass and stealth.
  - **Stagger rush:** pressure and break.
  - **Fortress:** cover and Harden.
- **Leaders** (gym-like) fight in their own themed arena with its own events.
- **Rivals** who grow with you and adapt to the creatures you use most.
- **Hard AI** uses the terrain and the tit-for-tat buffs smartly.
- **Rematches** that are much harder; endgame trainer gauntlets with stacked modifiers.
- **No overlevelling cheese:** trainer creatures scale with yours.

## 10. Testing: the Gate Hall
- **What it is:** a test hub where each **gate** (door) leads straight into one arena, so you can walk through a door and fight in that terrain immediately.
- **A sign by each door** names the arena and its features.
- **Choose the opponent:** a difficulty lever (Easy / Normal / Hard) and a wild-or-trainer switch (wild 1v1, trainer 3v3).
- **A team-picker station** to set your 3 creatures and their levels.
- **New arenas** get a new gate in the hall, so every terrain can always be tested.
- **The dev menu (F1)** can also jump to any gate.
