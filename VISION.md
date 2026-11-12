# Vision: the creature-trainer action RPG (working title TBD)

## The one-line hook
**An action RPG where you're a trainer, not a hero: you raise a team of creatures, fight beside them in real time, and become the very best at your chosen element.**

## Who you are
- You are the **trainer**. Your creatures are the stars of combat. You command them, use items, and cheer them on.
- **The trainer is never damaged** (as in the shows). Wild creatures ignore the trainer and fight your team.
- The heart of the game is **your relationship with your team**, like Ash and Pikachu. Closeness, not fusion.
- **Elements still exist** for matchups (fire, glass, storm, and so on), but you don't specialise in one.

## Pillars (every decision gets checked against these)
1. **Bond first.** You should love your team. They have personality, react to the world, grow with you, and remember your history together.
2. **Cool attacks.** Creature moves are flashy, glowing and powerful. Combat feels weighty and fast.
3. **Lots of creatures.** A big roster to discover across the world, with cute-to-cool evolution lines.
4. **Be the very best with your team.** You hone the creatures you have into masters.
5. **Rewarding grind.** Materials raise your creatures' stats. Steady and fun, never a slog, and every run moves something forward.
6. **Shiny hunting.** Rare forms worth chasing.
7. **A badass endgame.** Hard challenges that clearly pay off.

## How it plays
- **Your partner is always out:** walking beside you, resting with you, fighting at your side.
- **The team:** up to 6 creatures. One partner fights at a time, and you swap in others instantly.
- **Combat:** exploring as the trainer, battles as your creature in a separate arena (see below). Elements matter, so swapping to the right creature for the fight is part of the skill.
- **Catching (syncing):** weaken or stagger a wild creature in battle and the trainer syncs it with the Sync Lens. The basic lens only syncs weakened common creatures; upgraded lenses are faster and work on rarer ones.
- **Gentle defeat:** a knocked-out creature recovers after a while or at a rest point. If your whole team is knocked out, the screen fades and you retreat to the last rest point, where they recover (a small material cost at most). Nothing is lost permanently (except in the opt-in hardcore modes).

## Starters
- **Choose 1 of 3 at the start,** each with a clear role: a brave close-range fighter, a quick ranged trickster, a sturdy protector.
- **It's a meeting, not a menu.** Three young creatures react to how you act in the opening, and then you choose.
- **Your starter is special:** it's always your partner, gets unique story moments, has the highest bond potential, and gets one of the most impressive final evolutions.
- **The other two aren't lost.** They appear rarely later, and in the endgame.

## Elements (8, each strong against 2 and weak against 2)
**Advantage only:** a hit with the element advantage does x1.3 ("Strong hit!") and fills the stagger bar faster.
Nothing is ever resisted, so no creature is ever useless in a matchup, only better or worse placed.

| Element | Strong against | Weak against |
|---|---|---|
| Ember | Glass, Rot | Tide, Gale |
| Tide | Ember, Echo | Bloom, Shade |
| Bloom | Tide, Gale | Rot, Shade |
| Rot | Bloom, Echo | Ember, Gale |
| Gale | Ember, Rot | Bloom, Glass |
| Glass | Shade, Gale | Ember, Echo |
| Echo | Glass, Shade | Tide, Rot |
| Shade | Bloom, Tide | Glass, Echo |

**The first 24 lines** (uncommon real animals, designed so they never resemble an existing Pokémon):
- **Ember:** honey badger, monitor lizard, secretary bird
- **Tide:** shoebill, narwhal, gharial
- **Bloom:** pangolin, okapi, cassowary
- **Gale:** saiga antelope, maned wolf, frigatebird
- **Glass:** cuttlefish, thorny devil, ibex
- **Echo:** aye-aye, howler monkey, lyrebird
- **Rot:** Tasmanian devil, marabou stork, matamata turtle
- **Shade:** thylacine, fossa, binturong

## Bond
*(Long-term. Not in the current combat demo: its bond meter and bond moves were taken out to keep the test about combat; each creature's signature move now unlocks at level 25.)*
- **How it grows:** fighting together, winning hard fights, exploring, resting at camp, feeding and playing.
- **High bond unlocks:**
  - holding on through a knockout hit for you
  - stronger attacks and a signature bond move
  - more personality (celebrating, protecting you when you're low, nudging you toward secrets)
- **Natures** (brave, shy, proud, playful, lazy) colour each creature's behaviour. A proud one may not obey perfectly until the bond grows. It should be charming, never frustrating.
- **Camp:** at rest points you sit with your team, feed them, play with them and watch them interact.
- **Memory:** milestones and history ("together for 100 battles", first evolution, favourite food).
- **Story:** your team is part of story moments, and some quests are about them.

## Battles (the current model; BATTLE_IDEAS.md has the wider idea list)
Battles are meant to be **fun and fair**: readable, skill-based, no surprises you could not see coming.
- **Exploring:** you are the trainer; your creature follows. Wild creatures never force a fight. Their temperament
  shows how they react: shy ones flee, calm ones ignore you, territorial ones warn (a "!" and a growl) and calm
  down if you back off, and the rare aggressive one (a red eye glint) chases you. Trainers ask "Want to battle?"
  and you can decline.
- **Starting a battle:** walk into a creature or accept a trainer. An old-school black swirl closes and you are in a
  **separate square walled arena**, 1v1, with a fixed camera that shows all of it. The trainers stand outside the
  walls (never hurt). Afterwards the swirl takes you back to the exact spot. On the route your creatures' health
  carries over between battles; resting (camp, the Gate Hall) heals.
- **Controls (Battlerite-style):** you are your creature. Left click moves, right click is its basic physical
  attack, Q W E R are its 4 moves, Space dodges, 1-3 swap. Movement is deliberate (slower than the first
  prototypes) and projectiles are slow enough to read and dodge. No slow-time, no perfect dodge, no items in battle.
- **Three kinds of move:**
  - **Physical:** close range, fills the shared 3-segment gauge.
  - **Special:** costs gauge; a true skillshot with a wind-up. It flies where you aimed and can miss (no homing).
  - **Status:** hold to channel; the longer you hold, the stronger (up to a cap). You can't move or dodge while
    channelling, and a hit cancels it.
  Every creature has a mixed kit. Moves commit (wind-up and recovery: no dodging).
- **Buffs and debuffs always have a cost:** Sprint leaves Lethargy behind, Harden is slow and can't dodge, Berserk
  takes more damage, Camouflage makes the first hit taken a critical. Buffs fade faster when you are hit; debuffs
  just run out. Icons with timers show on both creatures.
- **Stagger:** hits fill a bar (an element advantage fills it faster); a staggered creature reels and takes 50% more.
- **Swaps** cost a gauge segment and have a short cooldown; the swap-in strikes as it lands.
- **Terrain:** each arena has its own (tall grass hides you at range until you attack, water slows, mud, a deep
  channel, a breakable bridge, trees as pillars, thickets, roots that trip a dash, fog, a ledge that gives high
  ground, walls you can be slammed into, thorns, cracked floor). Moves change it: Ember burns grass and vines,
  Gale flattens grass and clears fog, Echo shatters rock and crystal, Bloom grows a vine wall, Tide floods.
- **Home terrain:** every creature has one where it gets a bonus, with a cost, and it is **never weaker
  elsewhere** (the honey badger hits harder on burning ground and doesn't burn there; the cuttlefish hides in
  water but its shots are weaker; the aye-aye reaches further from high ground but takes more).
- **Opponents** fight in their species' style with tells and openings, at a difficulty tier: Easy (slow to react,
  long tells), Normal, Hard (leads its shots, dodges your wind-ups, hides in grass, takes cover and high ground,
  saves its gauge, counter-swaps).
- **Wild battles** reward XP, materials and the chance to sync. **Trainer battles** are 3v3, one creature at a time,
  and the trainer swaps smartly.

## Honing your creatures (no element path)
- **Your build is how deeply you've raised the creatures you have,** not a chosen element. "Being the very best" means mastering your own team.
- **Each creature has its own growth:**
  - its own small skill tree
  - stats raised with materials
  - move choices (pick 4 from the ones it has learned; moves unlock by level)
  - evolutions, and bond-unlocked moves and traits
- **Mastery comes from using a creature:** the more battles it fights with you, the more it unlocks. Long-time partners become specialists.
- **Any creature you love can be raised to the top.** No creature is a dead end.

## Progression and rewards
- **The rewards** are new creatures, materials, evolutions, bond and shinies. **Gear is not the focus:** at most a few simple trainer items.
- **Materials:**
  - **Each zone has its own materials,** so you farm where your favourites' materials come from.
  - **Uses:** raising stats, unlocking moves, pushing evolutions and enhancing shinies.
  - **Rarer sources:** bosses and the endgame drop rare materials.
  - **Duplicates** of a creature count as upgrade material.
  - **Visible progress:** bars toward each upgrade, so it never feels like failing.
- **Evolutions** are big moments with a short ceremony. Early forms are small and charming; final forms are powerful and cool.

## Shinies
- **How rare:** 1 in 4096 in the demo (a dev key spawns one for testing); better odds from tougher enemies and endgame modifiers later.
- **How they look:** a distinct colour, a sparkle, and a special sound when one appears.
- **What they give:** a small bonus or a unique move.
- **Never required.** Shinies are the chase for people who want it.

## Endgame
- Challenge maps that get harder and harder, with modifiers you choose.
- More danger means better rewards: higher shiny odds, rare materials, and endgame-only creatures and forms.
- Pinnacle bosses that test your whole team.
- The best creature in the game is **one you raised**, pushed to its apex through bond and materials.
- **Opt-in challenges:**
  - Hardcore (one life)
  - Trainer Challenge mode (only the first creature per zone; a fallen creature is gone for good)

## Difficulty philosophy
- **The campaign is forgiving:** any creature you love can carry you if you raise it.
- **Every creature has a job** (tank, burst, crowd control, support, utility) rather than a ranking.
- **Depth is hidden for people who want it:** natures, hidden quality, move choices and evolution branches.
- **The endgame is hard and rewarding** for players who want to optimise.

## What we are NOT doing
- No legendaries or god creatures that replace your team.
- No loot treadmill or gear-affix grind.
- No chaining systems.
- No fusing with creatures.
- No gacha, and nothing sold. Everything is earned by playing.
- No copying Pokémon's names, creatures, items, world or look. Everything is original.

## Look and feel (to confirm in the art-direction step)
- **Creatures:** cute-to-cool evolution lines, with charming first forms and powerful final forms.
- **Moves:** glow and shine, with real impact (flash, shockwave, knockback, sound).
- **World tone:** to be decided. Options: keep Lanternfall's dark, moody world (a grim world where your team is the warm light), or a fresh world built around creatures.

## Open decisions
1. **World and story:** reuse Lanternfall's (the sleeping sun, Tallow, the lanterns) or start fresh?
2. **Elements:** how many for matchups (about 6–8?) and which ones.
3. **Roster size:** about 70–90 creatures for the full game (about 30–35 evolution lines), built up one region at a time; about 12–15 in the vertical slice.
4. **Camera and art scale:** keep Lanternfall's top-down pixel style and size?
5. **Title.**

## Next steps
1. **The current demo** starts in a **Gate Hall**: a test hub with a gate per arena (meadow, riverbank, forest,
   ruins), each with a sign listing what to try, a difficulty lever, an opponent switch (wild 1v1 or trainer 3v3),
   a team station (pick 3 of 6, a level, the 4 active moves) and a door to the route (exploring, temperaments, the
   Sync Lens, a rival). It exists to answer one question: **is the combat fun and fair?**
2. **Then:** the canopy arena and more of BATTLE_IDEAS.md if the core holds up, art direction (creature concepts
   you approve), a polished vertical slice, then production one region at a time, and the endgame last.
